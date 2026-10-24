extends Node2D

signal checkpoint_reached(checkpoint_id: String)
signal progression_changed(message: String)
signal sector_completed
const CrawlerScene = preload("res://scenes/enemies/mechanical_crawler.tscn")
const TurretScene = preload("res://scenes/enemies/defensive_turret.tscn")
const SPAWNS: Dictionary = {"room_start": Vector2(128, 302), "east_checkpoint": Vector2(760, 302), "citadel_checkpoint": Vector2(2040, 302)}
const RELIC_ID: String = "citadel.training.axiom_shard"
const COMPLETION_ID: String = "citadel.training.complete"
const WIDTH: float = 3328.0
const EXTENDED_PLATFORMS: Array[Rect2] = [
	Rect2(1152, 320, 96, 64), Rect2(1168, 272, 144, 16),
	Rect2(1296, 224, 128, 16), Rect2(1408, 176, 176, 16),
	Rect2(1584, 224, 144, 16), Rect2(1728, 272, 288, 16),
	Rect2(2016, 320, 432, 64), Rect2(2528, 320, 800, 64),
	Rect2(2112, 264, 80, 12), Rect2(2192, 208, 80, 12),
	Rect2(2272, 152, 224, 12), Rect2(2496, 208, 80, 12),
	Rect2(2576, 264, 80, 12),
]
var checkpoint_id: String = "room_start"
var relic_collected: bool = false
var completed: bool = false
var enemies: Array[EnemyBase] = []
var relay: ProgressionMarker
var relic: ProgressionMarker
var exit_marker: ProgressionMarker
var legacy_checkpoint_visual: MarkerPresentation
@onready var player: FoundationPlayer = $Player


func _ready() -> void:
	player.world_right = WIDTH - 10.0
	player.get_node("Camera2D").limit_right = int(WIDTH)
	player.fell.connect(_on_fall)
	player.respawn_requested.connect(respawn)
	$Checkpoint.body_entered.connect(_on_checkpoint_body_entered)
	_build_sector()
	legacy_checkpoint_visual = MarkerPresentation.new()
	$Checkpoint.add_child(legacy_checkpoint_visual)
	add_child(CitadelPresentation.new())
	respawn()


func set_checkpoint(identity: String) -> void:
	checkpoint_id = identity if SPAWNS.has(identity) else "room_start"
	if is_instance_valid(legacy_checkpoint_visual):
		legacy_checkpoint_visual.active = checkpoint_id == "east_checkpoint"
	if is_instance_valid(relay):
		relay.set_active(checkpoint_id == "citadel_checkpoint")
	queue_redraw()


func respawn(restore_health: bool = true) -> void:
	var remaining_health: int = player.health.current
	player.reset_to(SPAWNS[checkpoint_id])
	if not restore_health:
		player.health.current = remaining_health
		player.health.changed.emit(remaining_health, player.health.maximum)
	player.health.immunity_left = 0.4
	for enemy in enemies:
		enemy.reset_enemy()
	for bolt in get_tree().get_nodes_in_group("projectiles"):
		if is_ancestor_of(bolt):
			bolt.queue_free()
	Controls.release_virtual()


func _on_fall() -> void:
	# Preserve Phase 0 immediate fall recovery; lethal falls use the death timeline.
	player.health.immunity_left = 0.0
	player.health.guarded = false
	player.health.take_damage(20, player.global_position, 0.0)
	if player.health.current > 0:
		respawn(false)


func restore_progress(data: Dictionary) -> void:
	relic_collected = RELIC_ID in data.get("collected_crystals", [])
	completed = COMPLETION_ID in data.get("unlocks", [])
	relic.set_active(relic_collected)
	exit_marker.set_active(completed)


func snapshot_progress(data: Dictionary) -> void:
	if relic_collected and RELIC_ID not in data.collected_crystals:
		data.collected_crystals.append(RELIC_ID)
	if completed and COMPLETION_ID not in data.unlocks:
		data.unlocks.append(COMPLETION_ID)


func _build_sector() -> void:
	for rectangle in EXTENDED_PLATFORMS:
		var platform := ModularPlatform.new()
		platform.position = rectangle.position
		platform.dimensions = rectangle.size
		if rectangle.position.y < 272:
			platform.accent = Color("82adb4")
		add_child(platform)
	relay = _marker(ProgressionMarker.Kind.CHECKPOINT, "citadel_checkpoint", Vector2(2040, 292))
	relic = _marker(ProgressionMarker.Kind.RELIC, RELIC_ID, Vector2(2380, 132))
	exit_marker = _marker(ProgressionMarker.Kind.EXIT, COMPLETION_ID, Vector2(3200, 292))
	for spawn in [
		[CrawlerScene, Vector2(1000, 308)], [TurretScene, Vector2(1840, 258)],
		[CrawlerScene, Vector2(2280, 308)], [TurretScene, Vector2(2410, 306)],
		[CrawlerScene, Vector2(2810, 308)],
	]:
		var enemy: EnemyBase = spawn[0].instantiate()
		enemy.position = spawn[1]
		add_child(enemy)
		enemies.append(enemy)


func _marker(kind: ProgressionMarker.Kind, identity: String, point: Vector2) -> ProgressionMarker:
	var marker := ProgressionMarker.new()
	marker.kind = kind
	marker.identity = identity
	marker.position = point
	marker.activated.connect(_on_marker_activated)
	add_child(marker)
	return marker


func _on_marker_activated(marker: ProgressionMarker) -> void:
	match marker.kind:
		ProgressionMarker.Kind.CHECKPOINT:
			if checkpoint_id != marker.identity:
				set_checkpoint(marker.identity)
				player.health.heal(player.health.maximum)
				player.audio.cue("relay")
				checkpoint_reached.emit(checkpoint_id)
		ProgressionMarker.Kind.RELIC:
			if not relic_collected:
				relic_collected = true
				marker.set_active(true)
				player.audio.cue("relay")
				progression_changed.emit("Axiom shard found. Optional reward saved.")
		ProgressionMarker.Kind.EXIT:
			if not completed:
				completed = true
				marker.set_active(true)
				player.audio.cue("relay")
				sector_completed.emit()


func _on_checkpoint_body_entered(body: Node2D) -> void:
	if body == player and checkpoint_id != "east_checkpoint":
		set_checkpoint("east_checkpoint")
		player.health.heal(player.health.maximum)
		player.audio.cue("relay")
		checkpoint_reached.emit(checkpoint_id)
