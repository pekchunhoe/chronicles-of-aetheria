extends SceneTree
## Measures original raster masters; never modifies image pixels.
## Explicit row bands compensate for generation gutters. Re-run after changing art.
const SOURCES: Dictionary = {
	"hero": {"path": "res://assets/characters/kael_atlas.png", "bands": [0, 172, 322, 495, 650, 835, 960, 1120, 1254]},
	"machines": {"path": "res://assets/enemies/machines_atlas.png", "bands": [0, 170, 326, 495, 650, 808, 960, 1100, 1254]},
	"world": {"path": "res://assets/environment/citadel_atlas.png", "bands": [0, 138, 284, 462, 637, 795, 974, 1114, 1254]},
}


func _initialize() -> void:
	var data: Dictionary = {"version": 1, "virtual_frame": [192, 192], "sprite_scale": 0.25, "atlases": {}}
	for identity in SOURCES:
		var source: Dictionary = SOURCES[identity]
		var bitmap := Image.load_from_file(source.path)
		if bitmap == null:
			quit(1)
			return
		var frames: Array[Dictionary] = []
		for index in range(64):
			var column: int = index % 8
			var row: int = index / 8
			var left: int = roundi(float(column) * bitmap.get_width() / 8.0)
			var right: int = roundi(float(column + 1) * bitmap.get_width() / 8.0)
			var top: int = roundi(float(source.bands[row]) * bitmap.get_height() / 1254.0)
			var bottom: int = roundi(float(source.bands[row + 1]) * bitmap.get_height() / 1254.0)
			var low := Vector2i(right, bottom)
			var high := Vector2i(left, top)
			var foot: int = top
			for y in range(top, bottom):
				for x in range(left, right):
					if bitmap.get_pixel(x, y).a > 0.18:
						low = low.min(Vector2i(x, y))
						high = high.max(Vector2i(x + 1, y + 1))
						if x > left + (right - left) * 0.32 and x < left + (right - left) * 0.72:
							foot = maxi(foot, y + 1)
			var size: Vector2i = high - low
			assert(size.x > 0 and size.y > 0, "Empty atlas frame " + identity + str(index))
			var anchor := Vector2((left + right) * 0.5, foot)
			if identity == "machines" and row == 6:
				anchor = Vector2(left + (right - left) * 0.34, top + (bottom - top) * 0.5)
			frames.append({"region": [low.x, low.y, size.x, size.y], "anchor": [anchor.x - low.x, anchor.y - low.y]})
		data.atlases[identity] = {"path": source.path, "size": [bitmap.get_width(), bitmap.get_height()], "frames": frames}
	var file := FileAccess.open("res://assets/source/atlas_layout.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()
	print("ART METADATA PASS: 192 nonempty measured regions; original raster masters unchanged.")
	quit(0)
