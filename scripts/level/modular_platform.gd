class_name ModularPlatform
extends StaticBody2D
@export var dimensions: Vector2 = Vector2(128, 16)
@export var accent: Color = Color("899caa")


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	collider.shape = rectangle
	collider.position = dimensions * 0.5
	add_child(collider)
	queue_redraw()


func _draw() -> void:
	ArtLibrary.draw_platform(self, dimensions, dimensions.y < 32)
