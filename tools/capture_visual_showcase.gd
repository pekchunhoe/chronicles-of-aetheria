extends SceneTree
## Deterministic review poses in the actual game. Also works against the Phase 1 tree.
var boot: Control
var player: CharacterBody2D
var room: Node2D
var destination: String = "res://artifacts/phase2-after"
var save_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--destination="):
			destination = argument.trim_prefix("--destination=")
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: visual showcase needs a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	save_path = "res://artifacts/showcase_save_" + str(Time.get_ticks_usec()) + ".json"
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	boot.validation_mode = true
	room = boot.room
	player = room.player
	for enemy in room.enemies:
		enemy.set_physics_process(false)
	await _settle(Vector2(128, 305))
	await _shot("idle")
	player.velocity.x = 180
	await _shot("run")
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	root.get_node("Controls").set_virtual_action("jump", "showcase", true)
	await _frames(2)
	player.set_physics_process(false)
	await _shot("jump-start", 0)
	player.set_physics_process(true)
	await _frames(8)
	player.set_physics_process(false)
	await _shot("jump-rise")
	player.set_physics_process(true)
	await _frames(18)
	root.get_node("Controls").release_virtual()
	player.set_physics_process(false)
	await _shot("jump-fall")
	player.set_physics_process(true)
	for index in range(40):
		await _frames(1)
		if player.is_on_floor():
			break
	player.set_physics_process(false)
	await _shot("land")
	for combo in range(3):
		player.combat.combo_left = 1
		player.combat.combo_index = combo - 1
		player.combat.request("light", 1)
		player.combat.elapsed = player.combat.attack.startup + player.combat.attack.active * 0.35
		player.combat.queue_redraw()
		await _shot("light-" + str(combo + 1))
		player.combat.cancel()
	player.combat.request("heavy", -1)
	await _shot("heavy-windup")
	player.combat.elapsed = player.combat.attack.startup + 0.02
	player.combat.queue_redraw()
	await _shot("heavy")
	player.combat.cancel()
	player.dodge.begin(1)
	player.dodge.elapsed = 0.08
	player.queue_redraw()
	await _shot("dodge")
	player.dodge.reset()
	player.hurt_left = 0.12
	await _shot("hurt")
	player.hurt_left = 0
	player.health.current = 0
	player.health.changed.emit(0, player.health.maximum)
	player.death_left = 0.45
	await _shot("death")
	player.reset_to(Vector2(128, 305))
	await _shot("respawn")
	await _settle(Vector2(920, 305))
	room.enemies[0].state = 2
	room.enemies[0].state_time = 0.1
	await _shot("crawler")
	await _settle(Vector2(1760, 256))
	room.enemies[1].state = 4
	room.enemies[1].state_time = room.enemies[1].profile.telegraph_seconds * 0.75
	room.enemies[1].aim_direction = Vector2.LEFT
	await _shot("turret")
	await _settle(Vector2(2080, 305))
	room.set_checkpoint("citadel_checkpoint")
	await _shot("checkpoint")
	await _settle(Vector2(2320, 136))
	await _shot("collectible")
	await _settle(Vector2(3120, 305))
	await _shot("exit")
	await _settle(Vector2(1360, 208))
	await _shot("environment")
	await _settle(Vector2(128, 305))
	boot.save_data.control_preferences.touch_visible = true
	boot.touch.visible = true
	boot._refresh_status()
	await _shot("touch")
	boot.set_paused(true)
	await _shot("pause")
	if player.has_node("Visual"):
		boot.pause_scroll.scroll_vertical = 650
		await _shot("presentation-settings")
		boot.set_paused(false)
		root.size = Vector2i(960, 540)
		root.content_scale_size = Vector2i(960, 540)
		await _frames(4)
		await _shot("touch-landscape")
	boot.set_paused(false)
	boot.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	print("SHOWCASE PASS: 23 rendered review states saved to ", destination)
	quit()


func _settle(point: Vector2) -> void:
	player.set_physics_process(true)
	player.reset_to(point)
	await _frames(25)
	player.set_physics_process(false)


func _shot(title: String, settle_frames: int = 2) -> void:
	await _frames(settle_frames)
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(destination + "/" + title + ".png")
	if error != OK:
		printerr("FAIL: screenshot ", title, " error ", error)
		quit(1)
	if title == "idle" or title == "environment":
		boot.get_node("WorldViewport").get_texture().get_image().save_png(destination + "/" + title + "-native.png")


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame
