class_name AxiomApparatus
extends Node2D
## Reusable collision adapter: an exact SI experiment drives a swept kinematic payload.
signal contacted(apparatus: AxiomApparatus, accepted: bool)
@export_enum("incline", "projectile", "momentum", "energy") var kind: String = "incline"
@export var identity: String = "cargo"
var experiment := ExperimentState.new()
var payload: CharacterBody2D
var receiver: StaticBody2D
var contacted_once: bool = false
var latched: bool = false
var contact_count: int = 0
var prediction: PackedVector2Array = PackedVector2Array()
var camera_follow: bool = false
var inspected: bool = false
var visual: Node2D


func _ready() -> void:
	experiment.configure(kind)
	add_to_group("axiom_apparatus")
	payload = CharacterBody2D.new()
	payload.name = "MeasuredPayload"
	payload.collision_layer = 32
	payload.collision_mask = 65
	payload.safe_margin = 0.001
	var shape := CollisionShape2D.new()
	if kind == "projectile":
		var circle := CircleShape2D.new()
		circle.radius = 4
		shape.shape = circle
	else:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(20, 20)
		shape.shape = rectangle
	payload.add_child(shape)
	add_child(payload)
	receiver = StaticBody2D.new()
	receiver.name = "PhysicalReceiver"
	receiver.collision_layer = 64
	receiver.collision_mask = 32
	var receiver_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 48) if kind == "projectile" else Vector2(8, 36)
	receiver_shape.shape = rectangle
	receiver.add_child(receiver_shape)
	add_child(receiver)
	visual = preload("res://scripts/presentation/apparatus_presentation.gd").new()
	add_child(visual)
	reset()


func parameter_ranges() -> Dictionary:
	match kind:
		"incline": return {"angle": [5.0, 45.0, 1.0], "mass": [2.0, 15.0, 1.0], "mu_s": [0.3, 0.7, 0.05], "mu_k": [0.0, 0.3, 0.05]}
		"projectile": return {"speed": [6.0, 18.0, 0.5], "angle": [15.0, 75.0, 1.0], "launch_x": [0.0, 1.0, 0.25], "launch_y": [0.0, 0.5, 0.25], "target_x": [16.0, 22.0, 0.5], "target_y": [-0.5, 1.0, 0.25], "g": [8.0, 12.0, 0.01]}
		"momentum": return {"mass": [2.0, 5.0, 1.0]}
		"energy": return {"height": [0.5, 2.5, 0.1], "mass": [1.0, 3.0, 0.5], "loss": [0.0, 0.4, 0.05]}
	return {}


func adjust(key: String, value: float) -> bool:
	var ranges: Dictionary = parameter_ranges()
	if experiment.running or not ranges.has(key) or not is_finite(value):
		return false
	experiment.parameters[key] = clampf(value, ranges[key][0], ranges[key][1])
	reset()
	return true


func reset() -> void:
	experiment.reset()
	contacted_once = false
	place_geometry()
	_rebuild_prediction()
	if is_instance_valid(visual):
		visual.queue_redraw()


func launch() -> bool:
	if experiment.running or kind == "momentum":
		return false
	reset()
	experiment.release()
	return true


func deliver_impulse(j: Vector2) -> bool:
	if kind != "momentum" or experiment.running or contacted_once or not j.is_finite():
		return false
	experiment.release(j)
	return true


func origin_offset() -> Vector2:
	var p: Dictionary = experiment.parameters
	if kind == "energy":
		return Vector2(0, -p.height * MechanicsModel.SCALE)
	if kind == "projectile":
		return MechanicsModel.to_pixels(Vector2(p.launch_x, p.launch_y))
	return Vector2.ZERO


func place_geometry() -> void:
	payload.position = origin_offset()
	payload.rotation = 0
	var p: Dictionary = experiment.parameters
	match kind:
		"incline":
			var direction := Vector2.RIGHT.rotated(deg_to_rad(p.angle))
			receiver.position = direction * (4.0 * MechanicsModel.SCALE + 14)
			receiver.rotation = direction.angle()
			payload.rotation = direction.angle()
		"projectile":
			receiver.position = MechanicsModel.to_pixels(Vector2(p.target_x, p.target_y))
		"momentum": receiver.position = Vector2(2.0 * MechanicsModel.SCALE + 14, 0)
		"energy":
			receiver.position = Vector2(0, 14)
			receiver.rotation = PI / 2


func _physics_process(dt: float) -> void:
	if not experiment.running:
		return
	var old_time: float = experiment.elapsed
	var old_distance: float = experiment.distance_m
	var old_position: Vector2 = experiment.position_si
	var old_velocity: Vector2 = experiment.velocity_si
	var old_heat: float = experiment.heat_j
	experiment.advance(dt)
	var desired: Vector2 = origin_offset() + MechanicsModel.to_pixels(experiment.position_si)
	var motion: Vector2 = desired - payload.position
	var collision: KinematicCollision2D = payload.move_and_collide(motion)
	if collision != null and not contacted_once:
		var fraction: float = clampf(collision.get_travel().length() / maxf(motion.length(), 1e-12), 0, 1)
		experiment.elapsed = old_time
		experiment.distance_m = old_distance
		experiment.position_si = old_position
		experiment.velocity_si = old_velocity
		experiment.heat_j = old_heat
		experiment.running = true
		experiment.advance(dt * fraction)
		experiment.running = false
		contacted_once = true
		contact_count += 1
		var accepted: bool = collision.get_collider() == receiver and _receiver_accepts()
		latched = latched or accepted
		experiment.result_text = "CONTACT — relay latched. Impact measurements preserved." if accepted else "Contact was insufficient or hit stone. Reset and adjust the machine."
		contacted.emit(self, accepted)
	visual.queue_redraw()


func _receiver_accepts() -> bool:
	match kind:
		"incline": return experiment.parameters.mass >= 8.0 and experiment.velocity_si.length() > 0.05
		"projectile": return true
		"momentum": return experiment.parameters.mass * experiment.velocity_si.x >= 4.0
		"energy": return 0.5 * experiment.parameters.mass * experiment.velocity_si.length_squared() >= 20.0
	return false


func _rebuild_prediction() -> void:
	prediction.clear()
	if kind != "projectile":
		return
	var p: Dictionary = experiment.parameters
	for index in range(241):
		var state: Dictionary = MechanicsModel.projectile_state(p.speed, p.angle, index / 30.0, p.g)
		var point: Vector2 = origin_offset() + MechanicsModel.to_pixels(state.position)
		prediction.append(point)
		if point.y > 80:
			break


func capture() -> Dictionary:
	var data: Dictionary = experiment.measurements().duplicate(true)
	data["point"] = payload.global_position
	data["parameters"] = experiment.parameters.duplicate(true)
	data["contact"] = contacted_once
	return data
