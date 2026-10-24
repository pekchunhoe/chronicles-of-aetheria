extends Node2D
## World-space diagram from a captured SI state. Every force uses the same labelled scale.
var snapshot: Dictionary = {}
const FORCE_SCALE: float = 0.65


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 50


func _draw() -> void:
	if snapshot.is_empty():
		return
	var point: Vector2 = to_local(snapshot.point)
	draw_rect(Rect2(point - Vector2(18, 18), Vector2(36, 36)), Color("82e5ca"), false, 1)
	var p: Dictionary = snapshot.parameters
	if snapshot.kind == "incline":
		var f: Dictionary = snapshot.forces
		var tangent := Vector2(cos(deg_to_rad(p.angle)), -sin(deg_to_rad(p.angle)))
		var normal := Vector2(sin(deg_to_rad(p.angle)), cos(deg_to_rad(p.angle)))
		_arrow(point, Vector2(0, -f.weight_n), "W", Color("eaa17f"))
		_arrow(point, normal * f.normal_n, "N", Color("8dbde3"))
		_arrow(point, tangent * f.friction_n, "f", Color("e6c579"))
		_arrow(point, tangent * f.net_n, "ΣF", Color("7fe4c4"))
	elif snapshot.kind == "projectile":
		_arrow(point, Vector2(0, -snapshot.weight), "W", Color("eaa17f"))
	elif snapshot.kind == "energy":
		_arrow(point, Vector2(0, -p.mass * p.g), "W", Color("eaa17f"))
		_arrow(point, Vector2(0, p.loss * p.mass * p.g), "guide", Color("e6c579"))
	elif snapshot.kind == "momentum":
		_arrow(point, Vector2(0, -p.mass * p.g), "W", Color("eaa17f"))
		_arrow(point, Vector2(0, p.mass * p.g), "N", Color("8dbde3"))
		_arrow(point, snapshot.acceleration * p.mass, "f", Color("e6c579"))


func _arrow(start: Vector2, force_si: Vector2, caption: String, color: Color) -> void:
	if force_si.length() < 1e-8:
		return
	var screen := Vector2(force_si.x, -force_si.y) * FORCE_SCALE
	var finish: Vector2 = start + screen
	draw_line(start, finish, color, 2)
	var direction: Vector2 = screen.normalized()
	draw_line(finish, finish - direction.rotated(0.5) * 5, color, 1)
	draw_line(finish, finish - direction.rotated(-0.5) * 5, color, 1)
	draw_string(GameTheme.body_font(), finish + Vector2(3, -3), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
