class_name CitadelPresentation
extends Node2D
## Six decorative layers. Existing level geometry stays in the collision scenes.
var camera: Camera2D
var age: float = 0.0
var lights: Array[PointLight2D] = []
var dust: Array[Vector3] = []

class AmbientMotes extends Node2D:
	var environment: Node2D

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		environment.draw_motes(self)

class DepthLayer extends Node2D:
	var camera: Camera2D
	var ratio: float = 0.18
	var layer_kind: int = 0

	func _process(_delta: float) -> void:
		position.x = roundf(camera.get_screen_center_position().x * (1.0 - ratio))
		queue_redraw()

	func _draw() -> void:
		var center: float = camera.get_screen_center_position().x - position.x
		var width: float = get_viewport_rect().size.x
		if layer_kind == 0:
			var first: int = floori((center - width * 0.5 + 384) / 1536.0) - 1
			for index in range(first, first + ceili(width / 1536.0) + 3):
				draw_texture_rect(ArtLibrary.BACKGROUND, Rect2(index * 1536 - 384, -180, 1536, 1024), false, Color("b2bdc5"))
		else:
			var first: int = floori((center - width * 0.5) / 384.0) - 1
			for index in range(first, first + ceili(width / 384.0) + 3):
				var x: float = index * 384.0
				ArtLibrary.prop(self, 28, Rect2(x + 16, 76, 156, 174), Color("51616b"))
				ArtLibrary.prop(self, 20, Rect2(x + 208, 128, 95, 95), Color("3d4b53"))
				ArtLibrary.prop(self, 18, Rect2(x + 276, -12, 12, 134), Color("61727a"))


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	process_priority = 200
	camera = get_parent().player.get_node("Camera2D")
	for index in range(2):
		var layer := DepthLayer.new()
		layer.name = "DistantVault" if index == 0 else "MidgroundArchitecture"
		layer.layer_kind = index
		layer.ratio = 0.18 if index == 0 else 0.48
		layer.camera = camera
		layer.z_index = -30 + index * 10
		layer.process_priority = 200
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(layer)
	var ambient := CanvasModulate.new()
	ambient.color = Color("d4dbe3")
	add_child(ambient)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.65), Color(1, 1, 1, 0)])
	var glow := GradientTexture2D.new()
	glow.width = 128
	glow.height = 128
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(0.5, 1.0)
	for point in [Vector2(80, 252), Vector2(640, 240), Vector2(1224, 210), Vector2(1744, 218), Vector2(2180, 272), Vector2(2740, 246), Vector2(3168, 242)]:
		var light := PointLight2D.new()
		light.position = point
		light.texture = glow
		light.texture_scale = 1.5
		light.color = Color("efb16a")
		light.energy = 0.6
		light.shadow_enabled = false
		add_child(light)
		lights.append(light)
	var random := RandomNumberGenerator.new()
	random.seed = 104729
	for index in range(36):
		dust.append(Vector3(random.randf(), random.randf(), random.randf_range(0.5, 1.5)))
	var motes := AmbientMotes.new()
	motes.environment = self
	add_child(motes)


func _process(delta: float) -> void:
	age += delta
	for light in lights:
		light.enabled = Visuals.quality > 0 and absf(light.position.x - camera.get_screen_center_position().x) < 440
		light.energy = 0.6 if Visuals.reduced_motion else 0.58 + sin(age * 4 + light.position.x) * 0.035


func _draw() -> void:
	# Original three colliders keep their exact scene geometry; this only skins them.
	for rectangle in [Rect2(0, 320, 448, 64), Rect2(528, 320, 624, 64), Rect2(240, 264, 112, 16)]:
		draw_set_transform(rectangle.position)
		ArtLibrary.draw_platform(self, rectangle.size, rectangle.size.y < 32)
	draw_set_transform(Vector2.ZERO)
	_draw_props()


func draw_motes(canvas: CanvasItem) -> void:
	var count: int = [8, 20, 36][Visuals.quality]
	var center: Vector2 = camera.get_screen_center_position()
	for index in range(count):
		var mote: Vector3 = dust[index]
		var drift: float = 0 if Visuals.reduced_motion else age * mote.z * 3
		var point := Vector2(center.x - 320 + fposmod(mote.x * 640 + drift, 640), 50 + fposmod(mote.y * 240 - drift * 0.3, 240))
		canvas.draw_rect(Rect2(point.round(), Vector2.ONE), Color(0.72, 0.77, 0.73, 0.20 + mote.z * 0.08))


func _draw_props() -> void:
	# Background props stay behind actors and never receive collision shapes.
	for entry in [
		[16, Rect2(18, 126, 36, 194)], [22, Rect2(58, 280, 50, 40)],
		[23, Rect2(328, 218, 24, 40)], [17, Rect2(572, 134, 38, 186)],
		[21, Rect2(822, 238, 46, 80)], [22, Rect2(1080, 276, 54, 44)],
		[16, Rect2(1460, 40, 35, 136)], [25, Rect2(1520, 141, 28, 35)],
		[17, Rect2(1940, 104, 36, 168)], [23, Rect2(1972, 214, 22, 38)],
		[21, Rect2(2070, 239, 40, 80)], [22, Rect2(2660, 276, 60, 44)],
		[16, Rect2(3024, 114, 38, 206)], [25, Rect2(3080, 280, 26, 40)],
	]:
		ArtLibrary.prop(self, entry[0], entry[1], Color("9ba7aa"))
	for light in lights:
		ArtLibrary.prop(self, 24, Rect2(light.position - Vector2(8, 18), Vector2(16, 36)))
	for x in [448, 2448]:
		draw_line(Vector2(x + 2, 355), Vector2(x + 78, 355), Color("ad7548"), 1)
	for entry in [[265, 262], [870, 318], [1120, 318], [1498, 174], [2250, 150], [2715, 318], [3054, 318]]:
		ArtLibrary.prop(self, 44, Rect2(entry[0], entry[1], 38, 7), Color("a0a994"))
