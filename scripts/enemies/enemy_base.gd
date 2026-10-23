class_name EnemyBase
extends CharacterBody2D
## Shared life, damage reaction, LOS and reset. AI does not know dungeon IDs.

signal defeated(enemy: Node2D)
enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, HURT, DEAD }
@export var profile: EnemyProfile
var state: State = State.IDLE
var state_time: float = 0.0
var cooldown_left: float = 0.0
var facing: float = -1.0
var home: Vector2
var target: Node2D
var ai_enabled: bool = true
var death_left: float = 0.0
@onready var health: HealthComponent = $Health
@onready var audio: CombatAudio = $Audio


func _ready() -> void:
	add_to_group("enemies")
	home = position
	health.maximum = profile.maximum_health
	health.restore()
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	target = get_tree().get_first_node_in_group("player")


func receive_hit(amount: int, origin: Vector2, knockback: float) -> bool:
	return health.take_damage(amount, origin, knockback)


func reset_enemy() -> void:
	position = home
	velocity = Vector2.ZERO
	state = State.IDLE
	state_time = 0.0
	cooldown_left = 0.0
	death_left = 0.0
	facing = -1.0
	collision_layer = 8
	health.restore()
	show()
	set_physics_process(true)
	reset_physics_interpolation()
	queue_redraw()


func _on_damaged(amount: int, origin: Vector2, knockback: float) -> void:
	_set_state(State.HURT)
	var away: float = signf(global_position.x - origin.x)
	velocity = Vector2((away if away != 0.0 else 1.0) * knockback, -65.0)
	ImpactBurst.spawn(self, amount)
	audio.cue("hit")


func _on_died() -> void:
	_set_state(State.DEAD)
	collision_layer = 0
	velocity = Vector2.ZERO
	death_left = 0.42
	defeated.emit(self)
	audio.cue("death")


func _set_state(next: State) -> void:
	state = next
	state_time = 0.0


func _step_common(delta: float) -> bool:
	state_time += delta
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if state == State.DEAD:
		death_left -= delta
		queue_redraw()
		if death_left <= 0.0:
			hide()
			set_physics_process(false)
		return false
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if not ai_enabled or not is_instance_valid(target):
		return false
	if global_position.distance_squared_to(target.global_position) > 750.0 * 750.0:
		velocity = Vector2.ZERO
		return false
	return true


func sees_target() -> bool:
	if not is_instance_valid(target) or target.health.current <= 0:
		return false
	if global_position.distance_to(target.global_position) > profile.detection_range:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -5), target.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _draw_health(width: float) -> void:
	if health.current >= health.maximum or state == State.DEAD:
		return
	draw_rect(Rect2(-width / 2, -27, width, 3), Color("392f3c"))
	draw_rect(Rect2(-width / 2, -27, width * float(health.current) / health.maximum, 3), Color("ffab7c"))
