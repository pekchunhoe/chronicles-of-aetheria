extends SceneTree
## Real scene/physics-tree smoke tests. Synthetic input != hardware certification.
const Checks = preload("res://tests/test_checks.gd")
var t := Checks.new()
var boot: Control
var controls: Node
var save_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	controls = root.get_node("Controls")
	save_path = "res://artifacts/scene_save_" + str(Time.get_ticks_usec()) + ".json"
	# Runtime load: --script parses before project autoload globals are registered.
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	await _frames(5)
	var room: Node2D = boot.room
	var player: CharacterBody2D = room.player
	t.check(boot.get_node("WorldViewport").size == Vector2i(640, 360), "world renders at 640 x 360 independently of UI")
	t.check(player.is_on_floor(), "player settles on collidable ground")
	# Send physical-key events through Godot's Input dispatch, rather than calling movement.
	var start_x: float = player.position.x
	_key(KEY_D, true)
	await _frames(24)
	_key(KEY_D, false)
	t.check(player.position.x > start_x + 40.0, "keyboard D moves player right")
	await _frames(8)
	var grounded_y: float = player.position.y
	_key(KEY_SPACE, true)
	await _frames(10)
	t.check(player.position.y < grounded_y - 30.0, "keyboard Space jumps")
	_key(KEY_SPACE, false)
	await _frames(45)
	t.check(player.is_on_floor(), "jump lands without falling through floor")
	# Test actual elevated platform and the intentional gap from repeatable starts.
	player.reset_to(Vector2(200, 305))
	await _frames(3)
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	await _frames(33)
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	await _frames(8)
	t.check(player.is_on_floor() and player.position.y < 260, "platform can be reached and landed on")
	player.reset_to(Vector2(410, 305))
	await _frames(4)
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	await _frames(43)
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	await _frames(8)
	t.check(player.is_on_floor() and player.position.x > 528, "graybox pit is traversable with a held jump")
	# Synthetic controller events travel through the same InputMap.
	var before_joy: float = player.position.x
	var joy := InputEventJoypadMotion.new()
	joy.device = 0
	joy.axis = JOY_AXIS_LEFT_X
	joy.axis_value = 1.0
	Input.parse_input_event(joy)
	await _frames(12)
	joy = InputEventJoypadMotion.new()
	joy.device = 0
	joy.axis = JOY_AXIS_LEFT_X
	joy.axis_value = 0.0
	Input.parse_input_event(joy)
	t.check(player.position.x > before_joy + 20, "synthetic controller axis moves player")
	_key(KEY_ESCAPE, true)
	await process_frame
	_key(KEY_ESCAPE, false)
	await process_frame
	t.check(paused and boot.pause_layer.visible, "Escape opens pause menu")
	var paused_position: Vector2 = player.position
	_key(KEY_D, true)
	await _frames(10)
	_key(KEY_D, false)
	t.check(player.position.is_equal_approx(paused_position), "paused player and collision world do not advance")
	boot.set_paused(false)
	await _frames(2)
	# A valid interaction records a stable discovery and accepted model inputs.
	boot._run_sample()
	t.check(boot.save_data.discoveries.size() == 1 and boot.puzzle.solved, "bench interaction validates and saves discovery")
	boot.save_data.control_preferences.touch_visible = true
	boot.touch.visible = true
	boot._refresh_status()
	await process_frame
	var jump: Control = boot.touch.get_node("Actions/Jump")
	var stick: Control = boot.touch.get_node("Stick")
	_touch(stick, 0, stick.get_global_rect().get_center() + Vector2(60, 0), true)
	_touch(jump, 1, jump.get_global_rect().get_center(), true)
	t.check(controls.movement_axis() > 0.5 and controls.held("jump"), "two synthetic fingers can move and jump simultaneously")
	_touch(jump, 1, Vector2.ZERO, false)
	t.check(not controls.held("jump") and controls.movement_axis() > 0.5, "releasing jump finger preserves movement finger")
	_touch(stick, 0, Vector2.ZERO, false)
	t.near(controls.movement_axis(), 0.0, 0.001, "releasing stick resets virtual axis")
	# Also verify viewport dispatch reaches the authored overlay, not only its handlers.
	var routed_touch := InputEventScreenTouch.new()
	routed_touch.index = 7
	routed_touch.position = root.get_screen_transform() * jump.get_global_rect().get_center()
	routed_touch.pressed = true
	Input.parse_input_event(routed_touch)
	await process_frame
	t.check(controls.held("jump"), "Godot viewport dispatch reaches touch jump control")
	routed_touch = InputEventScreenTouch.new()
	routed_touch.index = 7
	routed_touch.position = root.get_screen_transform() * jump.get_global_rect().get_center()
	routed_touch.pressed = false
	Input.parse_input_event(routed_touch)
	await process_frame
	t.check(not controls.held("jump"), "Godot viewport dispatch releases touch jump control")
	# Touch release must not cancel a physically held jump key.
	_key(KEY_SPACE, true)
	await process_frame
	_touch(jump, 1, jump.get_global_rect().get_center(), true)
	_touch(jump, 1, Vector2.ZERO, false)
	t.check(controls.held("jump"), "touch release preserves physical keyboard hold")
	_key(KEY_SPACE, false)
	_touch(stick, 0, stick.get_global_rect().get_center() + Vector2(60, 0), true)
	boot.touch.hide()
	t.near(controls.movement_axis(), 0.0, 0.001, "hidden overlay releases virtual movement")
	boot.touch.show()
	controls.rebind_key("jump", KEY_F)
	boot._persist("Test binding")
	var saved_jump: Array = boot.saves.load_save().control_preferences.bindings.jump
	t.check(saved_jump.size() == 1 and int(saved_jump[0]) == KEY_F, "remapped key persists")
	player.reset_to(Vector2(760, 304))
	await _frames(5)
	t.check(room.checkpoint_id == "east_checkpoint", "checkpoint area activates on collision")
	t.check(boot.saves.load_save().checkpoint_id == "east_checkpoint", "checkpoint saved on activation")
	player.position.y = 480
	await _frames(3)
	t.near(player.position.x, 760.0, 0.1, "fall respawns at saved checkpoint x [px]")
	# Background handling is simulated; actual Android lifecycle remains a device gate.
	boot._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await process_frame
	t.check(paused and boot.saves.load_save().checkpoint_id == "east_checkpoint", "background notification pauses and persists")
	boot.set_paused(false)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		room.set_checkpoint("room_start")
		room.respawn()
		boot.bench.hide()
		await _frames(30)
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		t.check(image.save_png("res://artifacts/phase0-touch.png") == OK, "rendered touch overlay screenshot saved")
		boot.bench.show()
		boot._run_sample()
		await process_frame
		await RenderingServer.frame_post_draw
		t.check(root.get_texture().get_image().save_png("res://artifacts/phase0-bench.png") == OK, "rendered SI model bench screenshot saved")
		boot.bench.hide()
		boot.set_paused(true)
		await process_frame
		await RenderingServer.frame_post_draw
		t.check(root.get_texture().get_image().save_png("res://artifacts/phase0-pause.png") == OK, "rendered pause menu screenshot saved")
		boot.set_paused(false)
	boot.queue_free()
	await process_frame
	controls.install_defaults()
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	await _frames(5)
	t.check(boot.room.checkpoint_id == "east_checkpoint", "new session restores saved checkpoint")
	t.check(boot.puzzle.solved and boot.save_data.discoveries.size() == 1, "new session restores puzzle and concept discovery")
	t.check(controls.binding_label("jump") == "F", "new session restores keyboard mapping")
	boot.queue_free()
	await process_frame
	controls.install_defaults()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit(t.summary())


func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


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
