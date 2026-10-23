class_name DodgeController
extends Node
## Travel is collision-resolved by the player; invulnerability is only early travel.
@export var distance_px: float = 92.0
@export var duration: float = 0.18
@export var invulnerability_seconds: float = 0.12
@export var recovery_seconds: float = 0.14
@export var cooldown_seconds: float = 0.72
var elapsed: float = 0.0
var cooldown_left: float = 0.0
var direction: float = 1.0
var running: bool = false


func begin(facing: float) -> bool:
	if cooldown_left > 0.0 or running:
		return false
	direction = -1.0 if facing < 0.0 else 1.0
	elapsed = 0.0
	cooldown_left = cooldown_seconds
	running = true
	return true


func advance(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if running:
		elapsed += delta
		if elapsed >= duration + recovery_seconds:
			running = false


func active() -> bool:
	return running and elapsed < duration


func invulnerable() -> bool:
	return active() and elapsed < invulnerability_seconds


func reset() -> void:
	running = false
	cooldown_left = 0.0
	elapsed = 0.0
