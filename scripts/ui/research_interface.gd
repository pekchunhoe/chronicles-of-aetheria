class_name ResearchInterface
extends Control
## High resolution fantasy instrument. All model state comes from the selected apparatus.
var host: Control
var lab: ResearchChambers
var selected: AxiomApparatus
var codex := PhysicsCodex.new()
var panel: PanelContainer
var column: VBoxContainer
var scroll: ScrollContainer
var hint_panel: PanelContainer
var hint: Label
var mode: String = ""
var previous_paused: bool = false
var captured: Dictionary = {}
var overlay: Node2D
var scholar_enabled: bool = false
var challenge: Dictionary = {}
var answer: LineEdit
var scholar_feedback: RichTextLabel
var scholar_variant: int = 0
var trajectory_map: Control
var parameter_labels: Dictionary = {}
var measurements: RichTextLabel
var selected_entry: int = 0
var last_notice: String = ""
var notice_left: float = 0.0

class TrajectoryMap extends Control:
	var machine: AxiomApparatus
	func _draw() -> void:
		if not is_instance_valid(machine) or machine.prediction.size() < 2:
			return
		var p: Dictionary = machine.experiment.parameters
		var scale_factor: float = (size.x - 30) / (24.0 * 64.0)
		var origin := Vector2(12, size.y - 22)
		for index in range(1, machine.prediction.size()):
			draw_line(origin + machine.prediction[index - 1] * scale_factor, origin + machine.prediction[index] * scale_factor, Color("7edfc7"), 1.5)
		var target: Vector2 = origin + machine.receiver.position * scale_factor
		draw_rect(Rect2(target - Vector2(3, 5), Vector2(6, 10)), Color("e6bd79"), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(12, size.y - 3), "Ideal path · receiver %.1f m away" % (p.target_x - p.launch_x), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("a9cfc3"))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	codex.load_entries()
	lab = host.room.research
	scholar_enabled = host.save_data.mode_choices.get("learning", "Adventure") == "Scholar"
	overlay = preload("res://scripts/presentation/vector_overlay.gd").new()
	host.get_node("WorldViewport").add_child(overlay)
	_build_hint()
	panel = PanelContainer.new()
	panel.name = "AxiomInstrument"
	panel.visible = false
	add_child(panel)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	resized.connect(_layout)
	_layout()


func _build_hint() -> void:
	hint_panel = PanelContainer.new()
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.add_theme_stylebox_override("panel", GameTheme.panel(Color(0.04, 0.08, 0.105, 0.90), Color("3b776c")))
	add_child(hint_panel)
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 16)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_panel.add_child(hint)


func _layout() -> void:
	var available: Vector2 = size
	if available.x < 1: available = get_viewport_rect().size
	var compact: bool = available.x < 1100
	var wide: bool = mode in ["codex", "scholar"]
	var width: float = minf(820 if wide else 390, available.x - 48)
	var height: float = minf(540 if wide else 510, available.y - (172 if compact else 178))
	panel.position = Vector2((available.x - width) * 0.5 if wide else available.x - width - 24, 154 if compact else 158)
	panel.size = Vector2(width, maxf(220, height))
	scroll.custom_minimum_size = Vector2(width - 38, maxf(200, height - 24))
	hint_panel.position = Vector2(24, 154 if compact else 158)
	hint_panel.size = Vector2(minf(650, available.x - 48), 0)
	hint_panel.custom_minimum_size.x = minf(650, available.x - 48)


func _process(delta: float) -> void:
	if host.status_message != last_notice:
		last_notice = host.status_message
		notice_left = 0.0 if last_notice.begins_with("Checkpoint") else 4.0
	notice_left = maxf(0.0, notice_left - delta)
	hint_panel.visible = lab.active and mode.is_empty() and not get_tree().paused
	if not hint_panel.visible:
		return
	host.room.player.impulse.unlocked = lab.progress.impulse_unlocked
	var x: float = host.room.player.global_position.x - lab.global_position.x
	var machine: AxiomApparatus = lab.nearest_machine()
	var context: String
	if x < 360 and not lab.progress.vector_unlocked:
		context = "Mira: The diagnostic module waits on the teal pedestal. %s: install Vector Sight." % Controls.binding_label("interact")
	elif x < 130 or x > 6880:
		context = "%s: return to the Citadel. Tab / Codex: journal." % Controls.binding_label("interact")
	elif machine != null:
		context = "%s: tune %s · %s: Vector Sight\n%s" % [Controls.binding_label("interact"), machine.identity.replace("_", " "), Controls.binding_label("scan"), machine.experiment.result_text]
		if machine.kind == "momentum":
			context += "\nFace the cargo: %s Impulse Strike · cooldown %.1f s" % [Controls.binding_label("impulse_strike"), host.room.player.impulse.cooldown_left]
	else:
		context = "Explore the chambers. The teal relays save your discoveries. %s: journal." % Controls.binding_label("codex")
	var mobile: bool = host._touch_enabled()
	hint.max_lines_visible = 5 if mobile else -1
	hint.text = lab.room_name + "\n" + (last_notice if mobile and notice_left > 0 else context)


func interact() -> bool:
	if not lab.active:
		if host.room.player.position.x > 3090:
			host.room.enter_research()
			return true
		return false
	var x: float = host.room.player.global_position.x - lab.global_position.x
	if x < 130 or x > 6880:
		host.room.leave_research()
		return true
	if not lab.progress.vector_unlocked:
		if x < 400:
			lab.unlock_vector()
		else:
			host._persist("Return to the laboratory pedestal to install the diagnostic module.")
		return true
	selected = lab.nearest_machine()
	if selected != null:
		show_apparatus()
		return true
	return false


func toggle_sight() -> void:
	if mode == "sight":
		close()
		return
	if not lab.progress.vector_unlocked:
		host._persist("Mira: Install the diagnostic module at the Lost Laboratory pedestal first.")
		return
	selected = lab.nearest_machine()
	if selected == null:
		host._persist("Vector Sight: approach a bronze cargo guide, launcher, or energy engine.")
		return
	captured = selected.capture()
	_open("sight")
	selected.inspected = true
	overlay.snapshot = captured.duplicate(true)
	overlay.queue_redraw()
	_title("VECTOR SIGHT", "Captured simulation · %s" % selected.identity.replace("_", " "))
	_label("%s\nForce arrows: 0.65 world px per N.\nPositive SI directions: right / up; incline: downhill." % ("Incident contact snapshot; receiver absorbs the subsequent motion." if captured.contact else "Time is paused. Velocity is the measured captured velocity."), 15)
	measurements = _rich(_describe(captured))
	if selected.kind == "projectile":
		_add_map()
	_button("Tune this machine", show_apparatus)
	_button("Resume observation", close)
	_layout()


func _describe(data: Dictionary) -> String:
	var text: String = "[color=#86e2c6]Mass %.2f kg · elapsed %.3f s[/color]\nDisplacement (%.3f, %.3f) m\nVelocity (%.3f, %.3f) m s⁻¹\nAcceleration (%.3f, %.3f) m s⁻²" % [data.mass, data.time, data.position.x, data.position.y, data.velocity.x, data.velocity.y, data.acceleration.x, data.acceleration.y]
	match data.kind:
		"incline":
			var f: Dictionary = data.forces
			text += "\n\nθ = %.1f° · %s\nWeight %.3f N downward\nNormal %.3f N perpendicular to ramp\nDownslope weight %.3f N\nFriction %+.3f N along plane\nStatic limit %.3f N\nNet force %+.3f N along plane\nNo external applied force. ΣF is the resultant, not an additional interaction force." % [data.angle, "STATIC" if f.static else "KINETIC", f.weight_n, f.normal_n, f.parallel_n, f.friction_n, f.static_limit_n, f.net_n]
		"projectile":
			var trajectory: Dictionary = data.prediction
			text += "\n\nWeight %.3f N downward; no drag.\nApex above launch %.3f m." % [data.weight, trajectory.height]
			text += "\nDescending elevation crossing: %.3f s, Δx %.3f m. Receiver contact includes its 24 × 48 px face and the 4 px projectile radius." % [trajectory.flight, trajectory.range] if trajectory.reachable else "\nReceiver elevation is unreachable with these settings."
		"momentum":
			text += "\n\nMomentum (%.3f, %.3f) kg m s⁻¹\nDelivered impulse (%.2f, %.2f) N s\nLater rail friction: μ = 0.10.\nThermal transfer %.3f J.\nLatch requires incident rightward momentum ≥ 4 N s." % [data.momentum.x, data.momentum.y, data.impulse.x, data.impulse.y, data.heat]
		"energy":
			text += "\n\nPotential %.4f J\nKinetic %.4f J\nThermal transfer %.4f J\nInitial energy %.4f J\nUpward guide resistance = λmg.\nLatch captures cargo at incident Eₖ ≥ 20 J. Remaining energy transfers to the machinery and surroundings." % [data.energy.potential, data.energy.kinetic, data.heat, data.initial_j]
	return text


func show_apparatus() -> void:
	if not is_instance_valid(selected):
		return
	_open("apparatus")
	_title(selected.identity.replace("_", " ").to_upper(), _machine_hint(selected.kind))
	_label("SI controls · 64 px = 1 m · free resets.\nCompleted relays stay latched.", 15)
	parameter_labels.clear()
	for key in selected.parameter_ranges():
		var bounds: Array = selected.parameter_ranges()[key]
		var row := VBoxContainer.new()
		column.add_child(row)
		var label := Label.new()
		label.text = _parameter_caption(key, selected.experiment.parameters[key])
		label.add_theme_font_size_override("font_size", 17)
		row.add_child(label)
		parameter_labels[key] = label
		var slider := HSlider.new()
		slider.name = key
		slider.min_value = bounds[0]
		slider.max_value = bounds[1]
		slider.step = bounds[2]
		slider.value = selected.experiment.parameters[key]
		slider.custom_minimum_size.y = 44
		slider.editable = not selected.experiment.running
		slider.value_changed.connect(func(value: float):
			if selected.adjust(key, value):
				parameter_labels[key].text = _parameter_caption(key, value)
				if is_instance_valid(trajectory_map): trajectory_map.queue_redraw()
		)
		row.add_child(slider)
	if selected.kind == "projectile":
		_add_map()
		var follow := CheckButton.new()
		follow.text = "Follow projectile camera"
		follow.add_theme_font_size_override("font_size", 17)
		follow.button_pressed = true
		selected.camera_follow = true
		follow.toggled.connect(func(value: bool): selected.camera_follow = value)
		column.add_child(follow)
	if selected.kind != "momentum":
		_button("Release / fire and observe", func():
			if selected.launch(): close()
		)
	else:
		_label("Reset the cargo, return to the world, face right, and use %s. Try both 5 kg and 2 kg." % Controls.binding_label("impulse_strike"), 17)
	_button("Reset this experiment", func():
		selected.reset()
		show_apparatus()
	)
	_button("Vector Sight", toggle_sight)
	var scholar := CheckButton.new()
	scholar.text = "Scholar Mode · optional"
	scholar.add_theme_font_size_override("font_size", 17)
	scholar.button_pressed = scholar_enabled
	scholar.toggled.connect(func(enabled: bool):
		scholar_enabled = enabled
		host.save_data.mode_choices["learning"] = "Scholar" if enabled else "Adventure"
		host._persist("Learning preference saved. Scholar Mode never gates the story.")
		show_apparatus()
	)
	column.add_child(scholar)
	if scholar_enabled:
		_button("Study these exact settings", show_scholar)
	_button("Return to adventure", close)
	_layout()


func _machine_hint(kind: String) -> String:
	match kind:
		"incline": return "Deliver ≥ 8 kg cargo to the receiver. Increase slope to overcome static friction."
		"projectile": return "Hit the distant relay. Adjust speed and angle; the miniature predicts the ideal path."
		"momentum": return "Strike cargo with 10 N s. The rough rail's latch needs ≥ 4 N s on arrival."
		"energy": return "Release the raised weight. Its receiver needs ≥ 20 J at physical contact. Reset supplies external lifting work."
	return ""


func _parameter_caption(key: String, value: float) -> String:
	var units: Dictionary = {"mass": "kg", "angle": "°", "speed": "m s⁻¹", "height": "m", "g": "m s⁻²", "launch_x": "m", "launch_y": "m", "target_x": "m", "target_y": "m"}
	var names: Dictionary = {"mu_s": "Static coefficient μₛ", "mu_k": "Kinetic coefficient μₖ", "loss": "Loss fraction λ", "g": "Gravity", "target_y": "Receiver elevation", "target_x": "Receiver horizontal position", "launch_x": "Launch horizontal position", "launch_y": "Launch elevation"}
	return "%s  %.2f %s" % [names.get(key, key.capitalize()), value, units.get(key, "(dimensionless)")]


func _add_map() -> void:
	var map := TrajectoryMap.new()
	map.machine = selected
	map.custom_minimum_size = Vector2(0, 135)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(map)
	trajectory_map = map


func toggle_codex() -> void:
	if mode == "codex":
		close()
		return
	_open("codex")
	_title("PHYSICS CODEX", "Offline field journal · %d / 9 discoveries · %d archive seals" % [lab.progress.discoveries.size(), lab.progress.scholar_completed.size()])
	var choose := OptionButton.new()
	choose.custom_minimum_size.y = 48
	for entry in codex.entries:
		choose.add_item(entry.title if entry.id in lab.progress.discoveries else "Undiscovered · " + entry.title)
	choose.selected = selected_entry
	choose.item_selected.connect(func(index: int):
		selected_entry = index
		toggle_codex_refresh()
	)
	column.add_child(choose)
	var entry: Dictionary = codex.entries[selected_entry]
	_rich(codex.text_for(entry) if entry.id in lab.progress.discoveries else "Explore the Axiom Research Chambers and operate its machinery to recover this record.")
	_button("Return to adventure", close)
	_layout()


func toggle_codex_refresh() -> void:
	mode = "refresh"
	toggle_codex()


func show_scholar() -> void:
	if not is_instance_valid(selected): return
	challenge = ScholarChallenges.build(selected.kind, selected.experiment.parameters, scholar_variant)
	_open("scholar")
	_title("SCHOLAR ARCHIVE", "Optional · simulation paused · copied apparatus settings")
	_label(_scholar_parameters(challenge.parameters), 16)
	_label(challenge.question, 20)
	_label("Required unit: " + challenge.unit, 19)
	answer = LineEdit.new()
	answer.name = "ScholarAnswer"
	answer.placeholder_text = "Enter a number in " + challenge.unit
	answer.custom_minimum_size.y = 50
	answer.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	column.add_child(answer)
	answer.text_submitted.connect(func(_value: String): submit_scholar())
	_button("Check answer and show working", submit_scholar)
	scholar_feedback = _rich("Rounded answers are accepted. No penalty for retrying; archive seals are cosmetic.")
	_button("Another question from these settings", func():
		scholar_variant += 1
		show_scholar()
	)
	_button("Back to machine", show_apparatus)
	_button("Return to adventure", close)
	_layout()
	answer.grab_focus()


func _scholar_parameters(p: Dictionary) -> String:
	match selected.kind:
		"incline": return "m = %.2f kg; θ = %.2f°; μₛ = %.2f; μₖ = %.2f; g = %.2f m s⁻²; released from rest." % [p.mass, p.angle, p.mu_s, p.mu_k, p.g]
		"projectile": return "u = %.2f m s⁻¹; θ = %.2f°; g = %.2f m s⁻²; launch y = %.2f m; receiver y = %.2f m. No drag." % [p.speed, p.angle, p.g, p.launch_y, p.target_y]
		"momentum": return "m = %.2f kg; J = +10 N s; initial velocity = 0. Other impulses during delivery negligible." % p.mass
		"energy": return "m = %.2f kg; h = %.2f m; g = %.2f m s⁻²; λ = %.2f; released from rest. Upward guide resistance λmg." % [p.mass, p.height, p.g, p.loss]
	return ""


func submit_scholar() -> void:
	var result: Dictionary = ScholarChallenges.check_answer(challenge, answer.text)
	scholar_feedback.text = result.feedback
	if result.correct and challenge.id not in lab.progress.scholar_completed:
		lab.progress.scholar_completed.append(challenge.id)
		host._persist("Optional archive seal saved. Story progression is unchanged.")


func _open(next_mode: String) -> void:
	if mode.is_empty():
		previous_paused = get_tree().paused
	if is_instance_valid(selected): selected.inspected = false
	mode = next_mode
	get_tree().paused = true
	host.pause_layer.visible = false
	host.touch.visible = false
	Controls.release_virtual()
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	trajectory_map = null
	panel.visible = true
	scroll.scroll_vertical = 0
	overlay.snapshot = {}
	overlay.queue_redraw()
	hint_panel.visible = false
	if next_mode in ["sight", "apparatus"] and is_instance_valid(selected):
		lab.observe_camera.enabled = true
		host.room.player.get_node("Camera2D").enabled = false
		lab.observe_camera.global_position = selected.payload.global_position + Vector2(70, -50)
		lab.observe_camera.force_update_scroll()


func close() -> void:
	if mode.is_empty(): return
	if is_instance_valid(selected): selected.inspected = false
	mode = ""
	panel.hide()
	overlay.snapshot = {}
	overlay.queue_redraw()
	lab.observe_camera.enabled = false
	host.room.player.get_node("Camera2D").enabled = true
	host.set_paused(previous_paused)
	Controls.release_virtual()


func _title(title: String, subtitle: String) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var heading := GameTheme.title(title, 22)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	var dismiss := Button.new()
	dismiss.name = "Dismiss"
	dismiss.text = "×"
	dismiss.custom_minimum_size = Vector2(44, 44)
	dismiss.pressed.connect(close)
	row.add_child(dismiss)
	_label(subtitle, 17)


func _label(text: String, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	column.add_child(label)
	return label


func _rich(text: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = text
	label.add_theme_font_size_override("normal_font_size", 18)
	column.add_child(label)
	return label


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	column.add_child(button)
	return button
