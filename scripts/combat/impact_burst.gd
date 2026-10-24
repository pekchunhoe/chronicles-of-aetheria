class_name ImpactBurst
extends Node2D
## Bounded sparks and raster impact accents. Numbers only follow accepted damage.
var age: float = 0.0
var amount: int = 0
var tint: Color = Color("ffd087")


static func spawn(actor: Node2D, damage: int, color: Color = Color("ffd087")) -> void:
	var burst := ImpactBurst.new()
	burst.position = actor.position
	burst.amount = damage
	burst.tint = color
	burst.z_index = 5
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.get_parent().add_child(burst)


func _process(delta: float) -> void:
	age += delta
	if age >= 0.45:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var fade := Color(tint, 1.0 - age / 0.45)
	var count: int = [3, 7, 10][Visuals.quality]
	for index in range(count):
		var direction := Vector2.from_angle(float(index) * TAU / count)
		var point: Vector2 = direction * (5.0 + age * 65.0)
		draw_rect(Rect2(point.round(), Vector2(2, 1)), fade)
	if amount > 0 and age < 0.15:
		var width: float = 30 if amount >= 25 else 20
		draw_texture_rect(ArtLibrary.texture("world", 59), Rect2(-width * 0.5, -width * 0.5, width, width), false, Color(tint, 1.0 - age / 0.15))
	if amount > 0:
		var point := Vector2(-8, -22 - age * 38).round()
		draw_string_outline(ThemeDB.fallback_font, point, str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0.03, 0.05, 0.07, fade.a))
		draw_string(ThemeDB.fallback_font, point, str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, fade)
