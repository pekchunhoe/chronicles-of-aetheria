class_name AttackData
extends Resource
## A weapon move's timeline and directional rectangle, all in arcade units.
@export var title: String = "Salvager cut"
@export var damage: int = 14
@export var startup: float = 0.07
@export var active: float = 0.10
@export var recovery: float = 0.16
@export var reach: float = 40.0
@export var height: float = 32.0
@export var knockback: float = 150.0
@export var movement_multiplier: float = 0.65
@export var color: Color = Color("a4f3dc")


func total_seconds() -> float:
	return startup + active + recovery
