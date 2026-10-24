extends SceneTree
## State-to-picture contract. Storage is isolated; gameplay timelines remain authoritative.
const Checks = preload("res://tests/test_checks.gd")
var t := Checks.new()
var boot: Control
var player: CharacterBody2D
var visual: Node2D
var settings: Node
var impacts: Array[float] = []
var save_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	settings = root.get_node("Visuals")
	save_path = "res://artifacts/visual_save_" + str(Time.get_ticks_usec()) + ".json"
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	boot.validation_mode = true
	player = boot.room.player
	visual = player.get_node("Visual")
	for enemy in boot.room.enemies:
		enemy.set_physics_process(false)
	await _frames(30)
	await _air_contract()
	player.set_physics_process(false)
	_resources()
	_player_contract()
	_enemy_contract()
	_marker_contract()
	await _settings_contract()
	await _small_screen_contract()
	print("VISUAL PERFORMANCE: texture MiB=", snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.01), "; canvas draw calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	boot.queue_free()
	await process_frame
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.set_meta("save_path", save_path)
	root.add_child(boot)
	boot.validation_mode = true
	t.check(settings.quality == 2 and settings.reduced_motion and is_equal_approx(settings.shake_strength, 0.6), "visual preferences restore from the existing schema-1 save")
	t.check(boot.saves.load_save().save_schema_version == 1, "visual preferences do not migrate the save schema")
	boot.queue_free()
	await process_frame
	root.get_node("Controls").release_virtual()
	settings.impact_requested.disconnect(_record_impact)
	settings.configure({})
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	# Let queued node/audio/resource destruction finish before ending the SceneTree.
	boot = null
	player = null
	visual = null
	await create_timer(0.05).timeout
	quit(t.summary())


func _resources() -> void:
	var good: bool = true
	for identity in ["hero", "machines", "world"]:
		for index in range(64):
			var image: AtlasTexture = ArtLibrary.texture(identity, index)
			good = good and image.atlas != null and image.region.has_area() and image.filter_clip
	t.check(good, "all 192 measured atlas regions resolve to clipped original raster resources")
	for animation in ArtLibrary.HERO_ANIMATIONS:
		t.check(visual.sprite.sprite_frames.has_animation(animation) and visual.sprite.sprite_frames.get_frame_count(animation) >= 2, "Kael has complete raster frames: " + animation)
	t.check(ArtLibrary.sprite_frames("hero") == visual.sprite.sprite_frames, "actor frames share one cached immutable animation resource")
	t.check(visual.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE and visual.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "actor raster art inherits nearest filtering")
	t.check(player.get_node("CollisionShape2D").shape.size == Vector2(18, 28), "hero sprite replacement preserves the 18 by 28 collision body")
	t.check(boot.room.EXTENDED_PLATFORMS.size() == 13 and boot.room.WIDTH == 3328, "visual terrain retains every authored platform and sector extent")
	t.check(boot.theme.get_stylebox("panel", "PanelContainer").border_color == Color("80704e"), "HUD and menu use the shared iron and brass theme")


func _player_contract() -> void:
	visual.recovery_left = 0
	visual.landing_left = 0
	visual._process(0)
	t.check(visual.animation_name == "idle", "settled hero displays idle")
	player.velocity.x = 180
	visual._process(0)
	t.check(visual.animation_name == "run", "ground velocity selects run without changing movement")
	player.velocity = Vector2.ZERO
	for combo in range(3):
		player.combat.combo_left = 1
		player.combat.combo_index = combo - 1
		player.combat.request("light", 1)
		visual._process(0)
		t.check(visual.animation_name == "light_" + str(combo + 1) and visual.sprite.frame == 0, "light combo %d holds its anticipation during startup" % (combo + 1))
		var attack: AttackData = player.combat.attack
		player.combat.advance(attack.startup + 0.001)
		var before: Array = [player.position, player.velocity, player.combat.elapsed, player.health.current]
		visual._process(0.016)
		t.check(visual.sprite.frame == 1 and player.combat.phase() == "active", "light combo %d contact art begins with the active hit window" % (combo + 1))
		t.check(before == [player.position, player.velocity, player.combat.elapsed, player.health.current], "presentation cannot advance damage, motion or attack timers")
		player.facing = -1
		visual._process(0)
		t.check(not visual.sprite.flip_h, "swing facing remains locked to the authoritative attack direction")
		player.combat.advance(attack.active)
		visual._process(0)
		t.check(visual.sprite.frame == 3 and player.combat.phase() == "recovery", "recovery uses follow-through art after hit queries stop")
		player.combat.cancel()
	player.combat.request("heavy", -1)
	visual._process(0)
	t.check(visual.animation_name == "heavy" and visual.sprite.frame == 0 and visual.sprite.flip_h, "heavy windup has a distinct pose and correct left facing")
	player.combat.advance(player.combat.attack.startup + 0.001)
	visual._process(0)
	t.check(visual.sprite.frame == 1, "heavy contact pose follows its longer existing startup")
	player.combat.cancel()
	player.dodge.begin(-1)
	visual._process(0)
	t.check(visual.animation_name == "dodge" and visual.sprite.flip_h, "dodge animation uses the latched dodge direction")
	player.dodge.reset()
	player.hurt_left = 0.1
	visual._process(0)
	t.check(visual.animation_name == "hurt", "hurt response has priority over locomotion")
	player.hurt_left = 0
	player.health.current = 0
	player.death_left = 0.45
	visual._process(0)
	t.check(visual.animation_name == "death" and visual.sprite.frame >= 3, "death art follows the existing respawn countdown")
	player.reset_to(Vector2(128, 306))
	visual._process(0)
	t.check(visual.animation_name == "respawn", "checkpoint reset explicitly starts the recovery animation")
	visual.flash_left = 0.1
	visual._process(0)
	t.check(visual.material_flash.get_shader_parameter("hit_flash") > 0, "accepted damage can flash the raster sprite")
	visual._process(0.12)
	t.check(visual.material_flash.get_shader_parameter("hit_flash") == 0, "hit flash has a bounded lifetime")


func _air_contract() -> void:
	var seen: Dictionary = {}
	root.get_node("Controls").set_virtual_action("jump", "visual_test", true)
	for index in range(54):
		await _frames(1)
		seen[visual.animation_name] = true
		if index == 24:
			root.get_node("Controls").release_virtual()
	for animation in ["jump_start", "rise", "fall", "land"]:
		t.check(seen.has(animation), "real jump physics reaches the expected visual phase: " + animation)


func _enemy_contract() -> void:
	var crawler: CharacterBody2D = boot.room.enemies[0]
	var art: Node2D = crawler.get_node("Visual")
	for entry in [[1, "patrol"], [2, "alert"], [3, "chase"], [4, "attack"], [5, "hurt"], [6, "death"]]:
		crawler.state = entry[0]
		crawler.state_time = 0.01
		art._process(0)
		t.check(art.animation_name == entry[1], "crawler state has corresponding raster art: " + entry[1])
	crawler.reset_enemy()
	crawler.set_physics_process(false)
	crawler.receive_hit(1, crawler.position - Vector2(20, 0), 0)
	art._process(0)
	t.check(art.flash_left > 0 and art.animation_name == "hurt", "accepted enemy damage drives both the flash and recoil animation")
	var turret: CharacterBody2D = boot.room.enemies[1]
	art = turret.get_node("Visual")
	turret.state = 4
	turret.state_time = turret.profile.telegraph_seconds * 0.8
	turret.aim_direction = Vector2(-1, -0.2).normalized()
	art._process(0)
	t.check(art.barrel.visible and is_equal_approx(art.barrel.rotation, turret.aim_direction.angle()) and art.muzzle_left == 0, "turret charge tracks locked aim without showing an early muzzle flash")
	turret.shots_fired += 1
	art._process(0)
	t.check(art.muzzle_left > 0, "turret flash follows an actual spawned-shot counter")
	turret.reset_enemy()
	art.muzzle_left = 0
	art._process(0)
	t.check(art.muzzle_left == 0, "enemy reset cannot create a false firing flash")
	turret.health.current = 0
	turret.death_left = 0.2
	art._process(0)
	t.check(art.animation_name == "death" and not art.barrel.visible, "turret destruction replaces the base and hides the intact barrel")


func _marker_contract() -> void:
	var marker: Area2D = boot.room.relay
	var art: Node2D
	for child in marker.get_children():
		if child is Node2D and child.get_script() != null and child.get_script().resource_path.ends_with("marker_presentation.gd"):
			art = child
	marker.set_active(true)
	art._process(0)
	t.check(art.active and art.kind == 0, "relay presentation observes checkpoint activation")
	marker.set_active(false)
	art._process(0)
	t.check(not art.active, "inactive checkpoint presentation restores without changing its trigger")
	boot.room.relic.set_active(false)
	t.check(boot.room.relic.visible and boot.room.relic.get_child_count() == 2, "uncollected shard has one raster visual and one unchanged trigger")
	boot.room.relic.set_active(true)
	t.check(not boot.room.relic.visible, "collected shard hides its visual with the existing one-time pickup state")


func _settings_contract() -> void:
	settings.impact_requested.connect(_record_impact)
	settings.configure({"effects_quality": 99, "camera_shake": 3})
	t.check(settings.quality == 2 and settings.shake_strength == 1, "quality and shake settings clamp unsupported saved values")
	settings.reduced_motion = true
	settings.impact(2)
	t.check(impacts.is_empty(), "reduced motion suppresses camera impulses")
	settings.reduced_motion = false
	settings.impact(2)
	t.check(impacts.size() == 1 and impacts[0] == 2, "optional shake receives only a bounded presentation impulse")
	settings.quality = 0
	await _frames(2)
	var scene: Node2D
	for child in boot.room.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("citadel_presentation.gd"):
			scene = child
	var disabled: bool = true
	for light in scene.lights:
		disabled = disabled and not light.enabled and not light.shadow_enabled
	t.check(disabled, "reduced effects disable every dynamic light and no preset uses shadows")
	t.check(scene.get_node("DistantVault").ratio < scene.get_node("MidgroundArchitecture").ratio, "far and middle architecture move at separate parallax depths")
	var camera: Camera2D = player.get_node("Camera2D")
	player.reset_to(Vector2(760.25, 306.25))
	t.check(camera.global_position == camera.global_position.round() and camera.offset == Vector2.ZERO, "checkpoint camera reset snaps to whole pixels and clears shake")
	settings.quality = 2
	settings.reduced_motion = true
	settings.shake_strength = 0.6
	boot._persist("Visual test settings.")
	t.check(boot.saves.load_save().control_preferences.effects_quality == 2, "visual options persist through the existing save repository")


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func _small_screen_contract() -> void:
	var original_size: Vector2i = root.size
	var original_scale: Vector2i = root.content_scale_size
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	await _frames(3)
	var rectangle: Rect2 = boot.combat_label.get_global_rect()
	t.check(rectangle.end.x <= 936 and rectangle.position.x >= 24, "ability status wraps inside the 960 by 540 landscape HUD")
	root.size = original_size
	root.content_scale_size = original_scale
	await _frames(3)


func _record_impact(value: float) -> void:
	impacts.append(value)
