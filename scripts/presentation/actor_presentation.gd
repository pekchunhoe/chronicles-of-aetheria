class_name ActorPresentation
extends Node2D
## Reads authoritative state; it never changes actor position, velocity or timers.
@export_enum("hero", "crawler", "turret") var role: String = "hero"
var sprite: AnimatedSprite2D
var barrel: Sprite2D
var animation_name: String = "idle"
var facing_value: float = 1.0
var flash_left: float = 0.0
var recovery_left: float = 0.28
var landing_left: float = 0.0
var air_time: float = 0.0
var previous_floor: bool = true
var previous_position: Vector2
var last_shots: int = 0
var muzzle_left: float = 0.0
var material_flash: ShaderMaterial
@onready var actor: CharacterBody2D = get_parent()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 2
	material_flash = ShaderMaterial.new()
	material_flash.shader = preload("res://assets/effects/hit_flash.gdshader")
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = ArtLibrary.sprite_frames(role)
	sprite.scale = Vector2.ONE * 0.25
	sprite.position.y = -6.0 if role == "crawler" else -4.0
	sprite.material = material_flash
	add_child(sprite)
	if role == "turret":
		barrel = Sprite2D.new()
		barrel.name = "Barrel"
		barrel.position.y = -8
		barrel.scale = Vector2.ONE * 0.25
		barrel.material = material_flash
		add_child(barrel)
	var health: HealthComponent = actor.get_node("Health")
	health.damaged.connect(_on_damage)
	health.died.connect(_on_death)
	if role == "hero":
		actor.presentation_reset.connect(func(): recovery_left = 0.28)
		actor.get_node("Combat").connected.connect(func(_target: Node2D, damage: int): Visuals.impact(1.2 if damage >= 25 else 0.5))
	previous_position = actor.position
	_play("idle")


func _process(delta: float) -> void:
	if not actor.is_node_ready():
		return
	flash_left = maxf(0, flash_left - delta)
	recovery_left = maxf(0, recovery_left - delta)
	landing_left = maxf(0, landing_left - delta)
	muzzle_left = maxf(0, muzzle_left - delta)
	if actor.position.distance_to(previous_position) > 100.0:
		recovery_left = 0.25
	previous_position = actor.position
	material_flash.set_shader_parameter("hit_flash", minf(0.65 if Visuals.reduced_motion else 1.0, flash_left / 0.1))
	if role == "hero":
		_update_hero(delta)
	elif role == "crawler":
		_update_crawler()
	else:
		_update_turret()
	queue_redraw()


func _update_hero(delta: float) -> void:
	facing_value = actor.combat.direction if actor.combat.attack != null else actor.dodge.direction if actor.dodge.running else actor.facing
	sprite.flip_h = facing_value < 0
	var floor_now: bool = actor.is_on_floor()
	if floor_now and not previous_floor and actor.health.current > 0:
		landing_left = 0.10
		if Visuals.quality > 0:
			ImpactBurst.spawn(actor, 0, Color("a39b83"))
	previous_floor = floor_now
	air_time = air_time + delta if not floor_now else 0.0
	sprite.modulate.a = 0.65 + 0.35 * absf(sin(actor.health.immunity_left * 30)) if actor.health.immunity_left > 0 and not Visuals.reduced_motion else 1.0
	if actor.health.current <= 0:
		_play("death", 1.0 - actor.death_left / actor.death_seconds)
	elif actor.combat.attack != null:
		var name: String = "heavy" if actor.combat.combo_index < 0 else "light_" + str(actor.combat.combo_index + 1)
		var move: AttackData = actor.combat.attack
		var phase: String = actor.combat.phase()
		var pose: float = 0.0
		if phase == "active":
			pose = 0.25 + 0.49 * (actor.combat.elapsed - move.startup) / move.active
		elif phase == "recovery":
			pose = 0.99
		_play(name, pose)
	elif actor.dodge.running:
		_play("dodge", minf(0.99, actor.dodge.elapsed / actor.dodge.duration))
	elif actor.hurt_left > 0:
		_play("hurt", 1.0 - actor.hurt_left / actor.hurt_seconds)
	elif recovery_left > 0:
		_play("respawn", 1.0 - recovery_left / 0.28)
	elif not floor_now:
		_play("jump_start" if air_time < 0.06 and actor.velocity.y < 0 else "rise" if actor.velocity.y < 0 else "fall")
	elif landing_left > 0:
		_play("land", 1.0 - landing_left / 0.10)
	else:
		_play("run" if absf(actor.velocity.x) > 10 else "idle")


func _update_crawler() -> void:
	facing_value = actor.facing
	sprite.flip_h = facing_value < 0
	match actor.state:
		EnemyBase.State.DEAD:
			_play("death", 1.0 - actor.death_left / 0.42)
		EnemyBase.State.HURT:
			_play("hurt", actor.state_time / actor.profile.hurt_seconds)
		EnemyBase.State.ATTACK:
			var time: float = actor.state_time
			var windup: float = actor.profile.telegraph_seconds
			var progress: float = time / windup * 0.25 if time < windup else 0.25 + (time - windup) / actor.profile.active_seconds * 0.35
			if time >= windup + actor.profile.active_seconds:
				progress = 0.65 + (time - windup - actor.profile.active_seconds) / 0.25 * 0.35
			_play("attack", progress)
		EnemyBase.State.ALERT:
			_play("alert", actor.state_time / 0.24)
		EnemyBase.State.CHASE:
			_play("chase")
		EnemyBase.State.PATROL:
			_play("patrol")
		_:
			_play("idle")


func _update_turret() -> void:
	var dead: bool = actor.health.current <= 0
	_play("death" if dead else "idle", 1.0 - actor.death_left / 0.42 if dead else -1.0)
	barrel.visible = not dead
	var charge: float = clampf(actor.state_time / actor.profile.telegraph_seconds, 0, 1) if actor.state == EnemyBase.State.ATTACK else 0.0
	barrel.texture = ArtLibrary.texture("machines", 48 + mini(5, int(charge * 5)), true)
	barrel.rotation = actor.aim_direction.angle()
	if actor.shots_fired > last_shots:
		muzzle_left = 0.1
	last_shots = actor.shots_fired


func _play(animation: String, progress: float = -1.0) -> void:
	animation_name = animation
	if sprite.animation != animation:
		sprite.play(animation)
	if progress >= 0:
		sprite.pause()
		var count: int = sprite.sprite_frames.get_frame_count(animation)
		sprite.set_frame_and_progress(clampi(int(progress * count), 0, count - 1), 0)
	elif not sprite.is_playing():
		sprite.play(animation)


func _on_damage(_amount: int, _origin: Vector2, _knockback: float) -> void:
	flash_left = 0.10
	if role == "hero":
		Visuals.impact(1.5)


func _on_death() -> void:
	ImpactBurst.spawn(actor, 0, Color("c49c61") if role != "hero" else Color("75d8c7"))


func _draw() -> void:
	if sprite == null or not actor.is_node_ready():
		return
	if role == "hero" and actor.dodge.active() and not Visuals.reduced_motion:
		var current: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		for index in range(1, 2 + Visuals.quality):
			draw_set_transform(Vector2(-actor.dodge.direction * index * 9, 0), 0, Vector2(facing_value, 1))
			draw_texture_rect(current, Rect2(-24, -28, 48, 48), false, Color(0.45, 0.9, 0.85, 0.2 / index))
		draw_set_transform(Vector2.ZERO)
	elif role != "hero":
		_draw_enemy_feedback()


func _draw_enemy_feedback() -> void:
	if actor.health.current <= 0:
		return
	if actor.health.current < actor.health.maximum:
		draw_rect(Rect2(-18, -31, 36, 4), Color("0a111a"))
		draw_rect(Rect2(-17, -30, 34 * float(actor.health.current) / actor.health.maximum, 2), Color("d1a464"))
	if role == "crawler" and actor.state == EnemyBase.State.ALERT:
		draw_string(ThemeDB.fallback_font, Vector2(-2, -28), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffca7a"))
	if role == "crawler" and actor.state == EnemyBase.State.ATTACK:
		draw_arc(Vector2(facing_value * 17, 0), 16, -1.6, 1.6, 12, Color("e7a34d"), 1)
	if role == "turret" and actor.state == EnemyBase.State.ATTACK:
		var progress: float = minf(1, actor.state_time / actor.profile.telegraph_seconds)
		for index in range(14):
			var point: Vector2 = Vector2(0, -8) + actor.aim_direction * (24 + index * 17)
			draw_line(point, point + actor.aim_direction * 9, Color(1, 0.6, 0.25, 0.3 + progress * 0.5), 1)
	if role == "turret" and muzzle_left > 0:
		draw_set_transform(Vector2(0, -8) + actor.aim_direction * 22, actor.aim_direction.angle())
		draw_texture_rect(ArtLibrary.texture("world", 62), Rect2(-4, -9, 24, 18), false, Color(1, 1, 1, muzzle_left / 0.1))
		draw_set_transform(Vector2.ZERO)
