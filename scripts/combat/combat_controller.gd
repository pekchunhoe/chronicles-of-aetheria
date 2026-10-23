class_name CombatController
extends Node2D
## Weapon timeline is shared by rendering and physics queries. No lingering Area.

signal attack_started(title: String)
signal connected(target: Node2D, damage: int)
@export var light_attacks: Array[AttackData] = []
@export var heavy_attack: AttackData
@export var combo_window: float = 0.30
@export var input_buffer: float = 0.20
var attack: AttackData
var elapsed: float = 0.0
var direction: float = 1.0
var combo_index: int = -1
var combo_left: float = 0.0
var buffered_light: float = 0.0
var hit_ids: Dictionary = {}
var hitbox := RectangleShape2D.new()
@onready var audio: CombatAudio = $Audio


func request(kind: String, facing: float) -> bool:
	if attack != null:
		if kind == "light" and phase() == "recovery":
			buffered_light = input_buffer
		return false
	if kind == "heavy":
		combo_index = -1
		attack = heavy_attack
	else:
		if light_attacks.is_empty():
			return false
		combo_index = (combo_index + 1) % light_attacks.size() if combo_left > 0.0 else 0
		attack = light_attacks[combo_index]
	if attack == null:
		return false
	direction = -1.0 if facing < 0.0 else 1.0
	elapsed = 0.0
	buffered_light = 0.0
	hit_ids.clear()
	attack_started.emit(attack.title)
	audio.cue("heavy" if kind == "heavy" else "swing")
	queue_redraw()
	return true


func advance(delta: float) -> void:
	combo_left = maxf(0.0, combo_left - delta)
	buffered_light = maxf(0.0, buffered_light - delta)
	if attack != null:
		elapsed += delta
		if elapsed >= attack.total_seconds():
			attack = null
			combo_left = combo_window
			if buffered_light > 0.0:
				request("light", direction)
	queue_redraw()


func phase() -> String:
	if attack == null:
		return "idle"
	if elapsed < attack.startup:
		return "startup"
	return "active" if elapsed < attack.startup + attack.active else "recovery"


func cancel() -> void:
	attack = null
	buffered_light = 0.0
	combo_left = 0.0
	combo_index = -1
	hit_ids.clear()
	queue_redraw()


func resolve_hits() -> void:
	if phase() != "active":
		return
	hitbox.size = Vector2(attack.reach, attack.height)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox
	query.transform = Transform2D(0.0, global_position + Vector2(direction * (8.0 + attack.reach * 0.5), -2))
	query.collision_mask = 8
	for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var target: Node2D = result.collider
		var identity: int = target.get_instance_id()
		if hit_ids.has(identity) or not target.has_method("receive_hit"):
			continue
		# Solid platforms/walls also stop swords, even when their far side is in range.
		var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		hit_ids[identity] = true
		if target.receive_hit(attack.damage, global_position, attack.knockback):
			connected.emit(target, attack.damage)


func _draw() -> void:
	if attack == null:
		return
	var current_phase: String = phase()
	var color: Color = attack.color
	if current_phase == "startup":
		draw_line(Vector2(7 * direction, 0), Vector2(12 * direction, -24), Color(color, 0.6), 3)
	elif current_phase == "active":
		var progress: float = (elapsed - attack.startup) / attack.active
		var angle: float = lerpf(-1.0, 1.0, progress)
		var tip := Vector2(cos(angle) * direction, sin(angle)) * attack.reach
		draw_line(Vector2(7 * direction, 0), tip, color, 4)
		for index in range(5):
			var trail_angle: float = angle - float(index) * 0.16
			var end := Vector2(cos(trail_angle) * direction, sin(trail_angle)) * attack.reach
			draw_line(end * 0.6, end, Color(color, 0.7 - index * 0.12), 2)
	else:
		draw_line(Vector2(8 * direction, 1), Vector2(25 * direction, 14), Color(color, 0.35), 2)
