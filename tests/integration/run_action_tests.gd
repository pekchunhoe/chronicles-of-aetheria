extends SceneTree
## Real physics, authored scenes and unified action input. Uses isolated save files.
const Checks = preload("res://tests/test_checks.gd")
var t := Checks.new()
var boot: Control
var room: Node2D
var player: CharacterBody2D
var controls: Node
var save_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	controls = root.get_node("Controls")
	save_path = "res://artifacts/action_save_" + str(Time.get_ticks_usec()) + ".json"
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	room = boot.room
	player = room.player
	_disable_enemies()
	await _frames(5)
	await _movement()
	await _combat()
	await _enemies()
	await _progression()
	await _traversal()
	await _touch_and_remapping()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await _capture_evidence()
	boot.queue_free()
	await process_frame
	controls.install_defaults()
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	await _frames(4)
	t.check(boot.room.checkpoint_id == "citadel_checkpoint", "fresh session restores the new relay checkpoint")
	t.check(boot.room.relic_collected and not boot.room.relic.visible, "fresh session restores shard without duplicating it")
	t.check(boot.room.completed and boot.room.COMPLETION_ID in boot.saves.load_save().unlocks, "fresh session restores sector completion")
	t.check(controls.binding_label("jump") == "J" and controls.binding_label("light_attack") != "J", "fresh session restores migrated non-conflicting bindings")
	boot.queue_free()
	await process_frame
	controls.install_defaults()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit(t.summary())


func _movement() -> void:
	player.reset_to(Vector2(128, 305))
	await _frames(4)
	_hold("move_right", true)
	await _frames(12)
	t.check(player.velocity.x == player.run_speed_px_per_s and player.position.x > 150, "acceleration reaches configured run speed")
	t.check(player.movement_state == "run", "ground motion enters run state")
	_hold("move_right", false)
	_hold("move_left", true)
	await _frames(7)
	t.check(player.velocity.x < 0 and player.facing < 0, "direction changes reverse promptly")
	_hold("move_left", false)
	await _frames(6)
	t.check(absf(player.velocity.x) < 0.1 and player.movement_state == "idle", "release decelerates to a stable idle")
	var short_peak: float = await _jump_peak(5)
	var full_peak: float = await _jump_peak(30)
	t.check(full_peak < short_peak - 20.0, "held jump is substantially higher than a tap")
	player.reset_to(Vector2(128, 305))
	await _frames(3)
	_hold("jump", true)
	await _frames(7)
	_hold("jump", false)
	await _frames(2)
	var previous: float = player.velocity.y
	_hold("jump", true)
	await _frames(2)
	t.check(player.velocity.y > previous and player.movement_state == "jump", "second jump press cannot produce an unintended air jump")
	_hold("jump", false)
	await _frames(35)
	player.reset_to(Vector2(435, 305))
	await _frames(3)
	_hold("move_right", true)
	for index in range(20):
		await _frames(1)
		if not player.is_on_floor():
			break
	_hold("jump", true)
	await _frames(2)
	t.check(player.velocity.y < -280, "coyote jump works immediately after leaving a platform")
	controls.release_virtual()
	player.reset_to(Vector2(480, 230))
	await _frames(12)
	_hold("jump", true)
	await _frames(2)
	t.check(player.velocity.y > 0, "jump is rejected after coyote time expires")
	controls.release_virtual()
	player.reset_to(Vector2(128, 288))
	player.velocity.y = 200
	await _frames(3)
	_hold("jump", true)
	await _frames(6)
	t.check(player.velocity.y < -250 and player.position.y < 300, "jump buffered just before landing launches on the next grounded step")
	controls.release_virtual()
	player.reset_to(Vector2(128, 305))
	await _frames(3)
	var start: float = player.position.x
	_tap("dodge")
	await _frames(1)
	t.check(player.dodge.active() and player.movement_state == "dodge", "dodge input enters travel state")
	player.health.immunity_left = 0
	t.check(not player.receive_hit(10, player.position - Vector2(20, 0), 100), "early dodge frames avoid a hit")
	await _frames(10)
	t.near(player.position.x - start, player.dodge.distance_px, 1.0, "unobstructed dodge has bounded travel distance [px]")
	_tap("dodge")
	await _frames(3)
	t.check(not player.dodge.active() and player.dodge.cooldown_left > 0, "dodge spam cannot reset travel or cooldown")
	await _frames(7)
	t.check(not player.dodge.running, "dodge recovers without a stuck movement state")
	var wall: Node2D = load("res://scripts/level/modular_platform.gd").new()
	wall.position = Vector2(210, 200)
	wall.dimensions = Vector2(20, 120)
	room.add_child(wall)
	player.reset_to(Vector2(180, 305))
	await _frames(3)
	_tap("dodge")
	await _frames(13)
	t.check(player.position.x <= 201.1, "dodge resolves solid wall collision without tunnelling")
	t.check(not player.dodge.invulnerable(), "late dodge travel and recovery do not grant immunity")
	wall.queue_free()
	await process_frame
	controls.release_virtual()


func _jump_peak(hold_frames: int) -> float:
	controls.release_virtual()
	player.reset_to(Vector2(128, 305))
	await _frames(4)
	_hold("jump", true)
	var peak: float = player.position.y
	for index in range(50):
		if index == hold_frames:
			_hold("jump", false)
		await _frames(1)
		peak = minf(peak, player.position.y)
	_hold("jump", false)
	return peak


func _combat() -> void:
	_disable_enemies()
	player.reset_to(Vector2(128, 305))
	var enemy: CharacterBody2D = room.enemies[0]
	_place_enemy(enemy, Vector2(160, 308))
	await _frames(4)
	var maximum: int = enemy.health.maximum
	_tap("light_attack")
	await _frames(3)
	t.check(player.combat.phase() == "startup" and enemy.health.current == maximum, "startup animation has no active hitbox")
	await _frames(4)
	t.check(player.combat.phase() == "active" and enemy.health.current == maximum - 14, "light active window delivers configured damage")
	t.check(enemy.velocity.x > 0, "sword knockback pushes the target away from the attacker")
	await _frames(7)
	t.check(enemy.health.current == maximum - 14 and player.combat.phase() == "recovery", "one swing cannot damage a target more than once")
	_tap("light_attack")
	await _frames(9)
	t.check(player.combat.attack != null and player.combat.attack.title == "Cut II", "late recovery input chains into the second combo move")
	await _frames(24)
	t.check(player.combat.phase() == "idle", "combo returns to idle after its finite timeline")
	_tap("light_attack")
	await _frames(4)
	t.check(player.combat.attack != null and player.combat.attack.title == "Cut III", "combo continues to the third distinct sword move")
	await _frames(24)
	t.check(enemy.health.current == 0, "third combo strike can finish an injured enemy")
	_place_enemy(enemy, Vector2(160, 308))
	player.combat.cancel()
	_tap("heavy_attack")
	await _frames(12)
	t.check(enemy.health.current == maximum, "heavy startup is longer than light startup")
	await _frames(7)
	t.check(enemy.health.current == maximum - 34, "heavy attack delivers higher configured damage")
	await _frames(32)
	t.check(enemy.health.current == maximum - 34 and player.combat.phase() == "idle", "heavy has one hit and fully disables its ended hitbox")
	_place_enemy(enemy, Vector2(160, 308))
	player.reset_to(Vector2(128, 305))
	player.facing = -1
	_tap("light_attack")
	await _frames(12)
	t.check(enemy.health.current == maximum, "left-facing sword cannot hit a target behind Kael")
	player.combat.cancel()
	_place_enemy(enemy, Vector2(96, 308))
	_tap("light_attack")
	await _frames(12)
	t.check(enemy.health.current == maximum - 14 and enemy.velocity.x < 0, "left-facing sword hits and knocks back to the left")
	player.combat.cancel()
	var blocker: Node2D = load("res://scripts/level/modular_platform.gd").new()
	blocker.position = Vector2(142, 280)
	blocker.dimensions = Vector2(5, 40)
	room.add_child(blocker)
	player.facing = 1
	_place_enemy(enemy, Vector2(166, 308))
	await _frames(2)
	_tap("light_attack")
	await _frames(12)
	t.check(enemy.health.current == maximum, "solid geometry prevents sword damage through a wall")
	blocker.queue_free()
	player.combat.cancel()
	player.health.immunity_left = 0
	var hp: int = player.health.current
	t.check(player.receive_hit(12, player.position - Vector2(20, 0), 180), "player receives enemy damage")
	t.check(player.velocity.x > 0 and player.movement_state != "dead", "damage applies directional knockback")
	t.check(not player.receive_hit(12, player.position - Vector2(20, 0), 180) and player.health.current == hp - 12, "post-damage immunity protects player health")
	await _frames(20)
	t.check(player.combat.phase() == "idle" and player.hurt_left <= 0, "damage cancels attacks and exits hurt state")
	controls.release_virtual()


func _enemies() -> void:
	room.respawn()
	_disable_enemies()
	var crawler: CharacterBody2D = room.enemies[0]
	crawler.ai_enabled = true
	crawler.set_physics_process(true)
	player.reset_to(Vector2(790, 305))
	await _frames(50)
	t.check(crawler.state == crawler.State.PATROL and crawler.position.x < crawler.home.x - 5, "crawler idles then patrols when player is outside detection")
	player.reset_to(crawler.position - Vector2(120, 2))
	await _frames(2)
	t.check(crawler.state == crawler.State.ALERT, "crawler detects player and enters visible alert")
	await _frames(18)
	t.check(crawler.state == crawler.State.CHASE and crawler.velocity.x < 0, "crawler chases the detected player")
	player.reset_to(crawler.position - Vector2(26, 2))
	player.health.immunity_left = 0
	player.set_physics_process(false)
	await _frames(2)
	t.check(crawler.state == crawler.State.ATTACK and crawler.velocity.x == 0, "crawler stops to telegraph a close attack")
	var hp: int = player.health.current
	await _frames(24)
	t.check(player.health.current == hp - crawler.profile.damage, "crawler attack applies one close-range hit")
	player.health.immunity_left = 0
	await _frames(22)
	t.check(player.health.current == hp - crawler.profile.damage, "crawler cooldown prevents continuous repeated damage")
	player.set_physics_process(true)
	crawler.reset_enemy()
	crawler.position = Vector2(1230, 308)
	crawler.facing = 1
	crawler.state = crawler.State.PATROL
	player.reset_to(Vector2(900, 305))
	await _frames(40)
	t.check(crawler.is_on_floor() and crawler.position.y < 310 and crawler.facing < 0, "crawler patrol turns at a platform edge")
	crawler.health.immunity_left = 0
	crawler.receive_hit(999, player.position, 200)
	t.check(crawler.state == crawler.State.DEAD and crawler.collision_layer == 0, "enemy lethal damage enters dead state and removes hit detection")
	await _frames(30)
	t.check(not crawler.visible and not crawler.is_physics_processing(), "dead crawler finishes feedback and stops processing")
	crawler.reset_enemy()
	t.check(crawler.visible and crawler.health.current == crawler.health.maximum, "enemy reset reuses the same healthy instance")
	_disable_enemies()
	var turret: CharacterBody2D = room.enemies[1]
	turret.reset_enemy()
	turret.ai_enabled = true
	player.reset_to(Vector2(1720, 210))
	player.health.immunity_left = 0
	player.set_physics_process(false)
	await _frames(2)
	t.check(turret.state == turret.State.ATTACK and turret.shots_fired == 0, "turret detects player and telegraphs before firing")
	var aim: Vector2 = turret.aim_direction
	player.position.y -= 20
	await _frames(10)
	t.check(turret.aim_direction.is_equal_approx(aim), "turret telegraph locks its projectile aim")
	player.position.y += 20
	await _frames(31)
	t.check(turret.shots_fired == 1 and turret.cooldown_left > 0, "turret fires one projectile and starts cooldown")
	await _frames(45)
	t.check(player.health.current == player.health.maximum - turret.profile.damage, "swept turret projectile collides and damages the player")
	t.check(turret.shots_fired == 1, "turret respects its fire interval")
	t.check(not turret.aim_at(turret.global_position + Vector2(70, 0)), "turret does not fire behind its permitted aiming arc")
	turret.health.immunity_left = 0
	turret.receive_hit(999, player.position, 200)
	await _frames(30)
	t.check(turret.state == turret.State.DEAD and not turret.visible, "turret is destructible and cleans up its active state")
	player.set_physics_process(true)
	_disable_enemies()
	player.reset_to(Vector2(128, 305))
	player.health.immunity_left = 0
	await _frames(2)
	var bolt: Node2D = load("res://scripts/enemies/security_projectile.gd").new()
	bolt.position = Vector2(95, 305)
	bolt.direction = Vector2.RIGHT
	bolt.speed = 3000
	room.add_child(bolt)
	await _frames(3)
	t.check(not is_instance_valid(bolt) and player.health.current == 84, "fast projectile hits once and is freed on first impact")
	player.health.immunity_left = 0
	await _frames(4)
	t.check(player.health.current == 84, "consumed projectile cannot inflict later damage")
	bolt = load("res://scripts/enemies/security_projectile.gd").new()
	bolt.position = Vector2(400, 40)
	bolt.lifetime = 0.04
	room.add_child(bolt)
	await _frames(5)
	t.check(not is_instance_valid(bolt), "expired projectile is freed")
	var wall: Node2D = load("res://scripts/level/modular_platform.gd").new()
	wall.position = Vector2(300, 240)
	wall.dimensions = Vector2(12, 80)
	room.add_child(wall)
	await _frames(2)
	bolt = load("res://scripts/enemies/security_projectile.gd").new()
	bolt.position = Vector2(250, 280)
	bolt.direction = Vector2.RIGHT
	bolt.speed = 6000
	room.add_child(bolt)
	await _frames(3)
	t.check(not is_instance_valid(bolt), "high-speed projectile is consumed by solid terrain")
	wall.queue_free()
	player.reset_to(Vector2(128, 305))
	player.health.immunity_left = 1.0
	await _frames(2)
	bolt = load("res://scripts/enemies/security_projectile.gd").new()
	bolt.position = Vector2(95, 305)
	bolt.direction = Vector2.RIGHT
	bolt.speed = 3000
	room.add_child(bolt)
	await _frames(3)
	t.check(not is_instance_valid(bolt) and player.health.current == 100, "invulnerable player consumes a projectile without receiving damage")


func _progression() -> void:
	room.set_checkpoint("east_checkpoint")
	player.reset_to(Vector2(2040, 305))
	player.health.current = 35
	await _frames(5)
	t.check(room.checkpoint_id == "citadel_checkpoint" and player.health.current == 100, "new relay collision activates checkpoint and heals Kael")
	t.check(boot.saves.load_save().checkpoint_id == "citadel_checkpoint", "new relay activation is persisted")
	var enemies_before: int = get_nodes_in_group("enemies").size()
	var bolt: Node2D = load("res://scripts/enemies/security_projectile.gd").new()
	bolt.position = Vector2(3000, 40)
	bolt.lifetime = 5
	room.add_child(bolt)
	player.health.immunity_left = 0
	player.receive_hit(999, player.position - Vector2(20, 0), 100)
	_tap("light_attack")
	_hold("move_right", true)
	await _frames(10)
	t.check(player.health.current == 0 and player.movement_state == "dead" and player.combat.phase() == "idle", "death disables movement and combat during feedback")
	t.near(player.position.x, 2040, 0.1, "dead player stays at the death position")
	for index in range(65):
		await _frames(1)
		if player.health.current > 0:
			break
	controls.release_virtual()
	_disable_enemies()
	t.check(player.health.current == 100 and player.position.distance_to(Vector2(2040, 302)) < 1, "controlled death timeline respawns healthy at latest checkpoint")
	t.check(get_nodes_in_group("player").size() == 1 and get_nodes_in_group("enemies").size() == enemies_before, "repeated respawn creates no duplicate actors")
	await _frames(2)
	t.check(not is_instance_valid(bolt), "checkpoint respawn removes orphaned projectiles")
	player.reset_to(Vector2(2380, 132))
	await _frames(5)
	t.check(room.relic_collected and not room.relic.visible, "optional upper-passage shard collects once")
	t.check(boot.saves.load_save().collected_crystals.count(room.RELIC_ID) == 1, "optional reward persists with one stable ID")
	player.reset_to(Vector2(3200, 305))
	await _frames(5)
	t.check(room.completed and room.COMPLETION_ID in boot.saves.load_save().unlocks, "exit collision completes and saves the sector")
	player.reset_to(Vector2(3150, 305))
	await _frames(2)
	player.reset_to(Vector2(3200, 305))
	await _frames(3)
	t.check(boot.saves.load_save().unlocks.count(room.COMPLETION_ID) == 1, "re-entering exit never duplicates completion")


func _traversal() -> void:
	# Verify actual jumps, with AI disabled to isolate geometry from the combat cases.
	_disable_enemies()
	player.reset_to(Vector2(1125, 305))
	await _frames(4)
	for step in [[1255.0, 258.0], [1375.0, 210.0], [1490.0, 162.0]]:
		_hold("move_right", true)
		_hold("jump", true)
		for index in range(55):
			await _frames(1)
			if player.position.x >= step[0]:
				break
		_hold("move_right", false)
		_hold("jump", false)
		await _frames(12)
		t.check(player.is_on_floor() and player.position.y <= step[1] + 1, "ascent step is reachable by the configured jump: y=" + str(step[1]))
	player.reset_to(Vector2(2076, 305))
	await _frames(4)
	for step in [[2155.0, 250.0], [2235.0, 194.0], [2330.0, 138.0]]:
		_hold("move_right", true)
		_hold("jump", true)
		for index in range(45):
			await _frames(1)
			if player.position.x >= step[0]:
				break
		_hold("move_right", false)
		_hold("jump", false)
		await _frames(18)
		t.check(player.is_on_floor() and player.position.y <= step[1] + 1, "optional passage step is reachable: y=" + str(step[1]))
	player.reset_to(Vector2(2410, 305))
	await _frames(4)
	_hold("move_right", true)
	_hold("jump", true)
	await _frames(45)
	controls.release_virtual()
	await _frames(10)
	t.check(player.is_on_floor() and player.position.x > 2528, "combined encounter's final gap is traversable")
	room.set_checkpoint("citadel_checkpoint")
	boot._checkpoint_reached("citadel_checkpoint")
	player.position.y = 480
	await _frames(3)
	t.check(player.position.x == 2040 and player.health.current > 0, "dungeon fall recovery returns to the active relay")


func _touch_and_remapping() -> void:
	boot.save_data.control_preferences.touch_visible = true
	boot.touch.show()
	await process_frame
	var stick: Control = boot.touch.get_node("Stick")
	var light: Control = boot.touch.get_node("Actions/Light")
	var jump: Control = boot.touch.get_node("Actions/Jump")
	_touch(stick, 0, stick.get_global_rect().get_center() + Vector2(60, 0), true)
	_touch(light, 1, light.get_global_rect().get_center(), true)
	_touch(jump, 2, jump.get_global_rect().get_center(), true)
	t.check(controls.movement_axis() > 0.5 and controls.held("light_attack") and controls.held("jump"), "three fingers can move, jump and attack simultaneously")
	t.check(controls.consume_press("light_attack") and not controls.consume_press("light_attack"), "touch attack produces one action edge per finger press")
	_touch(light, 1, Vector2.ZERO, false)
	t.check(not controls.held("light_attack") and controls.held("jump") and controls.movement_axis() > 0.5, "attack finger release preserves other fingers")
	boot.touch.hide()
	t.check(not controls.held("jump") and controls.movement_axis() == 0, "hidden combat touch overlay releases every owned finger")
	controls.install_defaults()
	controls.import_key_bindings({"jump": [KEY_J]})
	t.check(controls.binding_label("jump") == "J" and controls.binding_label("light_attack") != "J", "legacy custom key has priority over new attack default")
	var all: Dictionary = controls.export_key_bindings()
	var keys: Dictionary = {}
	var unique: bool = true
	for action in all:
		for key in all[action]:
			unique = unique and not keys.has(key)
			keys[key] = true
	t.check(unique and all.size() == 10, "all ten remappable actions remain reachable without duplicate keys")
	boot._persist("Migrated control test")
	boot.set_paused(true)
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_Y
	joy.pressed = true
	Input.parse_input_event(joy)
	await process_frame
	t.check(controls.consume_press("heavy_attack"), "controller heavy button routes through shared action map")
	joy = InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_Y
	joy.pressed = false
	Input.parse_input_event(joy)
	var before: Vector2 = player.position
	_tap("light_attack")
	await _frames(8)
	t.check(player.position == before and player.combat.phase() == "idle", "pause freezes combat and movement")
	boot.set_paused(false)
	await _frames(2)
	t.check(player.combat.phase() == "idle", "pause resume clears queued combat input")


func _capture_evidence() -> void:
	controls.install_defaults()
	boot._refresh_bindings()
	boot.save_data.control_preferences.touch_visible = false
	boot.status_message = "Heavy strike connected. Mix light cuts and Breaker attacks."
	boot._refresh_status()
	boot.touch.hide()
	boot.bench.hide()
	player.reset_to(Vector2(940, 305))
	var enemy: CharacterBody2D = room.enemies[0]
	_place_enemy(enemy, Vector2(972, 308))
	_tap("heavy_attack")
	await _frames(18)
	await _capture("phase1-combat")
	player.reset_to(Vector2(1720, 210))
	boot.status_message = "The turret locks its aim before firing. Jump or dodge out of the line."
	boot._refresh_status()
	var turret: CharacterBody2D = room.enemies[1]
	turret.reset_enemy()
	turret.ai_enabled = true
	await _frames(20)
	await _capture("phase1-turret")
	_disable_enemies()
	player.reset_to(Vector2(2040, 305))
	boot.save_data.control_preferences.touch_visible = true
	boot.status_message = "Relay active. Health restored and checkpoint saved."
	boot._refresh_status()
	boot.touch.show()
	await _frames(10)
	await _capture("phase1-touch-relay")
	boot.touch.hide()
	boot.save_data.control_preferences.touch_visible = false
	boot._refresh_status()
	player.reset_to(Vector2(3160, 305))
	boot._sector_completed()
	await _frames(5)
	await _capture("phase1-completion")
	boot.set_paused(true)
	await _capture("phase1-pause")
	boot.set_paused(false)
	# Captures must not replace the binding migration test's persistent settings.
	controls.import_key_bindings({"jump": [KEY_J]})
	boot._persist("Capture complete")


func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	t.check(root.get_texture().get_image().save_png("res://artifacts/" + name + ".png") == OK, "gameplay screenshot saved: " + name)


func _disable_enemies() -> void:
	for enemy in room.enemies:
		enemy.ai_enabled = false
		enemy.set_physics_process(false)
	for bolt in get_nodes_in_group("projectiles"):
		bolt.queue_free()


func _place_enemy(enemy: CharacterBody2D, point: Vector2) -> void:
	enemy.reset_enemy()
	enemy.ai_enabled = false
	enemy.set_physics_process(false)
	enemy.position = point
	enemy.velocity = Vector2.ZERO


func _hold(action: String, pressed: bool) -> void:
	controls.set_virtual_action(action, "action_tests", pressed)


func _tap(action: String) -> void:
	_hold(action, true)
	_hold(action, false)


func _touch(control: Control, index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	control._input(event)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame
