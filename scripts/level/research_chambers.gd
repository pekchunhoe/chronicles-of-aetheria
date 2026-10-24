class_name ResearchChambers
extends Node2D
signal changed(message: String)
signal checkpoint(identity: String)
const WIDTH: float = 7040.0
const CHECKPOINTS: Dictionary = {"research_a": Vector2(160, 302), "research_b": Vector2(780, 302), "research_c": Vector2(1510, 302), "research_d": Vector2(3370, 302), "research_e": Vector2(4220, 302), "research_f": Vector2(5010, 302)}
const TITLES: Array[String] = ["A · THE LOST LABORATORY", "B · THE CARGO MECHANISM", "C · THE BROKEN CROSSING", "D · THE MOMENTUM VAULT", "E · THE ENERGY ENGINE", "F · THE INTEGRATED TRIAL"]
const BOUNDARIES: Array[float] = [0.0, 720.0, 1450.0, 3300.0, 4150.0, 4950.0, 7040.0]
var progress := ResearchProgress.new()
var player: FoundationPlayer
var active: bool = false
var machines: Array[AxiomApparatus] = []
var enemies: Array[EnemyBase] = []
var gates: Dictionary = {}
var bridge: ModularPlatform
var shard_marker: ProgressionMarker
var checkpoint_index: int = -1
var notice: String = "Mira: The lost diagnostic module is on the laboratory pedestal. Use Interact beside it."
var cleared_enemy_ids: Array[int] = []
var observe_camera: Camera2D
var room_name: String = ""


func _ready() -> void:
	player = get_parent().player
	_build_geometry()
	observe_camera = Camera2D.new()
	observe_camera.enabled = false
	observe_camera.limit_left = int(global_position.x)
	observe_camera.limit_right = int(global_position.x + WIDTH)
	observe_camera.limit_top = -480
	observe_camera.limit_bottom = 360
	add_child(observe_camera)
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	visible = value
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	for enemy in enemies:
		enemy.collision_layer = 8 if value and enemy.health.current > 0 else 0
	if not value and is_instance_valid(observe_camera):
		observe_camera.enabled = false
		player.get_node("Camera2D").enabled = true


func _build_geometry() -> void:
	for rectangle in [Rect2(0, 320, 2060, 64), Rect2(2380, 320, 4660, 64), Rect2(500, 264, 112, 16), Rect2(3740, 264, 90, 12), Rect2(3820, 208, 90, 12), Rect2(3900, 152, 160, 12), Rect2(5720, 264, 112, 16), Rect2(5840, 216, 150, 16), Rect2(6140, 264, 120, 16)]:
		_platform(rectangle)
	bridge = _platform(Rect2(2060, 320, 320, 20))
	bridge.hide()
	bridge.get_node("CollisionShape2D").set_deferred("disabled", true)
	for entry in [["incline", "cargo", Vector2(930, 100)], ["projectile", "crossing", Vector2(1660, 230)], ["momentum", "vault", Vector2(3550, 260)], ["energy", "engine", Vector2(4450, 252)], ["incline", "trial_cargo", Vector2(5150, 100)], ["projectile", "trial_launcher", Vector2(5580, 230)]]:
		var machine: AxiomApparatus = load("res://scenes/experiments/" + entry[0] + ".tscn").instantiate()
		machine.identity = entry[1]
		machine.position = entry[2]
		machine.contacted.connect(_on_contact)
		add_child(machine)
		if machine.identity == "trial_launcher":
			machine.adjust("target_x", 16.0)
			machine.adjust("target_y", 1.0)
		machines.append(machine)
	for entry in [["cargo", 1420], ["vault", 4100], ["engine", 4900], ["trial_cargo", 5490], ["trial_final", 6800]]:
		var gate := StaticBody2D.new()
		gate.position = Vector2(entry[1], 160)
		gate.collision_layer = 1
		gate.collision_mask = 2
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20, 320)
		collision.shape = shape
		gate.add_child(collision)
		add_child(gate)
		gates[entry[0]] = gate
	for entry in [["mechanical_crawler", Vector2(600, 306)], ["mechanical_crawler", Vector2(1300, 306)], ["defensive_turret", Vector2(3080, 306)], ["mechanical_crawler", Vector2(3880, 306)], ["mechanical_crawler", Vector2(4770, 306)], ["mechanical_crawler", Vector2(5350, 306)], ["defensive_turret", Vector2(6090, 306)], ["mechanical_crawler", Vector2(6550, 306)]]:
		var enemy: EnemyBase = load("res://scenes/enemies/" + entry[0] + ".tscn").instantiate()
		enemy.position = entry[1]
		add_child(enemy)
		enemy.defeated.connect(_enemy_defeated)
		enemies.append(enemy)
	shard_marker = ProgressionMarker.new()
	shard_marker.kind = ProgressionMarker.Kind.RELIC
	shard_marker.identity = ResearchProgress.ROOT + "axiom_shard"
	shard_marker.position = Vector2(3990, 132)
	shard_marker.activated.connect(func(_marker: ProgressionMarker):
		if not progress.shard:
			progress.shard = true
			shard_marker.set_active(true)
			changed.emit("Axiom Research Shard found. Optional discovery saved.")
	)
	add_child(shard_marker)


func _platform(rectangle: Rect2) -> ModularPlatform:
	var platform := ModularPlatform.new()
	platform.position = rectangle.position
	platform.dimensions = rectangle.size
	add_child(platform)
	return platform


func _physics_process(_dt: float) -> void:
	var x: float = player.global_position.x - global_position.x
	var index: int = chamber_index(x)
	room_name = TITLES[index]
	if index != checkpoint_index and x >= BOUNDARIES[index] + 40:
		checkpoint_index = index
		checkpoint.emit(str(CHECKPOINTS.keys()[index]))
	if index >= 3 and not progress.impulse_unlocked:
		progress.impulse_unlocked = true
		progress.discover(["mechanics.impulse", "mechanics.momentum"])
		notice = "Mira: Impulse Strike restored. The same push accelerates lighter cargo more. Face the cargo and use your gauntlet tool."
		changed.emit(notice)
	var observed: AxiomApparatus
	for machine in machines:
		if machine.kind == "projectile" and machine.experiment.running and machine.camera_follow:
			observed = machine
	if observed != null:
		observe_camera.enabled = true
		player.get_node("Camera2D").enabled = false
		observe_camera.global_position = observed.payload.global_position.round()
	else:
		observe_camera.enabled = false
		player.get_node("Camera2D").enabled = true
	if x > 6890 and final_ready() and "complete" not in progress.completed:
		progress.completed.append("complete")
		changed.emit("RESEARCH CHAMBERS RESTORED — Mira: The laws never broke. Our machines did. Interact at the portal to return to the Citadel.")
	queue_redraw()


func final_ready() -> bool:
	return "trial_cargo" in progress.completed and "trial_launcher" in progress.completed and progress.trial_enemy_defeated


func chamber_index(x: float) -> int:
	for index in range(5, -1, -1):
		if x >= BOUNDARIES[index]:
			return index
	return 0


func nearest_machine() -> AxiomApparatus:
	var nearest: AxiomApparatus
	var distance: float = 210.0
	for machine in machines:
		var separation: float = absf(player.global_position.x - machine.global_position.x)
		if separation < distance:
			distance = separation
			nearest = machine
	return nearest


func unlock_vector() -> void:
	if progress.vector_unlocked:
		return
	progress.vector_unlocked = true
	progress.record_contact("laboratory", true)
	progress.discover(["mechanics.newton", "mechanics.weight", "mechanics.friction"])
	notice = "Mira: Vector Sight is online. It captures the machine's motion before pausing. Select a machine with Interact; Q inspects it."
	changed.emit(notice)


func _on_contact(machine: AxiomApparatus, accepted: bool) -> void:
	if progress.record_contact(machine.identity, accepted):
		match machine.kind:
			"incline": progress.discover(["mechanics.newton", "mechanics.weight", "mechanics.friction"])
			"projectile": progress.discover(["mechanics.projectile"])
			"momentum": progress.discover(["mechanics.impulse", "mechanics.momentum"])
			"energy": progress.discover(["mechanics.potential", "mechanics.kinetic", "mechanics.conservation"])
		_refresh_gates()
		changed.emit("%s relay activated by physical contact. Discovery saved; the apparatus can be replayed." % machine.identity.replace("_", " ").capitalize())
	elif not accepted:
		changed.emit(machine.experiment.result_text)


func _enemy_defeated(enemy: Node2D) -> void:
	if enemy.get_instance_id() not in cleared_enemy_ids:
		cleared_enemy_ids.append(enemy.get_instance_id())
	if enemy.position.x > 4950:
		progress.trial_enemy_defeated = true
		_refresh_gates()
		changed.emit("Trial security relay cleared. The final seal also needs both experimental relays.")


func _refresh_gates() -> void:
	for identity in gates:
		var opened: bool = identity in progress.completed
		if identity == "trial_final":
			opened = final_ready()
		gates[identity].visible = not opened
		gates[identity].get_child(0).set_deferred("disabled", opened)
	var crossing: bool = "crossing" in progress.completed
	bridge.visible = crossing
	bridge.get_node("CollisionShape2D").set_deferred("disabled", not crossing)


func restore(data: Dictionary) -> void:
	progress.restore(data)
	for machine in machines:
		machine.latched = machine.identity in progress.completed
		machine.reset()
	shard_marker.set_active(progress.shard)
	_refresh_gates()


func reset_experiments() -> void:
	for machine in machines:
		machine.reset()
	for enemy in enemies:
		enemy.reset_enemy()
		if not active:
			enemy.collision_layer = 0


func _draw() -> void:
	for index in range(6):
		var x: float = BOUNDARIES[index]
		ArtLibrary.prop(self, 28, Rect2(x + 80, 40, 190, 240), Color("7e9298"))
		ArtLibrary.prop(self, 16, Rect2(x + 18, 64, 32, 256), Color("9aa29c"))
		ArtLibrary.prop(self, 24, Rect2(x + 55, 210, 18, 40))
		ArtLibrary.prop(self, 23, Rect2(x + 300, 230, 28, 35))
		for xx in range(int(x + 360), int(BOUNDARIES[index + 1]), 192):
			ArtLibrary.prop(self, 18, Rect2(xx, 0, 8, 90), Color("6b7b80"))
			ArtLibrary.prop(self, 20, Rect2(xx + 45, 210, 64, 64), Color("697d80"))
	ArtLibrary.prop(self, 33 if progress.vector_unlocked else 32, Rect2(265, 267, 42, 53))
	ArtLibrary.prop(self, 41, Rect2(6900, 232, 86, 88))
	ArtLibrary.prop(self, 40, Rect2(48, 252, 55, 68))
	for identity in gates:
		if gates[identity].visible:
			var x: float = gates[identity].position.x
			for y in range(0, 320, 32):
				ArtLibrary.prop(self, 17, Rect2(x - 10, y, 20, 32))
			draw_line(Vector2(x, 28), Vector2(x, 316), Color("79ceb8"), 2)
