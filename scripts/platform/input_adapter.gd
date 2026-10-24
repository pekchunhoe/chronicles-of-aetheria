class_name InputAdapter
extends Node
## Unified keyboard / controller / multitouch state. Virtual sources are separate
## from Input.action_press, so touch release cannot cancel a physical held key.

signal bindings_changed
const ACTIONS: Array[String] = ["move_left", "move_right", "jump", "interact", "scan", "pause", "restart", "light_attack", "heavy_attack", "dodge", "impulse_strike", "codex"]
var virtual_sources: Dictionary = {}
var axis_sources: Dictionary = {}
var pending_presses: Dictionary = {}
var jump_is_held: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	install_defaults()


func install_defaults() -> void:
	var keys: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "interact": [KEY_E], "scan": [KEY_Q],
		"pause": [KEY_ESCAPE], "restart": [KEY_R],
		"light_attack": [KEY_J], "heavy_attack": [KEY_K], "dodge": [KEY_SHIFT],
		"impulse_strike": [KEY_F], "codex": [KEY_TAB],
	}
	var buttons: Dictionary = {
		"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT,
		"jump": JOY_BUTTON_A, "interact": JOY_BUTTON_RIGHT_SHOULDER, "scan": JOY_BUTTON_LEFT_SHOULDER,
		"pause": JOY_BUTTON_START, "restart": JOY_BUTTON_BACK,
		"light_attack": JOY_BUTTON_X, "heavy_attack": JOY_BUTTON_Y, "dodge": JOY_BUTTON_B,
		"impulse_strike": JOY_BUTTON_LEFT_STICK, "codex": JOY_BUTTON_RIGHT_STICK,
	}
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		InputMap.action_erase_events(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = buttons[action]
		InputMap.action_add_event(action, button)
	for direction in [-1, 1]:
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = JOY_AXIS_LEFT_X
		motion.axis_value = direction
		InputMap.action_add_event("move_left" if direction < 0 else "move_right", motion)
	bindings_changed.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	for action in ACTIONS:
		if event.is_action_pressed(action):
			pending_presses[action] = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_virtual()


func movement_axis() -> float:
	var physical: float = Input.get_axis("move_left", "move_right")
	var touch: float = 0.0
	for value in axis_sources.values():
		touch += float(value)
	touch += float(_virtual_held("move_right")) - float(_virtual_held("move_left"))
	return clampf(physical + touch, -1.0, 1.0)


func held(action: String) -> bool:
	return Input.is_action_pressed(action) or _virtual_held(action)


func consume_press(action: String) -> bool:
	return bool(pending_presses.erase(action))


func set_virtual_action(action: String, source: String, pressed: bool) -> void:
	if action not in ACTIONS:
		return
	if not virtual_sources.has(action):
		virtual_sources[action] = {}
	var sources: Dictionary = virtual_sources[action]
	if pressed:
		if not held(action):
			pending_presses[action] = true
		sources[source] = true
	else:
		sources.erase(source)


func set_virtual_axis(source: String, value: float) -> void:
	axis_sources[source] = clampf(value, -1.0, 1.0)


func release_virtual() -> void:
	virtual_sources.clear()
	axis_sources.clear()
	pending_presses.clear()


func rebind_key(action: String, physical_keycode: int) -> bool:
	if action not in ACTIONS or physical_keycode <= 0:
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var replacement := InputEventKey.new()
	replacement.physical_keycode = physical_keycode
	InputMap.action_add_event(action, replacement)
	release_virtual()
	bindings_changed.emit()
	return true


func binding_label(action: String) -> String:
	var labels: PackedStringArray = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			labels.append(OS.get_keycode_string(event.physical_keycode))
	return " / ".join(labels)


func export_key_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for action in ACTIONS:
		var keys: Array[int] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(event.physical_keycode)
		bindings[action] = keys
	return bindings


func import_key_bindings(bindings: Dictionary) -> void:
	# Saved Phase 0 bindings have priority over the three newly introduced defaults.
	# For example, an old Jump=J save keeps J and gets a free key for Light attack.
	var reserved: Dictionary = {}
	for action in ACTIONS:
		var saved: Variant = bindings.get(action, [])
		if saved is Array:
			for key in saved:
				if (key is int or key is float) and is_finite(float(key)) and key > 0:
					reserved[int(key)] = true
	var defaults: Dictionary = export_key_bindings()
	var used: Dictionary = {}
	for action in ACTIONS:
		var keys: Array[int] = []
		var saved: Variant = bindings.get(action, [])
		if saved is Array:
			for key in saved:
				if (key is int or key is float) and is_finite(float(key)) and key > 0 and not used.has(int(key)):
					keys.append(int(key))
					used[int(key)] = true
		if keys.is_empty():
			for key in defaults[action]:
				if not used.has(key) and not reserved.has(key):
					keys.append(key)
					used[key] = true
		if keys.is_empty():
			for key in [KEY_F, KEY_G, KEY_H, KEY_L, KEY_U, KEY_I, KEY_O, KEY_P, KEY_B, KEY_N, KEY_M, KEY_T, KEY_Y, KEY_C, KEY_V, KEY_Z, KEY_X]:
				if not used.has(key) and not reserved.has(key):
					keys.append(key)
					used[key] = true
					break
		if keys.is_empty():
			continue
		rebind_key(action, keys[0])
		for index in range(1, keys.size()):
			var event := InputEventKey.new()
			event.physical_keycode = keys[index]
			InputMap.action_add_event(action, event)
	bindings_changed.emit()


func _virtual_held(action: String) -> bool:
	return not virtual_sources.get(action, {}).is_empty()


func rebind_controller(action: String, button_index: int) -> bool:
	if action not in ACTIONS or button_index < 0 or button_index >= JOY_BUTTON_MAX:
		return false
	for other in ACTIONS:
		if other == action: continue
		for event in InputMap.action_get_events(other):
			if event is InputEventJoypadButton and event.button_index == button_index:
				return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button_index
	InputMap.action_add_event(action, event)
	release_virtual()
	bindings_changed.emit()
	return true


func export_controller_bindings() -> Dictionary:
	var data: Dictionary = {}
	for action in ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton:
				data[action] = event.button_index
	return data


func import_controller_bindings(data: Variant) -> void:
	if not data is Dictionary: return
	var defaults: Dictionary = export_controller_bindings()
	var chosen: Dictionary = {}
	var used: Array[int] = []
	for action in ACTIONS:
		var button: Variant = data.get(action)
		if (button is int or button is float) and is_finite(float(button)) and int(button) >= 0 and int(button) < JOY_BUTTON_MAX and int(button) not in used:
			chosen[action] = int(button)
			used.append(int(button))
	for action in ACTIONS:
		if not chosen.has(action):
			var button: int = defaults[action]
			if button in used:
				for candidate in range(JOY_BUTTON_MAX):
					if candidate not in used:
						button = candidate
						break
			chosen[action] = button
			used.append(button)
	for action in ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton:
				InputMap.action_erase_event(action, event)
	for action in ACTIONS:
		rebind_controller(action, chosen[action])
