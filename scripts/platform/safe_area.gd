class_name SafeAreaLayout
extends MarginContainer
## Insets in the UI canvas coordinate space, including window stretch/letterbox.

const BASE_MARGIN: int = 24


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(update_insets)
	update_insets()


func update_insets() -> void:
	var insets := Vector4.ZERO
	if OS.has_feature("android") or OS.has_feature("ios"):
		var screen_safe := Rect2(DisplayServer.get_display_safe_area())
		var window_rect := Rect2(Vector2(DisplayServer.window_get_position()), Vector2(DisplayServer.window_get_size()))
		var safe_in_window: Rect2 = screen_safe.intersection(window_rect)
		if safe_in_window.has_area():
			var inverse: Transform2D = get_viewport().get_screen_transform().affine_inverse()
			var safe_canvas: Rect2 = inverse * Rect2(safe_in_window.position - window_rect.position, safe_in_window.size)
			insets = calculate_insets(Rect2(Vector2.ZERO, get_viewport_rect().size), safe_canvas)
	add_theme_constant_override("margin_left", BASE_MARGIN + ceili(insets.x))
	add_theme_constant_override("margin_top", BASE_MARGIN + ceili(insets.y))
	add_theme_constant_override("margin_right", BASE_MARGIN + ceili(insets.z))
	add_theme_constant_override("margin_bottom", BASE_MARGIN + ceili(insets.w))


static func calculate_insets(canvas: Rect2, safe: Rect2) -> Vector4:
	var intersection: Rect2 = canvas.intersection(safe)
	if not intersection.has_area():
		return Vector4.ZERO
	return Vector4(maxf(0.0, intersection.position.x - canvas.position.x),
		maxf(0.0, intersection.position.y - canvas.position.y),
		maxf(0.0, canvas.end.x - intersection.end.x), maxf(0.0, canvas.end.y - intersection.end.y))
