class_name HealthComponent
extends Node
## Shared health contract. Values are gameplay units, never scientific SI models.

signal changed(current: int, maximum: int)
signal damaged(amount: int, origin: Vector2, knockback: float)
signal died
@export var maximum: int = 100
@export var damage_immunity_seconds: float = 0.7
var current: int = 100
var immunity_left: float = 0.0
var guarded: bool = false


func _ready() -> void:
	restore()


func _physics_process(delta: float) -> void:
	immunity_left = maxf(0.0, immunity_left - delta)


func take_damage(amount: int, origin: Vector2 = Vector2.ZERO, knockback: float = 0.0) -> bool:
	if amount <= 0 or current <= 0 or guarded or immunity_left > 0.0:
		return false
	var applied: int = mini(amount, current)
	current -= applied
	immunity_left = damage_immunity_seconds
	changed.emit(current, maximum)
	damaged.emit(applied, origin, knockback)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if current <= 0 or amount <= 0:
		return
	current = mini(maximum, current + amount)
	changed.emit(current, maximum)


func restore() -> void:
	current = maxi(1, maximum)
	immunity_left = 0.0
	guarded = false
	changed.emit(current, maximum)
