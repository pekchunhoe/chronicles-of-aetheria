extends RefCounted
## Opt-in debug export verification. Normal gameplay never invokes this script.
var boot: Control
var controls: Node


func run(application: Control) -> bool:
	boot = application
	controls = boot.get_node("/root/Controls")
	var room: Node2D = boot.room
	var player: CharacterBody2D = room.player
	var visual: Node2D = player.get_node("Visual")
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source/atlas_layout.json"))
	var art_valid: bool = layout is Dictionary and layout.atlases.size() == 3
	art_valid = art_valid and visual.sprite.sprite_frames.get_frame_count("heavy") == 4 and visual.sprite.sprite_frames.get_frame_texture("idle", 0).atlas != null
	art_valid = art_valid and ArtLibrary.TITLE_FONT.get_data().size() > 0
	if not _check(art_valid, "packaged raster atlases, animation frames, measured metadata and licensed font"):
		return false
	print("PACKAGED VISUAL PASS: raster atlases, animation frames, metadata, font")
	for enemy in room.enemies:
		enemy.ai_enabled = false
		enemy.set_physics_process(false)
	_hold("move_right", true)
	var start: float = player.position.x
	await _frames(16)
	_hold("move_right", false)
	var valid: bool = _check(player.position.x > start + 25, "movement")
	_hold("jump", true)
	await _frames(12)
	valid = _check(player.position.y < 280, "jump") and valid
	controls.release_virtual()
	player.reset_to(Vector2(940, 305))
	var crawler: CharacterBody2D = room.enemies[0]
	crawler.position = Vector2(972, 308)
	await _frames(4)
	_tap("light_attack")
	await _frames(28)
	valid = _check(crawler.health.current == crawler.health.maximum - 14, "light damage") and valid
	_tap("heavy_attack")
	await _frames(48)
	valid = _check(crawler.state == crawler.State.DEAD, "heavy / crawler death") and valid
	var turret: CharacterBody2D = room.enemies[1]
	turret.reset_enemy()
	turret.ai_enabled = true
	player.reset_to(Vector2(1740, 258))
	# Render stalls can run several physics steps between awaited process frames.
	# Observe a real shot and impact instead of assuming one wall-clock frame count.
	for index in range(120):
		await _frames(1)
		if turret.shots_fired > 0:
			turret.ai_enabled = false
			turret.set_physics_process(false)
		if player.health.current < player.health.maximum:
			break
	valid = _check(turret.shots_fired > 0 and player.health.current < player.health.maximum, "turret projectile (shots=%d, health=%d)" % [turret.shots_fired, player.health.current]) and valid
	turret.ai_enabled = false
	turret.set_physics_process(false)
	player.reset_to(Vector2(1810, 258))
	await _frames(4)
	for index in range(2):
		_tap("heavy_attack")
		await _frames(48)
	valid = _check(turret.health.current == 0, "turret destruction") and valid
	player.reset_to(Vector2(2040, 305))
	await _frames(4)
	valid = _check(room.checkpoint_id == "citadel_checkpoint" and boot.saves.load_save().checkpoint_id == "citadel_checkpoint", "relay save") and valid
	player.health.immunity_left = 0
	player.receive_hit(999, player.position, 0)
	await _frames(60)
	valid = _check(player.health.current == 100 and absf(player.position.x - 2040) < 1, "death / respawn") and valid
	for enemy in room.enemies:
		enemy.ai_enabled = false
		enemy.set_physics_process(false)
	player.reset_to(Vector2(2380, 132))
	await _frames(4)
	player.reset_to(Vector2(3200, 305))
	await _frames(4)
	var saved: Dictionary = boot.saves.load_save()
	valid = _check(room.relic_collected and room.completed, "shard / exit") and valid
	valid = _check(room.RELIC_ID in saved.collected_crystals and room.COMPLETION_ID in saved.unlocks, "progress persistence") and valid
	boot.set_paused(true)
	var point: Vector2 = player.position
	await _frames(4)
	valid = _check(player.position == point, "pause") and valid
	boot.set_paused(false)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await boot.get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path: String = boot.saves.path.get_base_dir().path_join("phase1-windows.png")
		valid = _check(boot.get_viewport().get_texture().get_image().save_png(path) == OK, "packaged screenshot") and valid
	print("PACKAGED ACTION PASS: movement, jump, sword damage, crawler death, turret projectile/destruction, relay save, death/respawn, shard, exit, pause" if valid else "FAIL: packaged action validation")
	return valid


func _check(condition: bool, title: String) -> bool:
	print(("PACKAGED CHECK PASS: " if condition else "FAIL: packaged ") + title)
	return condition


func _hold(action: String, pressed: bool) -> void:
	controls.set_virtual_action(action, "packaged_smoke", pressed)


func _tap(action: String) -> void:
	_hold(action, true)
	_hold(action, false)


func _frames(count: int) -> void:
	for index in range(count):
		await boot.get_tree().physics_frame
		await boot.get_tree().process_frame
