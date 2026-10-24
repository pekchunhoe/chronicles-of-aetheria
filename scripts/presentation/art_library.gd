class_name ArtLibrary
extends RefCounted
## Immutable raster masters plus measured atlas regions. Runtime never edits pixels.
const TITLE_FONT = preload("res://assets/fonts/Cinzel.ttf")
const BACKGROUND = preload("res://assets/backgrounds/citadel_depths.png")
const HERO_ANIMATIONS: Dictionary = {
	"idle": [0, 8, 6, true], "run": [8, 8, 12, true],
	"jump_start": [16, 2, 12, false], "rise": [18, 2, 8, true],
	"fall": [20, 2, 8, true], "land": [22, 2, 14, false],
	"light_1": [24, 4, 12, false], "light_2": [28, 4, 12, false],
	"light_3": [32, 4, 12, false], "heavy": [36, 4, 10, false],
	"dodge": [40, 8, 16, false], "hurt": [48, 4, 12, false],
	"respawn": [52, 4, 12, false], "death": [56, 8, 10, false],
}
const CRAWLER_ANIMATIONS: Dictionary = {
	"idle": [0, 8, 6, true], "patrol": [8, 8, 7, true], "chase": [8, 8, 12, true],
	"alert": [16, 4, 12, false], "hurt": [20, 4, 14, false],
	"attack": [24, 8, 12, false], "death": [32, 8, 14, false],
}
const TURRET_ANIMATIONS: Dictionary = {"idle": [40, 4, 6, true], "death": [44, 4, 10, false]}
static var data: Dictionary = {}
static var textures: Dictionary = {}
static var regions: Dictionary = {}
static var animations: Dictionary = {}


static func layout() -> Dictionary:
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source/atlas_layout.json"))
	return data


static func texture(identity: String, index: int, normalized: bool = false) -> AtlasTexture:
	var key: String = identity + ":" + str(index) + (":frame" if normalized else ":prop")
	if regions.has(key):
		return regions[key]
	var atlas_data: Dictionary = layout().atlases[identity]
	if not textures.has(identity):
		textures[identity] = load(atlas_data.path)
	var entry: Dictionary = atlas_data.frames[index]
	var rect: Array = entry.region
	var region := AtlasTexture.new()
	region.atlas = textures[identity]
	region.region = Rect2(rect[0], rect[1], rect[2], rect[3])
	region.filter_clip = true
	if normalized:
		var anchor: Array = entry.anchor
		var destination := Vector2(96, 96) if identity == "machines" and index in range(48, 56) else Vector2(96, 168)
		region.margin = Rect2(destination - Vector2(anchor[0], anchor[1]), Vector2(192, 192) - region.region.size)
	regions[key] = region
	return region


static func sprite_frames(role: String) -> SpriteFrames:
	if animations.has(role):
		return animations[role]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var definitions: Dictionary = HERO_ANIMATIONS if role == "hero" else CRAWLER_ANIMATIONS if role == "crawler" else TURRET_ANIMATIONS
	for animation in definitions:
		var definition: Array = definitions[animation]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, definition[2])
		frames.set_animation_loop(animation, definition[3])
		for index in range(definition[0], definition[0] + definition[1]):
			frames.add_frame(animation, texture("hero" if role == "hero" else "machines", index, true))
	animations[role] = frames
	return frames


static func draw_platform(canvas: CanvasItem, size: Vector2, metal: bool = false) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("222e39"))
	for y in range(0, ceili(size.y), 32):
		for x in range(0, ceili(size.x), 32):
			var index: int = (4 + (x / 32) % 3 if metal else (x / 32) % 4) if y == 0 else 8 + (x / 32 + y / 32) % 3
			var tile: AtlasTexture = texture("world", index)
			var extent := Vector2(minf(32, size.x - x), minf(32, size.y - y))
			var sample := Rect2(tile.region.position, tile.region.size * extent / 32.0)
			canvas.draw_texture_rect_region(tile.atlas, Rect2(Vector2(x, y), extent), sample)
	# A crisp collision lip stays aligned to the unchanged platform surface.
	canvas.draw_line(Vector2.ZERO, Vector2(size.x, 0), Color("a6a17c"), 1)


static func prop(canvas: CanvasItem, index: int, rectangle: Rect2, color: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect(texture("world", index), rectangle, false, color)
