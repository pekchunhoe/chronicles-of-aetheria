class_name ExperimentState
extends RefCounted
## Exact prescribed motion on ideal guides; collision/progression live outside this model.
var kind: String = "incline"
var parameters: Dictionary = {}
var running: bool = false
var elapsed: float = 0.0
var distance_m: float = 0.0
var velocity_si: Vector2 = Vector2.ZERO
var position_si: Vector2 = Vector2.ZERO
var last_impulse: Vector2 = Vector2.ZERO
var heat_j: float = 0.0
var result_text: String = "Ready. Adjust the machine, then release."


func configure(next_kind: String) -> void:
	kind = next_kind
	parameters = {"mass": 10.0, "angle": 15.0, "mu_s": 0.4, "mu_k": 0.2, "g": 9.81,
		"speed": 11.0, "height": 0.8, "loss": 0.0, "target_x": 20.0, "target_y": 0.0, "launch_x": 0.0, "launch_y": 0.0}
	if kind == "projectile":
		parameters.angle = 35.0
		parameters.mass = 1.0
	elif kind == "momentum":
		parameters.mass = 5.0
	elif kind == "energy":
		parameters.mass = 2.0
	reset()


func reset() -> void:
	running = false
	elapsed = 0.0
	distance_m = 0.0
	velocity_si = Vector2.ZERO
	position_si = Vector2.ZERO
	last_impulse = Vector2.ZERO
	heat_j = 0.0
	result_text = "Ready. Adjust the machine, then release."


func release(j: Vector2 = Vector2.ZERO) -> void:
	reset()
	running = true
	if kind == "momentum":
		last_impulse = j
		velocity_si = MechanicsModel.impulse(parameters.mass, Vector2.ZERO, j).velocity
	elif kind == "projectile":
		velocity_si = MechanicsModel.projectile(parameters.speed, parameters.angle, parameters.g).velocity
	result_text = "Experiment running. Vector Sight preserves this motion when paused."


func advance(dt: float) -> void:
	if not running:
		return
	elapsed += dt
	match kind:
		"incline":
			var along: Vector2 = Vector2(cos(deg_to_rad(parameters.angle)), -sin(deg_to_rad(parameters.angle)))
			var state: Dictionary = MechanicsModel.incline_step(distance_m, velocity_si.dot(along), dt, parameters)
			distance_m = state.s
			velocity_si = along * state.v
			position_si = along * distance_m
			if absf(state.v) < 1e-9:
				running = false
				result_text = "Held by static friction. Increase the incline and try again."
		"projectile":
			var state: Dictionary = MechanicsModel.projectile_state(parameters.speed, parameters.angle, elapsed, parameters.g)
			position_si = state.position
			velocity_si = state.velocity
		"momentum":
			var before: float = velocity_si.x
			var a: float = -signf(before) * 0.1 * parameters.g
			var step: float = minf(dt, absf(before / a)) if not is_zero_approx(a) else dt
			position_si.x += before * step + 0.5 * a * step * step
			velocity_si.x = move_toward(before, 0, 0.1 * parameters.g * dt)
			heat_j = 0.5 * parameters.mass * (last_impulse.length_squared() / (parameters.mass * parameters.mass) - velocity_si.length_squared())
			if is_zero_approx(velocity_si.x):
				running = false
				result_text = "Rail friction stopped the cargo before a successful latch. Reset and try a lighter cargo."
		"energy":
			var a: float = parameters.g * (1.0 - parameters.loss)
			distance_m = 0.5 * a * elapsed * elapsed
			position_si = Vector2(0, -distance_m)
			velocity_si = Vector2(0, -a * elapsed)
			heat_j = parameters.loss * parameters.mass * parameters.g * distance_m
	if elapsed > 8.0 or position_si.length() > 60:
		running = false
		result_text = "The receiver was missed. Reset and adjust; no resources are lost."


func measurements() -> Dictionary:
	var p: Dictionary = parameters
	var data: Dictionary = {"kind": kind, "mass": p.mass, "time": elapsed, "position": position_si,
		"velocity": velocity_si, "momentum": p.mass * velocity_si, "impulse": last_impulse, "heat": heat_j}
	match kind:
		"incline":
			var tangent := Vector2(cos(deg_to_rad(p.angle)), -sin(deg_to_rad(p.angle)))
			data.forces = MechanicsModel.incline(p.mass, p.angle, p.mu_s, p.mu_k, velocity_si.dot(tangent), p.g)
			data.angle = p.angle
			data.acceleration = tangent * data.forces.a
		"projectile":
			data.acceleration = Vector2(0, -p.g)
			data.weight = p.mass * p.g
			data.prediction = MechanicsModel.projectile(p.speed, p.angle, p.g, p.target_y - p.launch_y)
		"momentum":
			data.acceleration = Vector2(-signf(velocity_si.x) * 0.1 * p.g, 0)
		"energy":
			data.energy = MechanicsModel.energy(p.mass, maxf(0, p.height - distance_m), velocity_si.length(), 0, 0, p.g)
			data.initial_j = p.mass * p.g * p.height
			data.acceleration = Vector2(0, -p.g * (1.0 - p.loss))
	return data
