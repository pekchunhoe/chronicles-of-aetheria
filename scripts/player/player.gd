class_name FoundationPlayer
extends CharacterBody2D
## Arcade pixels/second. Educational SI models remain independent.

signal fell
signal respawn_requested
signal movement_state_changed(state: String)
@export var run_speed_px_per_s: float = 180.0
@export var jump_speed_px_per_s: float = 360.0
@export var gravity_px_per_s2: float = 1000.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 2400.0
@export var turn_acceleration: float = 2800.0
@export var air_acceleration: float = 1400.0
@export var jump_cut_speed: float = 120.0
@export var terminal_speed: float = 650.0
@export var coyote_seconds: float = 0.10
@export var buffer_seconds: float = 0.12
@export var hurt_seconds: float = 0.22
@export var death_seconds: float = 0.90
const COYOTE_SECONDS: float = 0.10
const BUFFER_SECONDS: float = 0.12
var coyote_left: float = 0.0
var buffer_left: float = 0.0
var facing: float = 1.0
var world_right: float = 1142.0
var fall_limit: float = 440.0
var hurt_left: float = 0.0
var death_left: float = 0.0
var fall_reported: bool = false
var jumped_since_landing: bool = false
var movement_state: String = "idle"
@onready var health: HealthComponent = $Health
@onready var combat: CombatController = $Combat
@onready var dodge: DodgeController = $Dodge
@onready var audio: CombatAudio = $Audio


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	floor_snap_length = 5.0


func _physics_process(delta: float) -> void:
	if health.current <= 0:
		death_left -= delta
		_set_state("dead")
		if death_left <= 0.0:
			respawn_requested.emit()
		queue_redraw()
		return
	combat.advance(delta)
	dodge.advance(delta)
	hurt_left = maxf(0.0, hurt_left - delta)
	coyote_left = coyote_seconds if is_on_floor() and not jumped_since_landing else maxf(0.0, coyote_left - delta)
	buffer_left = maxf(0.0, buffer_left - delta)
	if Controls.consume_press("jump"):
		buffer_left = buffer_seconds
	var axis: float = Controls.movement_axis()
	if not is_zero_approx(axis) and combat.attack == null and not dodge.running and hurt_left <= 0.0:
		facing = signf(axis)
	var dodge_pressed: bool = Controls.consume_press("dodge")
	var light_pressed: bool = Controls.consume_press("light_attack")
	var heavy_pressed: bool = Controls.consume_press("heavy_attack")
	if hurt_left <= 0.0:
		if dodge_pressed and combat.phase() in ["idle", "recovery"] and dodge.begin(facing):
			combat.cancel()
			buffer_left = 0.0
		if not dodge.running:
			if heavy_pressed:
				combat.request("heavy", facing)
			elif light_pressed:
				combat.request("light", facing)
	if dodge.active():
		var travel_fraction: float = minf(1.0, (dodge.duration - dodge.elapsed) / delta)
		velocity.x = dodge.direction * dodge.distance_px / dodge.duration * travel_fraction
	elif dodge.running and hurt_left <= 0.0:
		velocity.x = axis * run_speed_px_per_s * 0.3
	elif hurt_left <= 0.0:
		var multiplier: float = combat.attack.movement_multiplier if combat.attack != null else 1.0
		var rate: float = acceleration if is_on_floor() else air_acceleration
		if is_zero_approx(axis):
			rate = deceleration if is_on_floor() else air_acceleration
		elif velocity.x * axis < 0.0:
			rate = turn_acceleration
		velocity.x = move_toward(velocity.x, axis * run_speed_px_per_s * multiplier, rate * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if buffer_left > 0.0 and coyote_left > 0.0 and not dodge.running and hurt_left <= 0.0:
		velocity.y = -jump_speed_px_per_s
		buffer_left = 0.0
		coyote_left = 0.0
		jumped_since_landing = true
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity_px_per_s2 * delta, terminal_speed)
	if velocity.y < -jump_cut_speed and not Controls.held("jump") and hurt_left <= 0.0:
		velocity.y = -jump_cut_speed
	health.guarded = dodge.invulnerable()
	move_and_slide()
	if is_on_floor() and velocity.y >= 0.0:
		jumped_since_landing = false
	position.x = clampf(position.x, 10.0, world_right)
	combat.resolve_hits()
	if position.y > fall_limit and not fall_reported:
		fall_reported = true
		fell.emit()
	_update_state()
	queue_redraw()


func receive_hit(amount: int, origin: Vector2, knockback: float) -> bool:
	# Node update order cannot extend dodge invulnerability.
	health.guarded = dodge.invulnerable()
	return health.take_damage(amount, origin, knockback)


func _on_damaged(amount: int, origin: Vector2, knockback: float) -> void:
	combat.cancel()
	dodge.running = false
	hurt_left = hurt_seconds
	var away: float = signf(global_position.x - origin.x)
	velocity = Vector2((away if away != 0.0 else -facing) * knockback, -125.0)
	ImpactBurst.spawn(self, amount, Color("ff998c"))
	audio.cue("hit")


func _on_died() -> void:
	combat.cancel()
	dodge.running = false
	health.guarded = false
	velocity = Vector2.ZERO
	death_left = death_seconds
	Controls.release_virtual()
	_set_state("dead")
	audio.cue("death")


func reset_to(point: Vector2) -> void:
	position = point
	velocity = Vector2.ZERO
	coyote_left = 0.0
	buffer_left = 0.0
	hurt_left = 0.0
	death_left = 0.0
	fall_reported = false
	jumped_since_landing = false
	combat.cancel()
	dodge.reset()
	health.restore()
	_set_state("idle")
	reset_physics_interpolation()
	$Camera2D.reset_smoothing()
	queue_redraw()


func _update_state() -> void:
	if dodge.active():
		_set_state("dodge")
	elif dodge.running:
		_set_state("recover")
	elif hurt_left > 0.0:
		_set_state("hurt")
	elif combat.attack != null:
		_set_state("attack")
	elif not is_on_floor():
		_set_state("jump" if velocity.y < 0.0 else "fall")
	else:
		_set_state("run" if absf(velocity.x) > 1.0 else "idle")


func _set_state(next: String) -> void:
	if next != movement_state:
		movement_state = next
		movement_state_changed.emit(next)


func _draw() -> void:
	if movement_state == "dead":
		draw_rect(Rect2(-14, 7, 28, 7), Color("82908f"))
		return
	var tint: Color = Color("c4a679")
	if hurt_left > 0.0:
		tint = Color("fff2e5")
	elif health != null and health.immunity_left > 0.0:
		tint.a = 0.5 + 0.5 * absf(sin(health.immunity_left * 35.0))
	if dodge != null and dodge.active():
		for index in range(1, 4):
			draw_rect(Rect2(-9 - dodge.direction * index * 10, -10, 18, 24), Color(0.4, 0.9, 0.9, 0.28 / index))
	draw_rect(Rect2(-9, -14, 18, 28), tint)
	draw_rect(Rect2(-7, -12, 14, 8), Color("edf3ed"))
	draw_rect(Rect2(2 * facing, -10, 3, 3), Color("1b2d40"))
	draw_rect(Rect2(-10, 0, 20, 4), Color("427b87"))
	draw_rect(Rect2(7 * facing - 2, -2, 4, 5), Color("8cddc2"))
	if combat != null and combat.attack == null:
		draw_line(Vector2(10 * facing, 1), Vector2(21 * facing, 13), Color("b8ced4"), 2)
