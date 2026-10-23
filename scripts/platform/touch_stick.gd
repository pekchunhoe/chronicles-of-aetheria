extends Control
## Horizontal virtual stick; tracks one finger without stealing jump touches.
var finger: int = -1
var displacement: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_release)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			finger = event.index
			_update_axis(event.position)
		elif not event.pressed and event.index == finger:
			_release()
	elif event is InputEventScreenDrag and event.index == finger:
		_update_axis(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release()


func _update_axis(point: Vector2) -> void:
	var radius: float = get_global_rect().size.x * 0.35
	var raw: float = clampf((point.x - get_global_rect().get_center().x) / radius, -1.0, 1.0)
	displacement = 0.0 if absf(raw) < 0.18 else signf(raw) * (absf(raw) - 0.18) / 0.82
	Controls.set_virtual_axis(str(get_instance_id()), displacement)
	queue_redraw()


func _release() -> void:
	finger = -1
	displacement = 0.0
	Controls.set_virtual_axis(str(get_instance_id()), 0.0)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, size.x * 0.48, Color("182c40"))
	draw_arc(center, size.x * 0.48, 0, TAU, 48, Color("7cb9c4"), 2)
	draw_circle(center + Vector2(displacement * size.x * 0.30, 0), size.x * 0.20, Color("7cb9c4"))
