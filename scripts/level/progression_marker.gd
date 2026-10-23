class_name ProgressionMarker
extends Area2D
signal activated(marker: Area2D)
enum Kind { CHECKPOINT, RELIC, EXIT }
@export var kind: Kind = Kind.CHECKPOINT
@export var identity: String = "checkpoint"
var active: bool = false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 56) if kind != Kind.RELIC else Vector2(24, 28)
	collider.shape = rectangle
	add_child(collider)
	body_entered.connect(func(body: Node2D):
		if body.is_in_group("player") and body.health.current > 0:
			activated.emit(self)
	)


func set_active(value: bool) -> void:
	active = value
	visible = not (kind == Kind.RELIC and value)
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	match kind:
		Kind.CHECKPOINT:
			var color: Color = Color("a7f5cb") if active else Color("5caeae")
			draw_line(Vector2(0, 28), Vector2(0, -26), color, 3)
			draw_polygon(PackedVector2Array([Vector2(2, -24), Vector2(24, -15), Vector2(2, -6)]), PackedColorArray([color]))
			draw_string(font, Vector2(-38, -36), "RELAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		Kind.RELIC:
			draw_polygon(PackedVector2Array([Vector2(0, -12), Vector2(9, 0), Vector2(0, 12), Vector2(-9, 0)]), PackedColorArray([Color("ceb2ff")]))
			draw_string(font, Vector2(-42, -24), "AXIOM SHARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ddcaff"))
		Kind.EXIT:
			draw_rect(Rect2(-23, -36, 46, 64), Color("244d50"))
			draw_rect(Rect2(-18, -31, 36, 59), Color("87dac3"), false, 3)
			draw_string(font, Vector2(-16, -43), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a7f5cb"))
			draw_line(Vector2(-10, -2), Vector2(10, -2), Color("a7f5cb"), 3)
			draw_line(Vector2(10, -2), Vector2(3, -9), Color("a7f5cb"), 3)
