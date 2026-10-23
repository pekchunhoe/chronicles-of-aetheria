class_name ImpactBurst
extends Node2D
## Bounded, short-lived original shape particles and a damage number.
var age: float = 0.0
var amount: int = 0
var tint: Color = Color("ffd087")


static func spawn(actor: Node2D, damage: int, color: Color = Color("ffd087")) -> void:
	var burst := ImpactBurst.new()
	burst.position = actor.position
	burst.amount = damage
	burst.tint = color
	actor.get_parent().add_child(burst)


func _process(delta: float) -> void:
	age += delta
	if age >= 0.45:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var fade := Color(tint, 1.0 - age / 0.45)
	for index in range(7):
		var direction := Vector2.from_angle(float(index) * TAU / 7.0)
		var point: Vector2 = direction * (5.0 + age * 65.0)
		draw_line(point, point + direction * 4.0, fade, 2.0)
	if amount > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -22 - age * 38), str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fade)
