extends Control
## A finger-owned control. ScreenTouch avoids mouse emulation and supports chords.
@export var action: String = "jump"
@export var caption: String = "JUMP"
var finger: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_release)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			finger = event.index
			Controls.set_virtual_action(action, str(get_instance_id()), true)
			queue_redraw()
		elif not event.pressed and event.index == finger:
			_release()
	elif event is InputEventScreenDrag and event.index == finger:
		if not get_global_rect().has_point(event.position):
			_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release()


func _release() -> void:
	if finger >= 0:
		Controls.set_virtual_action(action, str(get_instance_id()), false)
	finger = -1
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_style(), rect)
	var icons: Dictionary = {"light_attack": 50, "heavy_attack": 51, "dodge": 52, "jump": 48, "scan": 54, "interact": 53, "pause": 55}
	var extent: float = minf(size.x, size.y) * 0.38
	draw_texture_rect(ArtLibrary.texture("world", icons.get(action, 48)), Rect2((size.x - extent) * 0.5, size.y * 0.12, extent, extent), false)
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(font, Vector2((size.x - text_size.x) * 0.5, size.y * 0.80), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("eee2c3"))


func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("34534a") if finger >= 0 else Color("101c25")
	style.border_color = Color("a0d9bf") if finger >= 0 else Color("a68d5d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
