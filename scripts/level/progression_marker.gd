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
	var visual := MarkerPresentation.new()
	visual.kind = kind
	add_child(visual)
	body_entered.connect(func(body: Node2D):
		if body.is_in_group("player") and body.health.current > 0:
			activated.emit(self)
	)


func set_active(value: bool) -> void:
	if value and not active and kind == Kind.RELIC:
		ImpactBurst.spawn(self, 0, Color("ceacfa"))
	active = value
	visible = not (kind == Kind.RELIC and value)
	queue_redraw()
