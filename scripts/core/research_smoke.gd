extends RefCounted
## Runs inside the exported pack, with the boot's isolated smoke-save path.


func run(boot: Control) -> bool:
	var lab: ResearchChambers = boot.room.research
	var player: FoundationPlayer = boot.room.player
	boot.room.enter_research()
	for enemy in lab.enemies: enemy.ai_enabled = false
	boot.research_ui.interact()
	var valid: bool = _check(lab.active and lab.progress.vector_unlocked, "packaged laboratory and Vector Sight unlock")
	player.reset_to(lab.position + Vector2(3505, 302))
	player.facing = 1
	await _frames(4, boot)
	var cargo: AxiomApparatus = lab.machines[2]
	cargo.adjust("mass", 2)
	player.impulse.begin()
	await _frames(10, boot)
	valid = _check(cargo.experiment.last_impulse == Vector2(10, 0), "packaged ability delivers real cargo impulse") and valid
	for machine in lab.machines:
		match machine.kind:
			"incline": machine.adjust("angle", 30)
			"projectile":
				machine.adjust("speed", 14)
				machine.adjust("angle", 62 if machine.identity == "trial_launcher" else 45)
			"energy": machine.adjust("height", 2)
		if machine.kind != "momentum": machine.launch()
	await _frames(180, boot)
	for machine in lab.machines:
		valid = _check(machine.latched and machine.contact_count > 0, "packaged physical contact: " + machine.identity) and valid
	player.reset_to(lab.position + Vector2(4380, 302))
	await _frames(3, boot)
	boot.research_ui.selected = lab.machines[3]
	boot.research_ui.toggle_sight()
	valid = _check(boot.get_tree().paused and boot.research_ui.captured.velocity.length() > 6, "packaged Vector Sight preserves incident measurement") and valid
	boot.research_ui.close()
	var codex := PhysicsCodex.new()
	valid = _check(codex.load_entries() and lab.progress.discoveries.size() == 9, "packaged offline Codex and nine discoveries") and valid
	var glyph_font: FontFile = GameTheme.SCIENTIFIC_FALLBACK
	var glyphs_present: bool = true
	for character in "θμΔ²ₛₖₚₓᵧ⁻¹Σ√≤≥∥λ°½−":
		glyphs_present = glyphs_present and TextServerManager.get_primary_interface().font_has_char(glyph_font.get_rids()[0], character.unicode_at(0))
	valid = _check(glyphs_present and FileAccess.file_exists("res://assets/fonts/DejaVu-LICENSE.txt"), "packaged scientific glyphs and font license") and valid
	var challenge: Dictionary = ScholarChallenges.build("energy", lab.machines[3].experiment.parameters)
	valid = _check(ScholarChallenges.check_answer(challenge, "6.26").correct, "packaged Scholar numerical tolerance") and valid
	boot._persist("Packaged research validation")
	var restored := ResearchProgress.new()
	restored.restore(boot.saves.load_save())
	valid = _check(restored.completed.size() >= 7 and restored.vector_unlocked and restored.impulse_unlocked, "packaged research save reload") and valid
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		boot.research_ui.selected = lab.machines[3]
		boot.research_ui.toggle_sight()
		await boot.get_tree().process_frame
		await RenderingServer.frame_post_draw
		valid = _check(boot.get_viewport().get_texture().get_image().save_png(boot.saves.path.get_base_dir().path_join("phase3-packaged.png")) == OK, "packaged graphical research capture") and valid
		boot.research_ui.close()
	return valid


func _frames(count: int, boot: Control) -> void:
	for index in range(count):
		await boot.get_tree().physics_frame
		await boot.get_tree().process_frame


func _check(condition: bool, label: String) -> bool:
	print(("PACKAGED RESEARCH PASS: " if condition else "FAIL: ") + label)
	return condition
