class_name ModularPlatform
extends StaticBody2D
@export var dimensions: Vector2 = Vector2(128, 16)
@export var accent: Color = Color("899caa")


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	collider.shape = rectangle
	collider.position = dimensions * 0.5
	add_child(collider)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, dimensions), Color("394c5c"))
	draw_rect(Rect2(0, 0, dimensions.x, 3), accent)
	for x in range(8, int(dimensions.x), 32):
		draw_rect(Rect2(x, 7, 3, 3), Color("617786"))
