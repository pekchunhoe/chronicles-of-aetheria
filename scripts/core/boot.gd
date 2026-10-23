extends Control

const Saves = preload("res://scripts/core/save_repository.gd")
const Concepts = preload("res://scripts/curriculum/concept_repository.gd")
const Puzzle = preload("res://scripts/puzzle_runtime/puzzle_controller.gd")
const Scanner = preload("res://scripts/player/gauntlet_scanner.gd")
const TouchScene = preload("res://scenes/ui/touch_overlay.tscn")
const WebSupport = preload("res://scripts/platform/web_platform_support.gd")
var saves: SaveRepository
var concepts := Concepts.new()
var puzzle := Puzzle.new()
var scanner := Scanner.new()
var save_data: Dictionary = {}
var touch: Control
var status: Label
var help_text: Label
var bench: PanelContainer
var bench_text: Label
var pause_layer: ColorRect
var remap_action: String = ""
var remap_buttons: Dictionary = {}
var menu_status: Label
var touch_toggle: CheckButton
var status_message: String = ""
var save_writable: bool = true
var pause_panel: PanelContainer
var pause_scroll: ScrollContainer
var health_bar: ProgressBar
var health_label: Label
var combat_label: Label
var feedback_label: Label
var hud_left: float = 0.0
var completion_notice_left: float = 0.0
var validation_mode: bool = false
@onready var room: Node2D = $WorldViewport/GrayboxRoom


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().title = "Chronicles of Aetheria — The Broken Laws"
	if WebSupport.is_touch_device():
		get_window().content_scale_size = Vector2i(960, 540)
	# Integration tests override storage, so they cannot touch a player's real save.
	var save_path: String = str(get_meta("save_path", "user://save_v1.json"))
	var smoke_mode: bool = "--foundation-smoke" in OS.get_cmdline_user_args() and OS.is_debug_build()
	validation_mode = smoke_mode
	if smoke_mode:
		save_path = OS.get_environment("AETHERIA_SMOKE_SAVE_PATH")
		if not save_path.is_absolute_path() or FileAccess.file_exists(save_path):
			printerr("FAIL: standalone smoke requires a new absolute isolated save path.")
			get_tree().quit(1)
			return
	saves = Saves.new(save_path)
	save_data = saves.load_save()
	if save_data.is_empty():
		save_data = saves.defaults()
		save_writable = false
		status_message = saves.last_error
	room.set_checkpoint(save_data.checkpoint_id)
	room.restore_progress(save_data)
	room.respawn()
	room.checkpoint_reached.connect(_checkpoint_reached)
	room.progression_changed.connect(_persist)
	room.sector_completed.connect(_sector_completed)
	var preferences: Dictionary = save_data.control_preferences
	var bindings: Variant = preferences.get("bindings", {})
	if bindings is Dictionary:
		Controls.import_key_bindings(bindings)
	var loaded: bool = concepts.load_content()
	var puzzle_loaded: bool = puzzle.load_definition("res://content/puzzles/projectile_bench.json")
	if puzzle_loaded:
		var saved_puzzle: Variant = save_data.puzzle_state.get(puzzle.definition.puzzle_id, {})
		if saved_puzzle is Dictionary:
			puzzle.solved = bool(saved_puzzle.get("solved", false))
	if not loaded or not puzzle_loaded:
		status_message = "Content validation failed. Check local content files."
	_build_ui()
	room.player.health.changed.connect(_health_changed)
	_health_changed(room.player.health.current, room.player.health.maximum)
	var web_support := WebSupport.new()
	web_support.pause_requested.connect(_on_web_pause)
	add_child(web_support)
	Controls.bindings_changed.connect(_refresh_bindings)
	_refresh_bindings()
	if status_message.is_empty():
		status_message = "Reach the relay, explore the upper passage, then find the east exit."
	_refresh_status()
	# The game subtree remains pausable even though UI/lifecycle code always runs.
	$WorldViewport.process_mode = Node.PROCESS_MODE_PAUSABLE
	if smoke_mode:
		call_deferred("_run_standalone_smoke")


func _run_standalone_smoke() -> void:
	for frame in range(5):
		await get_tree().physics_frame
		await get_tree().process_frame
	var valid: bool = not OS.has_feature("editor") and not FileAccess.file_exists("res://tests/run_unit_tests.gd")
	valid = valid and not puzzle.definition.is_empty() and not concepts.concepts.is_empty() and concepts.errors.is_empty()
	valid = valid and room.player.is_on_floor() and $WorldViewport.size == Vector2i(640, 360)
	if valid:
		_run_sample()
		valid = puzzle.solved and saves.load_save().discoveries.size() == 1
	if valid:
		valid = await load("res://scripts/core/packaged_smoke.gd").new().run(self)
	print("EXPORT SMOKE PASS: standalone pack, JSON content, scene, collision, SI puzzle, and isolated save" if valid else "FAIL: packaged foundation validation")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(saves.path + suffix):
			DirAccess.remove_absolute(saves.path + suffix)
	get_tree().quit(0 if valid else 1)


func _process(delta: float) -> void:
	if Controls.consume_press("pause"):
		set_paused(not get_tree().paused)
	if get_tree().paused:
		return
	hud_left -= delta
	completion_notice_left = maxf(0.0, completion_notice_left - delta)
	if hud_left <= 0.0:
		_refresh_combat_hud()
		hud_left = 0.08
	if Controls.consume_press("restart") and room.player.health.current > 0:
		room.respawn()
	if Controls.consume_press("interact"):
		_persist("Progress saved at " + str(save_data.checkpoint_id).replace("_", " ") + ".")
	if Controls.consume_press("scan"):
		_toggle_bench()


func _input(event: InputEvent) -> void:
	if remap_action.is_empty() or not event is InputEventKey or not event.pressed or event.echo:
		return
	var selected: String = remap_action
	remap_action = ""
	# Reject duplicate binds to keep pause and movement reachable.
	for action in Controls.ACTIONS:
		if action == selected:
			continue
		for binding in InputMap.action_get_events(action):
			if binding is InputEventKey and binding.physical_keycode == event.physical_keycode:
				menu_status.text = "That key is already bound to " + action + ". Choose another key."
				get_viewport().set_input_as_handled()
				Controls.release_virtual()
				return
	Controls.rebind_key(selected, event.physical_keycode)
	_persist("Control bindings saved.")
	menu_status.text = "Binding saved."
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	# Hidden debug export checks cannot acquire focus; lifecycle tests use normal mode.
	if validation_mode and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		set_paused(true)
		_persist("Paused and saved locally.")
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		set_paused(true)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_persist("Progress saved.")
		get_tree().quit()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	pause_layer.visible = paused
	touch.visible = not paused and _touch_enabled()
	Controls.release_virtual()
	remap_action = ""
	if paused:
		menu_status.text = "Paused. Select a control to rebind it."
		pause_layer.get_node("Center/Panel/Scroll/Contents/Resume").grab_focus()


func _on_web_pause() -> void:
	set_paused(true)
	_persist("Paused and saved in this browser.")


func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 22
	for type_name in ["PanelContainer", "Button", "CheckButton"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("132437")
		style.border_color = Color("456579")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		ui_theme.set_stylebox("panel" if type_name == "PanelContainer" else "normal", type_name, style)
		if type_name == "Button":
			var focus: StyleBoxFlat = style.duplicate()
			focus.border_color = Color("9fdfc3")
			focus.set_border_width_all(3)
			ui_theme.set_stylebox("focus", "Button", focus)
	theme = ui_theme
	var ui := Control.new()
	ui.name = "UI"
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$SafeArea.add_child(ui)
	touch = TouchScene.instantiate()
	touch.name = "TouchOverlay"
	ui.add_child(touch)
	var preferences: Dictionary = save_data.control_preferences
	touch.configure(float(preferences.get("touch_scale", 1.0)), float(preferences.get("touch_opacity", 0.8)))
	touch.visible = _touch_enabled()
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ui.add_child(top)
	var header := HBoxContainer.new()
	top.add_child(header)
	var title := Label.new()
	title.text = "AETHERIA  /  TRAINING SECTOR"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("9fdfc3"))
	header.add_child(title)
	header.add_child(_button("Bench", _toggle_bench))
	header.add_child(_button("Pause / Controls", func(): set_paused(true)))
	var vitals := HBoxContainer.new()
	vitals.add_theme_constant_override("separation", 14)
	top.add_child(vitals)
	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.custom_minimum_size.x = 124
	vitals.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(170, 18)
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	health_bar.show_percentage = false
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("8ed8b6")
	health_fill.set_corner_radius_all(5)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color("253b49")
	health_background.set_corner_radius_all(5)
	health_bar.add_theme_stylebox_override("background", health_background)
	vitals.add_child(health_bar)
	combat_label = Label.new()
	combat_label.add_theme_font_size_override("font_size", 18)
	vitals.add_child(combat_label)
	help_text = Label.new()
	help_text.add_theme_font_size_override("font_size", 18)
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(help_text)
	bench = PanelContainer.new()
	bench.visible = false
	top.add_child(bench)
	var bench_column := VBoxContainer.new()
	bench.add_child(bench_column)
	bench_text = Label.new()
	bench_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bench_text.add_theme_font_size_override("font_size", 20)
	bench_column.add_child(bench_text)
	bench_column.add_child(_button("Run sample: 14 m/s at 45 degrees", _run_sample))
	status = Label.new()
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_top = -38
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 18)
	ui.add_child(status)
	var center_feedback := CenterContainer.new()
	center_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(center_feedback)
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_color", Color("d6f7e8"))
	feedback_label.add_theme_color_override("font_shadow_color", Color("101c2b"))
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 2)
	center_feedback.add_child(feedback_label)
	_build_pause(ui)
	ui.resized.connect(_refresh_status)
	ui.resized.connect(_resize_pause_menu)
	_resize_pause_menu()


func _build_pause(parent: Control) -> void:
	pause_layer = ColorRect.new()
	pause_layer.name = "PauseLayer"
	pause_layer.color = Color(0.02, 0.04, 0.07, 0.96)
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(pause_layer)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)
	var panel := PanelContainer.new()
	pause_panel = panel
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	pause_scroll = scroll
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(0, 550)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var contents := VBoxContainer.new()
	contents.name = "Contents"
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 8)
	scroll.add_child(contents)
	var resume := _button("Resume", func(): set_paused(false))
	resume.name = "Resume"
	contents.add_child(resume)
	contents.add_child(_button("Return to active checkpoint", func():
		room.respawn()
		set_paused(false)
	))
	menu_status = Label.new()
	menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(menu_status)
	for action in Controls.ACTIONS:
		var button := _button("", _request_remap.bind(action))
		contents.add_child(button)
		remap_buttons[action] = button
	contents.add_child(_button("Reset keyboard / controller defaults", _reset_bindings))
	touch_toggle = CheckButton.new()
	touch_toggle.text = "Show touch controls on desktop"
	touch_toggle.button_pressed = bool(save_data.control_preferences.get("touch_visible", false))
	touch_toggle.toggled.connect(_touch_toggled)
	contents.add_child(touch_toggle)
	_add_slider(contents, "Touch size", 0.75, 1.25, float(save_data.control_preferences.get("touch_scale", 1.0)), "touch_scale")
	_add_slider(contents, "Touch opacity", 0.3, 1.0, float(save_data.control_preferences.get("touch_opacity", 0.8)), "touch_opacity")
	contents.add_child(_button("Save progress" if OS.has_feature("web") else "Save and quit", _save_and_quit))
	pause_layer.visible = false


func _add_slider(parent: VBoxContainer, caption: String, low: float, high: float, initial: float, key: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 42
	slider.value_changed.connect(func(value: float):
		save_data.control_preferences[key] = value
		touch.configure(float(save_data.control_preferences.get("touch_scale", 1.0)), float(save_data.control_preferences.get("touch_opacity", 0.8)))
		_persist("Touch settings saved.")
	)
	row.add_child(slider)


func _button(caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	button.pressed.connect(callback)
	return button


func _request_remap(action: String) -> void:
	remap_action = action
	menu_status.text = "Press a new key for " + action + "."
	Controls.release_virtual()


func _reset_bindings() -> void:
	Controls.install_defaults()
	_persist("Default controls restored.")


func _touch_enabled() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or WebSupport.is_touch_device() or bool(save_data.control_preferences.get("touch_visible", false))


func _touch_toggled(enabled: bool) -> void:
	save_data.control_preferences["touch_visible"] = enabled
	_persist("Touch preference saved.")
	_refresh_status()


func _toggle_bench() -> void:
	bench.visible = not bench.visible
	if bench.visible:
		bench_text.text = "Numerical model preview only. No launcher apparatus in this prototype.\nSame-height launch, no drag; uniform g = 9.81 m/s^2.\nSemester 1 / illustrative mapping; official syllabus alignment pending."


func _run_sample() -> void:
	if puzzle.definition.is_empty():
		bench_text.text = "Sample definition is invalid."
		return
	var result: Dictionary = puzzle.try_inputs(puzzle.definition.inputs_si)
	bench_text.text = "Inputs: 14.00 m/s, 45.00 degrees\n" + scanner.describe(result)
	if result.get("success", false):
		save_data.puzzle_state[puzzle.definition.puzzle_id] = {"solved": true, "inputs_si": puzzle.definition.inputs_si}
		var concept_id: String = puzzle.definition.concept_id
		if concept_id not in save_data.discoveries:
			save_data.discoveries.append(concept_id)
		_persist("Model bench validated; local discovery saved.")


func _checkpoint_reached(identity: String) -> void:
	save_data.checkpoint_id = identity
	_persist("Checkpoint active. Progress saved locally.")


func _persist(message: String) -> void:
	if not save_writable:
		status_message = "Existing unreadable/newer save preserved; this session cannot overwrite it."
	elif saves.save(_snapshot()) != OK:
		status_message = "Save failed: " + saves.last_error
	else:
		status_message = message
	_refresh_status()


func _snapshot() -> Dictionary:
	save_data.content_version = Saves.CONTENT_VERSION
	room.snapshot_progress(save_data)
	save_data.control_preferences["bindings"] = Controls.export_key_bindings()
	return save_data


func _refresh_bindings() -> void:
	for action in remap_buttons:
		remap_buttons[action].text = action.replace("_", " ").capitalize() + "   :   " + Controls.binding_label(action)
	help_text.text = "Move %s / %s    Jump %s    Light %s    Heavy %s    Dodge %s    Scan %s    Save %s" % [
		Controls.binding_label("move_left"), Controls.binding_label("move_right"), Controls.binding_label("jump"),
		Controls.binding_label("light_attack"), Controls.binding_label("heavy_attack"), Controls.binding_label("dodge"),
		Controls.binding_label("scan"), Controls.binding_label("interact")]


func _health_changed(current: int, maximum: int) -> void:
	health_label.text = "KAEL  %d / %d" % [current, maximum]
	health_bar.max_value = maximum
	health_bar.value = current
	_refresh_combat_hud()


func _refresh_combat_hud() -> void:
	var fighter: FoundationPlayer = room.player
	var weapon: String = fighter.combat.attack.title if fighter.combat.attack != null else "Salvager sword"
	var dodge_status: String = "READY" if fighter.dodge.cooldown_left <= 0.0 else "%.1fs" % fighter.dodge.cooldown_left
	combat_label.text = "%s   |   Dodge %s   |   Shard %d/1" % [weapon, dodge_status, int(room.relic_collected)]
	if fighter.health.current <= 0:
		feedback_label.text = "KAEL HAS FALLEN\nReturning to checkpoint..."
	elif completion_notice_left > 0.0:
		feedback_label.text = "TRAINING SECTOR COMPLETE\nAxiom shard: %d / 1  |  Continue exploring" % int(room.relic_collected)
	else:
		feedback_label.text = ""


func _sector_completed() -> void:
	completion_notice_left = 4.0
	_persist("Training sector complete. Progress saved. You can continue exploring.")
	_refresh_combat_hud()


func _refresh_status() -> void:
	if status == null:
		return
	status.text = status_message
	status.offset_top = -210 if _touch_enabled() else -38
	status.offset_bottom = -172 if _touch_enabled() else 0


func _resize_pause_menu() -> void:
	if pause_panel == null or pause_scroll == null:
		return
	pause_panel.custom_minimum_size.x = minf(760.0, maxf(320.0, get_viewport_rect().size.x - 96.0))
	pause_scroll.custom_minimum_size.y = minf(550.0, maxf(240.0, get_viewport_rect().size.y - 120.0))


func _save_and_quit() -> void:
	_persist("Progress saved.")
	if not OS.has_feature("web"):
		get_tree().quit()
