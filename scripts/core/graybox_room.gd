extends Node2D

signal checkpoint_reached(checkpoint_id: String)
const SPAWNS: Dictionary = {"room_start": Vector2(128, 302), "east_checkpoint": Vector2(760, 302)}
var checkpoint_id: String = "room_start"
@onready var player: FoundationPlayer = $Player


func _ready() -> void:
	player.fell.connect(respawn)
	$Checkpoint.body_entered.connect(_on_checkpoint_body_entered)
	respawn()


func set_checkpoint(identity: String) -> void:
	checkpoint_id = identity if SPAWNS.has(identity) else "room_start"
	queue_redraw()


func respawn() -> void:
	player.reset_to(SPAWNS[checkpoint_id])
	Controls.release_virtual()


func _on_checkpoint_body_entered(body: Node2D) -> void:
	if body == player and checkpoint_id != "east_checkpoint":
		set_checkpoint("east_checkpoint")
		checkpoint_reached.emit(checkpoint_id)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 480), Color("0e1927"))
	for x in range(0, 1153, 32):
		draw_line(Vector2(x, 0), Vector2(x, 360), Color("152332"))
	for y in range(0, 361, 32):
		draw_line(Vector2(0, y), Vector2(1152, y), Color("152332"))
	for x in range(32, 1152, 160):
		draw_rect(Rect2(x, 140, 20, 180), Color("1b2c3b"))
	for rect in [Rect2(0, 320, 448, 64), Rect2(528, 320, 624, 64), Rect2(240, 264, 112, 16)]:
		draw_rect(rect, Color("465461"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("849398"))
	draw_rect(Rect2(448, 356, 80, 4), Color("c58d70"))
	draw_line(Vector2(760, 320), Vector2(760, 266), Color("82c7bb"), 3)
	draw_rect(Rect2(762, 268, 30, 18), Color("82c7bb") if checkpoint_id == "east_checkpoint" else Color("486a72"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(50, 270), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a4b4bf"))
	draw_string(font, Vector2(242, 244), "PLATFORM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a4b4bf"))
	draw_string(font, Vector2(424, 296), "JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d2ac8a"))
	draw_string(font, Vector2(718, 250), "CHECKPOINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("82c7bb"))
