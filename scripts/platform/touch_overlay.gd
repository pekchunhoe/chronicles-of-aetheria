extends Control
@onready var stick: Control = $Stick
@onready var actions: Control = $Actions
var control_scale: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(layout_controls)
	layout_controls()


func configure(scale_value: float, opacity: float) -> void:
	control_scale = clampf(scale_value, 0.75, 1.25)
	modulate.a = clampf(opacity, 0.3, 1.0)
	if is_node_ready():
		layout_controls()


func layout_controls() -> void:
	stick.scale = Vector2.ONE * control_scale
	actions.scale = Vector2.ONE * control_scale
	stick.position = Vector2(0, size.y - stick.size.y * control_scale)
	actions.position = Vector2(size.x - actions.size.x * control_scale, size.y - actions.size.y * control_scale)
