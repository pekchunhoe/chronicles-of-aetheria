class_name GameTheme
extends RefCounted
## Restrained iron, brass and jade; UI text stays at full display resolution.
const SCIENTIFIC_FALLBACK: FontFile = preload("res://assets/fonts/DejaVuSans.ttf")
static var _body_font: Font


static func body_font() -> Font:
	if _body_font == null:
		var wrapped := FontVariation.new()
		wrapped.base_font = ThemeDB.fallback_font
		wrapped.fallbacks = [SCIENTIFIC_FALLBACK]
		_body_font = wrapped
	return _body_font


static func panel(color: Color = Color("101c25"), border: Color = Color("80704e")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func create() -> Theme:
	var result := Theme.new()
	result.default_font = body_font()
	result.set_font("normal_font", "RichTextLabel", body_font())
	result.default_font_size = 20
	result.set_color("font_color", "Label", Color("e4dfcd"))
	result.set_color("font_shadow_color", "Label", Color("080e15"))
	result.set_constant("shadow_offset_y", "Label", 1)
	result.set_stylebox("panel", "PanelContainer", panel(Color(0.043, 0.071, 0.098, 0.94)))
	for type_name in ["Button", "CheckButton", "OptionButton"]:
		result.set_stylebox("normal", type_name, panel())
		result.set_stylebox("hover", type_name, panel(Color("203739"), Color("c3a56b")))
		result.set_stylebox("pressed", type_name, panel(Color("324a43"), Color("9fddc4")))
		result.set_stylebox("disabled", type_name, panel(Color("151c22"), Color("38434a")))
		var focus := panel(Color(0, 0, 0, 0), Color("a9e7cc"))
		focus.set_border_width_all(2)
		result.set_stylebox("focus", type_name, focus)
		result.set_color("font_color", type_name, Color("e4dfcd"))
		result.set_color("font_hover_color", type_name, Color("fff0c9"))
	return result


static func title(text: String, size: int = 24) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ArtLibrary.TITLE_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("d3b77d"))
	return label


static func icon(index: int, size: float = 28.0) -> TextureRect:
	var result := TextureRect.new()
	result.texture = ArtLibrary.texture("world", index)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.custom_minimum_size = Vector2(size, size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
