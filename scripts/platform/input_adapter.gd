class_name InputAdapter
extends Node
## Unified keyboard / controller / multitouch state. Virtual sources are separate
## from Input.action_press, so touch release cannot cancel a physical held key.

signal bindings_changed
const ACTIONS: Array[String] = ["move_left", "move_right", "jump", "interact", "scan", "pause", "restart"]
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
	}
	var buttons: Dictionary = {
		"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT,
		"jump": JOY_BUTTON_A, "interact": JOY_BUTTON_X, "scan": JOY_BUTTON_LEFT_SHOULDER,
		"pause": JOY_BUTTON_START, "restart": JOY_BUTTON_BACK,
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
	for action in ACTIONS:
		var keys: Variant = bindings.get(action)
		if not keys is Array or keys.is_empty():
			continue
		var valid: bool = true
		for key in keys:
			if not (key is int or key is float) or key <= 0:
				valid = false
		if not valid:
			continue
		rebind_key(action, int(keys[0]))
		for index in range(1, keys.size()):
			var event := InputEventKey.new()
			event.physical_keycode = int(keys[index])
			InputMap.action_add_event(action, event)
	bindings_changed.emit()


func _virtual_held(action: String) -> bool:
	return not virtual_sources.get(action, {}).is_empty()
