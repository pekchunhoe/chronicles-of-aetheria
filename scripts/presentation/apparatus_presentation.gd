extends Node2D
## Original moving machinery assembled from the approved Phase 2 bronze/stone atlas.
var age: float = 0.0
@onready var machine: AxiomApparatus = get_parent()
const TEAL := Color("79e0c4")
const BRASS := Color("b49866")


func _process(delta: float) -> void:
	if absf(machine.global_position.x - machine.get_viewport().get_camera_2d().global_position.x) > 1750:
		return
	age += delta
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(machine.payload):
		return
	var p: Dictionary = machine.experiment.parameters
	var target: Vector2 = machine.receiver.position
	match machine.kind:
		"incline":
			var end: Vector2 = target - Vector2.RIGHT.rotated(deg_to_rad(p.angle)) * 14
			for x in range(0, int(end.x), 32):
				var y: float = x * tan(deg_to_rad(p.angle))
				ArtLibrary.prop(self, 17, Rect2(x - 5, y + 12, 10, maxf(10, 212 - y)))
			draw_line(Vector2(0, 12), end + Vector2(0, 12), BRASS.darkened(0.5), 9)
			draw_line(Vector2(0, 8), end + Vector2(0, 8), BRASS, 2)
			ArtLibrary.prop(self, 20, Rect2(-28, -32, 36, 36))
		"projectile":
			ArtLibrary.prop(self, 29, Rect2(-40, -28, 70, 76))
			draw_set_transform(machine.origin_offset(), -deg_to_rad(p.angle))
			ArtLibrary.prop(self, 17, Rect2(-10, -10, 50, 20))
			draw_set_transform(Vector2.ZERO)
			if machine.inspected and machine.prediction.size() > 1:
				for index in range(1, machine.prediction.size(), 3):
					draw_circle(machine.prediction[index], 1.4, Color(0.47, 0.88, 0.77, 0.65))
		"momentum":
			for x in range(-32, 190, 32):
				ArtLibrary.prop(self, 7, Rect2(x, 12, 32, 12))
			ArtLibrary.prop(self, 29, Rect2(-48, -16, 32, 48))
		"energy":
			for y in range(-176, 14, 32):
				ArtLibrary.prop(self, 17, Rect2(-34, y, 12, 32))
				draw_line(Vector2(-15, y), Vector2(-15, y + 24), BRASS.darkened(0.3), 2)
			ArtLibrary.prop(self, 20, Rect2(-56, -194, 54, 54))
			ArtLibrary.prop(self, 29, Rect2(-34, 12, 68, 40))
			var energies: Dictionary = machine.experiment.measurements().energy
			var initial: float = p.mass * p.g * p.height
			for entry in [[energies.potential, TEAL], [energies.kinetic, Color("edc47d")], [machine.experiment.heat_j, Color("e68e79")]]:
				var i: int = 0 if entry[1] == TEAL else 1 if entry[1] == Color("edc47d") else 2
				draw_rect(Rect2(26 + i * 10, -120, 6, 100), Color("23323e"))
				var h: float = clampf(entry[0] / initial, 0, 1) * 100
				draw_rect(Rect2(26 + i * 10, -20 - h, 6, h), entry[1])
	ArtLibrary.prop(self, 32 + (2 if machine.latched else 0), Rect2(target.x - 19, target.y - 28, 38, 56))
	ArtLibrary.prop(self, 23, Rect2(-52, 64 if machine.kind == "incline" else 30, 30, 28))
	var point: Vector2 = machine.payload.position
	draw_set_transform(point, machine.payload.rotation)
	if machine.kind == "projectile":
		ArtLibrary.prop(self, 36, Rect2(-7, -7, 14, 14))
	elif machine.kind == "energy":
		ArtLibrary.prop(self, 19, Rect2(-13, -13, 26, 26))
	else:
		ArtLibrary.prop(self, 11, Rect2(-12, -12, 24, 24))
		ArtLibrary.prop(self, 48, Rect2(-5, -5, 10, 10), TEAL)
	if machine.inspected:
		draw_rect(Rect2(-17, -17, 34, 34), TEAL, false, 1)
	draw_set_transform(Vector2.ZERO)
	if machine.experiment.running and not Visuals.reduced_motion:
		draw_arc(target, 22, age * 2, age * 2 + PI, 16, TEAL, 1)
