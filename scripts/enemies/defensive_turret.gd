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


func _draw() -> void:
	if state == State.DEAD:
		draw_rect(Rect2(-17, 5, 34, 9), Color("645052"))
		return
	var tint: Color = Color("c7a565") if state != State.HURT else Color("fff3c7")
	draw_rect(Rect2(-17, 4, 34, 10), Color("64747d"))
	draw_rect(Rect2(-10, -14, 20, 22), tint)
	draw_circle(Vector2(0, -8), 8, Color("485766"))
	draw_line(Vector2(0, -8), Vector2(0, -8) + aim_direction * 22, tint, 6)
	if state == State.ATTACK:
		var progress: float = minf(1.0, state_time / profile.telegraph_seconds)
		var color := Color(1.0, 0.65, 0.35, 0.25 + progress * 0.55)
		for index in range(14):
			var begin: Vector2 = Vector2(0, -8) + aim_direction * (24 + index * 17)
			draw_line(begin, begin + aim_direction * 9, color, 1)
		draw_circle(Vector2(0, -8) + aim_direction * 23, 3 + progress * 3, Color("ffe4a4"))
	_draw_health(36)
