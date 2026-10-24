extends SceneTree
## Continuous normal-stat, live-AI expedition. No position warps after entry, no direct damage.
var t: RefCounted = preload("res://tests/test_checks.gd").new()
var boot: Control
var controls: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	controls = root.get_node("Controls")
	var path: String = "res://artifacts/research-route-" + str(Time.get_ticks_usec()) + ".json"
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", path)
	root.add_child(boot)
	boot.validation_mode = true
	boot.room.enter_research()
	var lab: Node2D = boot.room.research
	var player: CharacterBody2D = boot.room.player
	var installed: bool = false
	var strikes: int = 0
	var misses: int = 0
	var observed_contacts: Dictionary = {}
	var frames: int = 0
	var samples: Array[float] = []
	var peak_projectiles: int = 0
	var started: int = Time.get_ticks_msec()
	var draw_start: int = Engine.get_frames_drawn()
	while frames < 15000 and "complete" not in lab.progress.completed:
		await physics_frame
		await process_frame
		frames += 1
		samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		peak_projectiles = maxi(peak_projectiles, get_nodes_in_group("projectiles").size())
		if frames % 600 == 0:
			print("RESEARCH ROUTE: frame=%d x=%.1f health=%d relays=%s" % [frames, player.position.x - lab.position.x, player.health.current, str(lab.progress.completed)])
		if player.health.current <= 0:
			controls.release_virtual()
			continue
		if not installed:
			press("interact")
			installed = true
			continue
		var nearby: Node2D
		var closest: float = 104.0
		for enemy in lab.enemies:
			var separation: float = absf(enemy.global_position.x - player.global_position.x)
			if enemy.health.current > 0 and absf(enemy.global_position.y - player.global_position.y) < 40 and separation < closest:
				nearby = enemy
				closest = separation
		if nearby != null:
			var direction: float = signf(nearby.global_position.x - player.global_position.x)
			controls.set_virtual_axis("route", direction if closest > 39 or player.facing != direction else 0)
			if closest <= 48 and player.combat.attack == null:
				press("heavy_attack")
			continue
		var waiting: Node2D
		for machine in lab.machines:
			if machine.identity not in lab.progress.completed:
				waiting = machine
				break
		if waiting != null and absf(player.global_position.x - waiting.global_position.x) < 70:
			controls.set_virtual_axis("route", 0)
			if not waiting.experiment.running:
				if waiting.contacted_once:
					misses += 1
					waiting.reset()
				if waiting.kind == "momentum":
					waiting.adjust("mass", 2)
					if player.facing < 0:
						controls.set_virtual_axis("route", 1)
					elif player.impulse.cooldown_left <= 0:
						press("impulse_strike")
						strikes += 1
				elif waiting.kind == "incline":
					waiting.adjust("angle", 30)
					waiting.launch()
				elif waiting.kind == "projectile":
					waiting.adjust("speed", 14)
					waiting.adjust("angle", 62 if waiting.identity == "trial_launcher" else 45)
					waiting.camera_follow = true
					waiting.launch()
				elif waiting.kind == "energy":
					waiting.adjust("height", 2)
					waiting.launch()
			continue
		for machine in lab.machines:
			observed_contacts[machine.identity] = machine.contact_count
		controls.set_virtual_axis("route", 1)
	controls.release_virtual()
	t.check("complete" in lab.progress.completed, "continuous expedition reaches the research exit without position warps")
	t.check(lab.progress.vector_unlocked and lab.progress.impulse_unlocked, "continuous expedition unlocks both gauntlet modules")
	t.check(lab.progress.completed.size() == 8, "all six physical relays, laboratory and exit complete")
	var actual_contacts: bool = true
	for machine in lab.machines:
		actual_contacts = actual_contacts and machine.contact_count > 0 and machine.latched
	t.check(actual_contacts, "every experimental relay receives actual collision contact")
	t.check(lab.progress.trial_enemy_defeated and lab.cleared_enemy_ids.size() == 8, "ordinary sword input defeats all eight live enemies")
	t.check(player.health.current > 0, "expedition completes alive with normal damage and health")
	t.check(strikes >= 1 and misses == 0, "ordinary Impulse Strike input activates the vault without scripted success")
	t.check(lab.progress.discoveries.size() == 9 and lab.progress.scholar_completed.is_empty(), "all Codex entries unlock with Scholar Mode disabled")
	t.check(peak_projectiles <= 4, "live research combat keeps hostile projectiles bounded")
	t.check(boot.saves.load_save().puzzle_state["citadel.research.progress"].completed.has("complete"), "exit progression persists during continuous play")
	var wall_seconds: float = float(Time.get_ticks_msec() - started) / 1000
	var average: float = 0
	for sample in samples: average += sample / maxf(1, samples.size())
	samples.sort()
	print("RESEARCH PERFORMANCE: physics_steps=%d wall_seconds=%.2f rendered_fps=%.2f mean_process_ms=%.3f p95_process_ms=%.3f renderer=%s" % [frames, wall_seconds, float(Engine.get_frames_drawn() - draw_start) / wall_seconds, average, samples[int(samples.size() * 0.95)], DisplayServer.get_name()])
	boot.queue_free()
	await process_frame
	await create_timer(0.10).timeout
	t.check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("axiom_apparatus").is_empty(), "research route teardown releases every apparatus and enemy")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	quit(t.summary())


func press(action: String) -> void:
	controls.set_virtual_action(action, "route", true)
	controls.set_virtual_action(action, "route", false)
