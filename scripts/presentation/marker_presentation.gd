class_name MarkerPresentation
extends Node2D
## Decorative only: existing Area2D and persistence own all interaction rules.
@export var kind: int = 0
var active: bool = false
var age: float = 0.0
var activation_left: float = 0.0
var previous_active: bool = false


func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	age += delta
	activation_left = maxf(0.0, activation_left - delta)
	if get_parent() is ProgressionMarker:
		active = get_parent().active
	if active and not previous_active:
		activation_left = 0.45
	previous_active = active
	queue_redraw()


func _draw() -> void:
	var motion: float = 0.0 if Visuals.reduced_motion else sin(age * 2.4)
	match kind:
		0:
			var frame: int = 32 if not active else 33 + int(age * 5) % 3
			ArtLibrary.prop(self, frame, Rect2(-17, -28, 34, 56))
			if active:
				draw_arc(Vector2(0, -9), 13 + motion, -2.8, 0.8, 16, Color(0.4, 0.92, 0.84, 0.5), 1)
		1:
			var frame: int = 36 + int(age * 6) % 4
			ArtLibrary.prop(self, frame, Rect2(-8, -13 + roundf(motion * 2), 16, 26))
			for index in range(3):
				var angle: float = float(index) * TAU / 3 + (0 if Visuals.reduced_motion else age * 0.5)
				draw_circle(Vector2.from_angle(angle) * 14, 0.7, Color("bca4ef"))
		2:
			ArtLibrary.prop(self, 41, Rect2(-28, -47, 56, 75))
			draw_string(ThemeDB.fallback_font, Vector2(-13, -51), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b8d9cd"))
	if activation_left > 0 and not Visuals.reduced_motion:
		var progress: float = 1.0 - activation_left / 0.45
		draw_arc(Vector2(0, 16), 9 + progress * 24, PI, TAU, 20, Color(0.5, 1, 0.85, 1 - progress), 1)
