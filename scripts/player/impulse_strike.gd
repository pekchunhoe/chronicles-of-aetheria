class_name ImpulseStrike
extends Node2D
## Quantified rail impulse is separate from explicitly arcade enemy stagger.
signal feedback(message: String)
@export var impulse_ns: float = 10.0
@export var cooldown_seconds: float = 2.0
@export var windup_seconds: float = 0.10
var unlocked: bool = false
var cooldown_left: float = 0.0
var activation_left: float = 0.0
var direction: float = 1.0
var resolved: bool = false
var effect_left: float = 0.0
@onready var hero: FoundationPlayer = get_parent()


func begin() -> bool:
	if not unlocked:
		feedback.emit("Impulse Strike awaits the Momentum Vault module.")
		return false
	if cooldown_left > 0 or hero.health.current <= 0 or hero.hurt_left > 0 or hero.dodge.running or hero.combat.attack != null:
		return false
	direction = hero.facing
	cooldown_left = cooldown_seconds
	activation_left = windup_seconds + 0.16
	effect_left = 0.0
	resolved = false
	hero.audio.cue("swing")
	return true


func advance(dt: float) -> void:
	cooldown_left = maxf(0, cooldown_left - dt)
	activation_left = maxf(0, activation_left - dt)
	effect_left = maxf(0, effect_left - dt)
	if not resolved and activation_left > 0 and activation_left <= 0.16:
		resolved = true
		if hero.health.current > 0 and hero.hurt_left <= 0:
			_resolve()
	queue_redraw()


func _resolve() -> void:
	effect_left = 0.16
	var shape := RectangleShape2D.new()
	shape.size = Vector2(72, 80)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, hero.global_position + Vector2(direction * 44, -22))
	query.collision_mask = 40
	var message: String = "No compatible cargo or enemy in reach. Face a nearby target."
	for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body: Node2D = result.collider
		var ray := PhysicsRayQueryParameters2D.create(hero.global_position + Vector2(0, -14), body.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		if body.get_parent() is AxiomApparatus:
			var machine: AxiomApparatus = body.get_parent()
			if machine.deliver_impulse(Vector2(direction * impulse_ns, 0)):
				message = "Cargo received %.1f N s; Δv = %.2f m s⁻¹. The rough guide applies a later friction impulse." % [impulse_ns, direction * impulse_ns / machine.experiment.parameters.mass]
				break
		elif body is EnemyBase and body.health.current > 0:
			if body is DefensiveTurret:
				message = "Turret anchored to the Citadel. Use the sword to break its armour."
			else:
				body._set_state(EnemyBase.State.HURT)
				body.velocity = Vector2(direction * 180, -45)
				ImpactBurst.spawn(body, 0, Color("83d9c5"))
				message = "Crawler staggered — arcade combat knockback. Sword strikes still deal damage."
			break
	feedback.emit(message)


func reset() -> void:
	cooldown_left = 0
	activation_left = 0
	effect_left = 0
	resolved = true


func _draw() -> void:
	if effect_left <= 0:
		return
	draw_set_transform(Vector2(direction * 12, -14), 0, Vector2(direction, 1))
	ArtLibrary.prop(self, 57, Rect2(0, -21, 70, 42), Color(0.45, 1, 0.85, effect_left / 0.16))
	ArtLibrary.prop(self, 63, Rect2(25, -19, 38, 38), Color(0.55, 1, 0.9, effect_left / 0.16))
