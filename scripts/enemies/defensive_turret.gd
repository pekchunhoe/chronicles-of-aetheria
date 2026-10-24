class_name DefensiveTurret
extends EnemyBase
var aim_direction: Vector2 = Vector2.LEFT
var shots_fired: int = 0


func _physics_process(delta: float) -> void:
	if not _step_common(delta):
		return
	velocity = Vector2.ZERO
	if state == State.HURT:
		if state_time >= profile.hurt_seconds:
			_set_state(State.IDLE)
	elif state == State.ATTACK:
		# Aim locks at telegraph start; stepping or dodging out of the line is reliable.
		if state_time >= profile.telegraph_seconds:
			fire()
			cooldown_left = profile.cooldown_seconds
			_set_state(State.IDLE)
	elif sees_target() and aim_at(target.global_position):
		if cooldown_left <= 0.0:
			_set_state(State.ATTACK)
	else:
		_set_state(State.IDLE)
	queue_redraw()


func aim_at(point: Vector2) -> bool:
	var raw: Vector2 = (point - (global_position + Vector2(0, -8))).normalized()
	var base_angle: float = PI if facing < 0.0 else 0.0
	var relative: float = wrapf(raw.angle() - base_angle, -PI, PI)
	var limit: float = deg_to_rad(profile.aim_half_arc_degrees)
	aim_direction = Vector2.from_angle(base_angle + clampf(relative, -limit, limit))
	return absf(relative) <= limit


func fire() -> void:
	var bolt := SecurityProjectile.new()
	bolt.position = position + Vector2(0, -8) + aim_direction * 22.0
	bolt.direction = aim_direction
	bolt.speed = profile.projectile_speed
	bolt.lifetime = profile.projectile_lifetime
	bolt.damage = profile.damage
	bolt.knockback = profile.knockback
	get_parent().add_child(bolt)
	shots_fired += 1
	audio.cue("shot")


func reset_enemy() -> void:
	super.reset_enemy()
	aim_direction = Vector2.LEFT
	shots_fired = 0
