class_name SecurityProjectile
extends CharacterBody2D
## Swept circle collision prevents tunnelling. First impact always consumes the bolt.
@export var speed: float = 210.0
@export var lifetime: float = 2.7
@export var damage: int = 16
@export var knockback: float = 180.0
var direction: Vector2 = Vector2.LEFT
var age: float = 0.0
var consumed: bool = false


func _ready() -> void:
	add_to_group("projectiles")
	collision_layer = 16
	collision_mask = 3
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	collider.shape = circle
	add_child(collider)


func _physics_process(delta: float) -> void:
	if consumed:
		return
	age += delta
	if age >= lifetime:
		_dispose()
		return
	var collision: KinematicCollision2D = move_and_collide(direction.normalized() * speed * delta)
	if collision != null:
		var body: Object = collision.get_collider()
		if body.has_method("receive_hit"):
			body.receive_hit(damage, global_position - direction * 8.0, knockback)
		_dispose()


func _dispose() -> void:
	consumed = true
	hide()
	queue_free()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, direction.angle())
	draw_texture_rect(ArtLibrary.texture("machines", 56), Rect2(-13, -4, 20, 8), false)
	draw_rect(Rect2(-2, -2, 4, 4), Color("ffe6aa"))
	draw_set_transform(Vector2.ZERO)
