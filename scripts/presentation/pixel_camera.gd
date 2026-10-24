extends Camera2D
## Smooth presentation with whole-world-pixel camera transforms; no actor mutation.
var tracked: Vector2
var trauma: float = 0.0
var age: float = 0.0


func _ready() -> void:
	position_smoothing_enabled = false
	tracked = get_parent().global_position
	set_as_top_level(true)
	global_position = tracked.round()
	process_priority = 100
	get_parent().presentation_reset.connect(_reset_tracking)
	Visuals.impact_requested.connect(func(amount: float): trauma = maxf(trauma, amount))


func _reset_tracking() -> void:
	tracked = get_parent().global_position
	global_position = tracked.round()
	trauma = 0.0
	offset = Vector2.ZERO


func _process(delta: float) -> void:
	age += delta
	var point: Vector2 = get_parent().global_position
	if tracked.distance_to(point) > 120:
		tracked = point
	tracked = tracked.lerp(point, 1.0 - exp(-10.0 * delta))
	global_position = tracked.round()
	trauma = move_toward(trauma, 0.0, delta * 9.0)
	offset = Vector2.ZERO if Visuals.reduced_motion else (Vector2(sin(age * 79), cos(age * 57)) * trauma).round()
