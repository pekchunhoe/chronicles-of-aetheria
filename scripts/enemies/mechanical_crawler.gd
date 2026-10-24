class_name MechanicalCrawler
extends EnemyBase
var strike_delivered: bool = false


func _physics_process(delta: float) -> void:
	if not _step_common(delta):
		return
	velocity.y = minf(velocity.y + 1000.0 * delta, 650.0)
	if state == State.HURT:
		velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
		if state_time >= profile.hurt_seconds:
			_set_state(State.ALERT)
	elif state == State.ATTACK:
		velocity.x = 0.0
		if state_time >= profile.telegraph_seconds and not strike_delivered:
			strike_delivered = true
			var offset: Vector2 = target.global_position - global_position
			if offset.x * facing >= -5.0 and absf(offset.x) <= profile.attack_range + 8.0 and absf(offset.y) <= 26.0 and sees_target():
				target.receive_hit(profile.damage, global_position, profile.knockback)
		if state_time >= profile.telegraph_seconds + profile.active_seconds + 0.25:
			_set_state(State.IDLE)
	else:
		var visible_target: bool = sees_target() and absf(target.global_position.y - global_position.y) < 45.0
		if visible_target:
			var distance: float = target.global_position.x - global_position.x
			facing = signf(distance) if not is_zero_approx(distance) else facing
			if state in [State.IDLE, State.PATROL]:
				_set_state(State.ALERT)
			if state == State.ALERT:
				velocity.x = 0.0
				if state_time >= 0.24:
					_set_state(State.CHASE)
			elif absf(distance) <= profile.attack_range:
				velocity.x = 0.0
				if cooldown_left <= 0.0:
					_set_state(State.ATTACK)
					strike_delivered = false
					cooldown_left = profile.cooldown_seconds
			else:
				_set_chase_velocity()
		else:
			if state not in [State.IDLE, State.PATROL]:
				_set_state(State.IDLE)
			velocity.x = 0.0
			if state == State.IDLE and state_time > 0.4:
				_set_state(State.PATROL)
			if state == State.PATROL:
				if is_on_wall() or (is_on_floor() and not floor_ahead()):
					facing *= -1.0
				velocity.x = facing * profile.patrol_speed
	move_and_slide()
	if position.y > home.y + 160.0:
		# Knockback may throw a crawler off an edge; it is removed, not respawned in combat.
		health.immunity_left = 0.0
		health.take_damage(health.maximum)
	queue_redraw()


func _set_chase_velocity() -> void:
	if state != State.CHASE:
		_set_state(State.CHASE)
	velocity.x = facing * profile.chase_speed
	if is_on_floor() and not floor_ahead():
		velocity.x = 0.0


func floor_ahead() -> bool:
	var point: Vector2 = global_position + Vector2(facing * 22.0, 0)
	var ray := PhysicsRayQueryParameters2D.create(point, point + Vector2(0, 30), 1)
	return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
