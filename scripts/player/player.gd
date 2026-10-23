class_name FoundationPlayer
extends CharacterBody2D
## Arcade movement in pixels/second, intentionally separate from graded SI models.

signal fell
@export var run_speed_px_per_s: float = 170.0
@export var jump_speed_px_per_s: float = 360.0
@export var gravity_px_per_s2: float = 1000.0
const COYOTE_SECONDS: float = 0.10
const BUFFER_SECONDS: float = 0.12
var coyote_left: float = 0.0
var buffer_left: float = 0.0
var facing: float = 1.0


func _physics_process(delta: float) -> void:
	coyote_left = COYOTE_SECONDS if is_on_floor() else maxf(0, coyote_left - delta)
	buffer_left = maxf(0, buffer_left - delta)
	if Controls.consume_press("jump"):
		buffer_left = BUFFER_SECONDS
	var axis: float = Controls.movement_axis()
	velocity.x = move_toward(velocity.x, axis * run_speed_px_per_s, 1400.0 * delta)
	if not is_zero_approx(axis):
		facing = signf(axis)
	if buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = -jump_speed_px_per_s
		buffer_left = 0.0
		coyote_left = 0.0
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity_px_per_s2 * delta, 650.0)
	if velocity.y < -120.0 and not Controls.held("jump"):
		velocity.y = -120.0
	move_and_slide()
	position.x = clampf(position.x, 10.0, 1142.0)
	if position.y > 440.0:
		fell.emit()
	queue_redraw()


func reset_to(point: Vector2) -> void:
	position = point
	velocity = Vector2.ZERO
	coyote_left = 0.0
	buffer_left = 0.0
	reset_physics_interpolation()
	$Camera2D.reset_smoothing()


func _draw() -> void:
	draw_rect(Rect2(-9, -14, 18, 28), Color("c4a679"))
	draw_rect(Rect2(-7, -12, 14, 8), Color("edf3ed"))
	draw_rect(Rect2(2 * facing, -10, 3, 3), Color("1b2d40"))
	draw_rect(Rect2(-10, 0, 20, 4), Color("427b87"))
	draw_rect(Rect2(7 * facing - 2, -2, 4, 5), Color("8cddc2"))
