extends SceneTree
## A continuous input-driven run from the normal spawn to the exit, with live AI.
## No teleports, disabled enemies, boosted stats or direct damage calls in the run.
const Checks = preload("res://tests/test_checks.gd")
var t := Checks.new()
var boot: Control
var controls: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "res://artifacts/route_save_" + str(Time.get_ticks_usec()) + ".json"
	controls = root.get_node("Controls")
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", path)
	root.add_child(boot)
	boot.validation_mode = true
	var player: CharacterBody2D = boot.room.player
	var jump_held: bool = false
	var defeats: Array[int] = []
	var peak_projectiles: int = 0
	var cpu_samples: Array[float] = []
	var physics_total_ms: float = 0.0
	var frames: int = 0
	var started: int = Time.get_ticks_msec()
	var draw_start: int = Engine.get_frames_drawn()
	while frames < 3000 and not boot.room.completed:
		await physics_frame
		await process_frame
		frames += 1
		peak_projectiles = maxi(peak_projectiles, get_nodes_in_group("projectiles").size())
		cpu_samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_total_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		for enemy in boot.room.enemies:
			if enemy.health.current == 0 and enemy.get_instance_id() not in defeats:
				defeats.append(enemy.get_instance_id())
		if frames % 300 == 0:
			print("ROUTE: frame=%d position=%s health=%d defeated=%d" % [frames, str(player.position), player.health.current, defeats.size()])
		if player.health.current <= 0:
			controls.release_virtual()
			continue
		var nearby: Node2D
		var closest: float = 115.0
		for enemy in boot.room.enemies:
			var distance: float = absf(enemy.position.x - player.position.x)
			if enemy.health.current > 0 and absf(enemy.position.y - player.position.y) < 32 and distance < closest:
				nearby = enemy
				closest = distance
		var axis: float = 1.0
		if nearby != null:
			axis = signf(nearby.position.x - player.position.x)
			if closest <= 45.0:
				if player.combat.attack == null:
					controls.set_virtual_action("heavy_attack", "route", true)
					controls.set_virtual_action("heavy_attack", "route", false)
				if player.facing == axis:
					axis = 0.0
		controls.set_virtual_axis("route", axis)
		if jump_held and player.velocity.y >= 0:
			jump_held = false
			controls.set_virtual_action("jump", "route", false)
		var x: float = player.position.x
		var y: float = player.position.y
		var jump_zone: bool = (x >= 400 and x < 445 and y > 285) or (x >= 1120 and x < 1168 and y > 280) or (x >= 1248 and x < 1296 and y > 232) or (x >= 1360 and x < 1408 and y > 184) or (x >= 2400 and x < 2445 and y > 285)
		if nearby == null and player.is_on_floor() and jump_zone and not jump_held:
			jump_held = true
			controls.set_virtual_action("jump", "route", true)
	controls.release_virtual()
	t.check(boot.room.completed, "continuous live-AI run reaches the exit using movement, jumps and sword input")
	t.check(defeats.size() == 5, "continuous run defeats all three crawlers and both turrets")
	t.check(boot.room.checkpoint_id == "citadel_checkpoint" and boot.saves.load_save().checkpoint_id == "citadel_checkpoint", "continuous run activates and saves the relay")
	t.check(player.health.current > 0, "continuous run completes alive with ordinary health and damage")
	t.check(peak_projectiles <= 4, "live combat keeps projectile population bounded")
	var average_cpu: float = 0.0
	for sample in cpu_samples:
		average_cpu += sample / maxf(1, cpu_samples.size())
	cpu_samples.sort()
	var p95: float = cpu_samples[int(cpu_samples.size() * 0.95)]
	var elapsed: float = float(Time.get_ticks_msec() - started) / 1000.0
	var rendered_fps: float = float(Engine.get_frames_drawn() - draw_start) / elapsed
	print("ROUTE METRICS: physics_steps=%d wall_seconds=%.2f mean_process_ms=%.3f p95_process_ms=%.3f mean_physics_ms=%.3f rendered_fps=%.2f peak_projectiles=%d renderer=%s" % [frames, elapsed, average_cpu, p95, physics_total_ms / maxf(1, frames), rendered_fps, peak_projectiles, DisplayServer.get_name()])
	boot.queue_free()
	await process_frame
	# Allow the audio mix thread to release its final completion cue before shutdown.
	await create_timer(0.08).timeout
	t.check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("projectiles").is_empty() and get_nodes_in_group("player").is_empty(), "scene teardown removes every actor and projectile")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	quit(t.summary())
