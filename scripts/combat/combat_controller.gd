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
	if current_phase == "active":
		var progress: float = (elapsed - attack.startup) / attack.active
		var index: int = 58 if combo_index < 0 else 56 + mini(1, int(progress * 2))
		draw_set_transform(Vector2(8 * direction, -2), 0, Vector2(direction, 1))
		draw_texture_rect(ArtLibrary.texture("world", index), Rect2(0, -attack.height * 0.5, attack.reach, attack.height), false, Color(1, 1, 1, 0.88))
		draw_set_transform(Vector2.ZERO)
	elif current_phase == "startup":
		draw_texture_rect(ArtLibrary.texture("world", 59), Rect2(4 * direction - 3, -20, 6, 6), false, Color(1, 0.85, 0.55, 0.65))
