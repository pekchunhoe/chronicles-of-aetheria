extends SceneTree
## Targeted scene tests use isolated saves and staged positions; the route runner tests continuous travel.
var t: RefCounted = preload("res://tests/test_checks.gd").new()
var boot: Control
var lab: Node2D
var player: CharacterBody2D
var controls: Node
var path: String
var capture_enabled: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	controls = root.get_node("Controls")
	path = "res://artifacts/research-save-" + str(Time.get_ticks_usec()) + ".json"
	capture_enabled = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", path)
	root.add_child(boot)
	boot.validation_mode = true
	lab = boot.room.research
	player = boot.room.player
	await frames(4)
	t.check(not lab.active and not lab.progress.vector_unlocked, "legacy Citadel starts with research inactive and module locked")
	boot.room.enter_research()
	for enemy in lab.enemies: enemy.ai_enabled = false
	await frames(5)
	t.check(lab.active and boot.room.checkpoint_id == "research_a", "expedition entry activates research and saves its checkpoint")
	t.check(lab.machines.size() == 6 and lab.enemies.size() == 8, "six reusable apparatus and familiar enemies populate the chambers")
	t.check(lab.gates.cargo.get_child(0).disabled == false and not lab.bridge.visible, "unsolved physical barriers begin closed")
	boot.research_ui.interact()
	t.check(lab.progress.vector_unlocked and lab.progress.discoveries.size() == 3, "laboratory interaction installs Vector Sight and discoveries")
	await shot("laboratory")
	var ramp: Node2D = lab.machines[0]
	stage(Vector2(860, 302))
	await frames(4)
	ramp.launch()
	await frames(30)
	t.check(not ramp.experiment.running and ramp.payload.position.length() < 0.001, "static friction physically holds the default cargo")
	t.check(not ramp.latched and "cargo" not in lab.progress.completed, "static cargo cannot open the relay")
	ramp.adjust("angle", 30)
	t.check("cargo" not in lab.progress.completed, "correct numeric setting alone does not activate cargo relay")
	ramp.launch()
	await frames(24)
	var before: Vector2 = ramp.payload.position
	var velocity_before: Vector2 = ramp.experiment.velocity_si
	controls.set_virtual_action("scan", "research", true)
	await frames(2)
	controls.set_virtual_action("scan", "research", false)
	t.check(paused and boot.research_ui.mode == "sight", "Q/shared scan action opens paused Vector Sight")
	t.check(boot.research_ui.captured.velocity.length() > 1.0, "captured measured velocity remains nonzero during pause")
	await frames(10)
	t.check(ramp.payload.position.is_equal_approx(before) and ramp.experiment.velocity_si.is_equal_approx(velocity_before), "Vector Sight freezes the complete experiment without changing its velocity")
	t.near(boot.research_ui.captured.forces.a, 3.205858157775, 1e-9, "inspector acceleration matches the active force model")
	await shot("vector-forces")
	boot.research_ui.close()
	await frames(120)
	t.check(ramp.latched and ramp.contact_count == 1 and "cargo" in lab.progress.completed, "moving cargo collision activates and persists its receiver")
	t.check(lab.gates.cargo.get_child(0).disabled, "cargo contact opens actual gate collider")
	t.near(ramp.experiment.distance_m, 4.0, 0.003, "cargo collision displacement agrees with four metre guide")
	var contact_total: int = ramp.contact_count
	ramp.reset()
	t.check(ramp.latched and not ramp.contacted_once and ramp.payload.position.length() == 0, "reset restores cargo while retaining completed progression")
	ramp.launch()
	await frames(120)
	t.check(ramp.contact_count == contact_total + 1 and lab.progress.completed.count("cargo") == 1, "cargo replays without duplicated completion")
	var launcher: Node2D = lab.machines[1]
	stage(Vector2(1600, 302))
	await frames(4)
	launcher.adjust("speed", 14)
	launcher.adjust("angle", 45)
	t.near(launcher.receiver.position.x, 1280, 1e-6, "20 metre target renders 1280 world pixels away")
	t.check(not launcher.latched and not lab.bridge.visible, "launcher settings never substitute for collision")
	var predicted: PackedVector2Array = launcher.prediction.duplicate()
	launcher.launch()
	await frames(30)
	var analytic: Vector2 = MechanicsModel.to_pixels(MechanicsModel.projectile_state(14, 45, launcher.experiment.elapsed).position)
	t.near(launcher.payload.position.distance_to(analytic), 0, 0.002, "observed projectile matches analytic prediction [px]")
	t.check(launcher.prediction == predicted, "flight reuses cached prediction instead of rebuilding every frame")
	boot.research_ui.selected = launcher
	boot.research_ui.show_apparatus()
	t.check(not launcher.adjust("speed", 16), "active trajectory parameters cannot change midway through flight")
	await shot("launcher-controls")
	boot.research_ui.close()
	await frames(120)
	t.check(launcher.latched and launcher.contact_count == 1 and lab.bridge.visible, "swept projectile contacts finite receiver and restores bridge")
	t.check(launcher.experiment.elapsed < 2.0183, "finite collision face is contacted before centre-plane landing time")
	t.check(not lab.bridge.get_node("CollisionShape2D").disabled, "bridge becomes physically walkable after contact")
	launcher.reset()
	launcher.adjust("speed", 6)
	launcher.launch()
	await frames(180)
	t.check(launcher.contacted_once and launcher.contact_count == 2 and lab.progress.completed.count("crossing") == 1, "missed replay hits terrain without duplicating successful bridge progression")
	var momentum: Node2D = lab.machines[2]
	stage(Vector2(3505, 302))
	player.facing = 1
	await frames(4)
	t.check(lab.progress.impulse_unlocked and player.impulse.unlocked, "Momentum Vault entry installs Impulse Strike")
	controls.set_virtual_action("impulse_strike", "research", true)
	await frames(8)
	controls.set_virtual_action("impulse_strike", "research", false)
	t.check(momentum.experiment.last_impulse == Vector2(10, 0), "ability target query delivers the specified net impulse to cargo")
	t.check(player.impulse.cooldown_left > 1 and not player.impulse.begin(), "Impulse Strike cooldown prevents spam")
	await frames(150)
	t.check(not momentum.latched, "heavier five kilogram cargo loses too much momentum to latch")
	momentum.adjust("mass", 2)
	player.impulse.reset()
	controls.set_virtual_action("impulse_strike", "research", true)
	await frames(8)
	controls.set_virtual_action("impulse_strike", "research", false)
	t.near(momentum.experiment.velocity_si.x, 5, 0.04, "two kilogram cargo gains five metres per second then feels guide friction")
	await shot("impulse-cargo")
	await frames(55)
	t.check(momentum.latched and "vault" in lab.progress.completed, "impulsed light cargo physically latches the momentum receiver")
	t.check(momentum.experiment.parameters.mass * momentum.experiment.velocity_si.x >= 4, "incident momentum threshold is evaluated at contact")
	stage(Vector2(3035, 302))
	player.facing = 1
	player.impulse.reset()
	await frames(3)
	player.impulse.begin()
	await frames(10)
	t.check(boot.status_message.contains("anchored") and lab.enemies[2].velocity == Vector2.ZERO, "anchored turret resists impulse with an explicit explanation")
	stage(Vector2(3835, 302))
	player.facing = 1
	player.impulse.reset()
	lab.enemies[3].ai_enabled = true
	await frames(3)
	var enemy_health: int = lab.enemies[3].health.current
	player.impulse.begin()
	await frames(10)
	t.check(lab.enemies[3].velocity.x > 50 and lab.enemies[3].health.current == enemy_health, "arcade enemy impulse staggers without replacing sword damage")
	lab.enemies[3].ai_enabled = false
	stage(Vector2(3990, 132))
	await frames(4)
	t.check(lab.progress.shard, "optional upper passage research shard collects through real overlap")
	var engine: Node2D = lab.machines[3]
	stage(Vector2(4380, 302))
	await frames(4)
	engine.launch()
	await frames(60)
	t.check(engine.contacted_once and not engine.latched, "insufficient height makes actual contact without opening energy latch")
	engine.adjust("height", 2)
	engine.launch()
	await frames(15)
	boot.research_ui.toggle_sight()
	var captured: Dictionary = boot.research_ui.captured
	t.near(captured.energy.potential + captured.energy.kinetic + captured.heat, captured.initial_j, 1e-5, "Vector Sight energy terms balance during real motion")
	await shot("energy-inspection")
	boot.research_ui.close()
	await frames(45)
	t.check(engine.latched and "engine" in lab.progress.completed, "guided weight collision operates energy gate")
	t.near(engine.experiment.velocity_si.length(), 6.264183905, 0.01, "observed incident speed agrees with two metre energy benchmark")
	engine.adjust("loss", 0.2)
	engine.launch()
	await frames(60)
	var losses: Dictionary = engine.capture()
	t.near(losses.energy.potential + losses.energy.kinetic + losses.heat, losses.initial_j, 1e-5, "dissipative experiment includes thermal energy at contact")
	t.near(losses.heat, 7.848, 0.02, "observed guide thermal transfer matches specified resistance")
	boot.research_ui.selected = engine
	boot.research_ui.scholar_enabled = true
	boot.save_data.mode_choices.learning = "Scholar"
	boot.research_ui.show_scholar()
	boot.research_ui.answer.text = "999"
	boot.research_ui.submit_scholar()
	t.check(lab.progress.scholar_completed.is_empty(), "wrong optional answer gives no archive seal and never changes story")
	boot.research_ui.answer.text = str(boot.research_ui.challenge.expected)
	boot.research_ui.submit_scholar()
	t.check(lab.progress.scholar_completed.size() == 1, "correct apparatus-linked Scholar answer awards cosmetic archive seal")
	await shot("scholar-working")
	boot.research_ui.close()
	boot.research_ui.toggle_codex()
	t.check(boot.research_ui.codex.entries.size() == 9 and lab.progress.discoveries.size() == 9, "all nine journal discoveries unlock through machinery")
	boot.research_ui.selected_entry = 8
	boot.research_ui.toggle_codex_refresh()
	await shot("codex")
	boot.research_ui.close()
	var trial_ramp: Node2D = lab.machines[4]
	var trial_launcher: Node2D = lab.machines[5]
	trial_ramp.adjust("angle", 30)
	trial_ramp.launch()
	trial_launcher.adjust("speed", 14)
	trial_launcher.adjust("angle", 62)
	trial_launcher.launch()
	await frames(180)
	t.check(trial_ramp.latched and trial_launcher.latched, "integrated trial combines independent force and unequal-height projectile collisions")
	t.check(not lab.gates.trial_final.get_child(0).disabled, "final gate still requires traditional combat")
	stage(Vector2(5320, 302))
	var enemy: CharacterBody2D = lab.enemies[5]
	enemy.reset_enemy()
	enemy.ai_enabled = true
	await frames(5)
	for index in range(160):
		if enemy.health.current <= 0: break
		controls.set_virtual_axis("research", signf(enemy.global_position.x - player.global_position.x) if absf(enemy.global_position.x - player.global_position.x) > 38 else 0)
		player.facing = signf(enemy.global_position.x - player.global_position.x)
		if player.combat.attack == null:
			controls.set_virtual_action("heavy_attack", "research", true)
			controls.set_virtual_action("heavy_attack", "research", false)
		await frames(1)
	controls.release_virtual()
	t.check(enemy.health.current <= 0 and lab.progress.trial_enemy_defeated, "ordinary sword input defeats live trial crawler")
	await frames(2)
	t.check(lab.gates.trial_final.get_child(0).disabled, "combined physics relays and combat open final progression collider")
	stage(Vector2(6920, 302))
	await frames(4)
	t.check("complete" in lab.progress.completed, "recognizable research exit completes expedition")
	await shot("research-complete")
	boot._persist("Phase 3 test snapshot")
	var saved: Dictionary = boot.saves.load_save()
	t.check(saved.content_version == "phase3.0" and saved.save_schema_version == 1, "Phase 3 save advances content while retaining compatible schema")
	t.check(saved.puzzle_state[ResearchProgress.ROOT + "progress"].completed.has("engine"), "physical chamber completion persists")
	var snapshot_completed: int = lab.progress.completed.size()
	boot.queue_free()
	await frames(3)
	controls.install_defaults()
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", path)
	root.add_child(boot)
	boot.validation_mode = true
	lab = boot.room.research
	player = boot.room.player
	await frames(4)
	t.check(lab.active and lab.progress.completed.size() == snapshot_completed, "new session restores chamber completion and research checkpoint")
	t.check(lab.progress.vector_unlocked and player.impulse.unlocked, "ability unlocks survive reload")
	t.check(lab.progress.discoveries.size() == 9 and lab.progress.scholar_completed.size() == 1, "Codex discoveries and Scholar seal survive reload")
	t.check(lab.progress.shard and not lab.shard_marker.visible, "research shard persists without duplicating the collectible")
	t.check(boot.research_ui.scholar_enabled, "Scholar preference survives reload")
	t.check(lab.machines[0].experiment.elapsed == 0 and lab.machines[0].payload.position == Vector2.ZERO, "partially completed experiments safely reset on reload")
	t.check(lab.bridge.visible and lab.gates.trial_final.get_child(0).disabled, "reloaded completed mechanisms retain traversable collision state")
	boot.set_paused(true)
	boot.research_ui.toggle_codex()
	boot.research_ui.close()
	t.check(paused and boot.pause_layer.visible, "closing journal opened from pause preserves pause state")
	boot.set_paused(false)
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	boot.save_data.control_preferences.touch_visible = true
	boot.touch.show()
	await frames(4)
	t.check(boot.touch.get_node("Actions/Impulse").get_global_rect().size.x >= 60, "dedicated impulse touch target has usable landscape size")
	for action in ["scan", "impulse_strike", "codex"]:
		var pad := InputEventJoypadButton.new()
		pad.button_index = controls.export_controller_bindings()[action]
		pad.pressed = true
		t.check(pad.is_action_pressed(action), "controller action routes correctly: " + action)
	t.check(controls.rebind_controller("impulse_strike", JOY_BUTTON_MISC1), "gauntlet controller action supports an unused configurable button")
	t.check(not controls.rebind_controller("scan", JOY_BUTTON_MISC1), "controller remapping prevents duplicate button assignment")
	boot._persist("Controller remapping test")
	t.check(boot.saves.load_save().control_preferences.controller_bindings.impulse_strike == JOY_BUTTON_MISC1, "controller mapping persists alongside original keyboard preferences")
	stage(Vector2(4380, 302))
	for e in lab.enemies: e.ai_enabled = false
	await frames(4)
	await shot("touch-landscape")
	t.check(not boot.status.visible, "landscape research feedback stays clear of the new gauntlet button row")
	boot.touch.configure(1.25, 0.8)
	await frames(2)
	var hint_bounds: Rect2 = boot.research_ui.hint_panel.get_global_rect()
	t.check(not hint_bounds.intersects(boot.touch.get_node("Actions/Impulse").get_global_rect()) and not hint_bounds.intersects(boot.touch.get_node("Stick").get_global_rect()), "landscape feedback does not overlap maximum-size movement or impulse controls")
	boot.research_ui.selected = lab.machines[3]
	boot.research_ui.show_apparatus()
	await frames(3)
	t.check(boot.research_ui.panel.get_rect().end.x <= 960 and boot.research_ui.panel.get_rect().end.y <= 540, "apparatus instrument fits 960 by 540 landscape")
	var slider: HSlider = boot.research_ui.column.find_child("height", true, false)
	var previous_height: float = lab.machines[3].experiment.parameters.height
	await tap_touch(slider.get_global_rect().position + Vector2(slider.size.x * 0.8, slider.size.y * 0.5))
	t.check(lab.machines[3].experiment.parameters.height != previous_height, "native touch dispatch adjusts an apparatus slider through standard GUI")
	await shot("touch-instrument")
	var dismiss: Button = boot.research_ui.column.find_child("Dismiss", true, false)
	await tap_touch(dismiss.get_global_rect().get_center())
	t.check(boot.research_ui.mode.is_empty() and not paused, "native touch dispatch closes the instrument and restores adventure")
	boot.room.leave_research()
	t.check(not lab.active and player.world_right == 3318, "return portal restores ordinary Citadel exploration bounds")
	boot.queue_free()
	await frames(3)
	await create_timer(0.10).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	quit(t.summary())


func stage(point: Vector2) -> void:
	player.reset_to(lab.position + point)
	controls.release_virtual()


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func tap_touch(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.pressed = pressed
		event.position = root.get_screen_transform() * point
		Input.parse_input_event(event)
		await frames(2)


func shot(title: String) -> void:
	if not capture_enabled: return
	await frames(3)
	await RenderingServer.frame_post_draw
	var folder: String = "res://artifacts/phase3-screenshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	t.check(root.get_texture().get_image().save_png(folder + "/" + title + ".png") == OK, "rendered evidence saved: " + title)
