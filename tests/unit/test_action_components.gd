extends RefCounted
const Health = preload("res://scripts/combat/health_component.gd")
const Dodge = preload("res://scripts/player/dodge_controller.gd")
const Saves = preload("res://scripts/core/save_repository.gd")


func run(t: RefCounted) -> void:
	t.check(ProjectSettings.get_setting("application/config/name") == "Chronicles of Aetheria — Phase 0", "application identity preserves existing default user save directory")
	var health := Health.new()
	health.maximum = 80
	health.restore()
	t.check(health.current == 80, "shared health restores configurable maximum")
	t.check(not health.take_damage(-5) and health.current == 80, "negative damage cannot heal")
	t.check(health.take_damage(20) and health.current == 60, "health accepts damage once")
	t.check(not health.take_damage(20) and health.current == 60, "damage immunity blocks repeated hits")
	health._physics_process(0.71)
	t.check(health.take_damage(10) and health.current == 50, "damage immunity expires")
	health.heal(1000)
	t.check(health.current == 80, "healing clamps to maximum")
	health.immunity_left = 0.0
	health.guarded = true
	t.check(not health.take_damage(20), "external guard prevents damage")
	health.guarded = false
	t.check(health.take_damage(999) and health.current == 0, "lethal damage clamps at zero")
	health.heal(20)
	t.check(health.current == 0 and not health.take_damage(1), "dead health cannot heal or die repeatedly")
	health.restore()
	t.check(health.current == 80 and not health.guarded and health.immunity_left == 0.0, "respawn clears health timers and guard")
	health.free()
	var dodge := Dodge.new()
	t.check(dodge.begin(-1.0) and dodge.direction == -1.0 and dodge.invulnerable(), "dodge starts in requested direction with early immunity")
	t.check(not dodge.begin(1.0), "dodge cannot restart during travel")
	dodge.advance(0.13)
	t.check(dodge.active() and not dodge.invulnerable(), "late dodge travel is vulnerable")
	dodge.advance(0.06)
	t.check(dodge.running and not dodge.active(), "dodge enters explicit recovery")
	dodge.advance(0.14)
	t.check(not dodge.running and not dodge.begin(1), "cooldown survives the end of recovery")
	dodge.advance(0.5)
	t.check(dodge.begin(1), "dodge becomes available after cooldown")
	dodge.reset()
	t.check(not dodge.running and dodge.cooldown_left == 0.0, "respawn resets dodge state")
	dodge.free()
	var light: Resource = load("res://content/combat/light_1.tres")
	var heavy: Resource = load("res://content/combat/heavy.tres")
	t.check(heavy.damage > light.damage and heavy.startup > light.startup and heavy.recovery > light.recovery, "weapon data makes heavy attacks stronger and slower")
	t.check(light.active > 0 and heavy.active > 0 and heavy.knockback > light.knockback, "both moves have finite active windows and distinct knockback")
	var path: String = "res://artifacts/legacy_action_" + str(Time.get_ticks_usec()) + ".json"
	var saves := Saves.new(path)
	var legacy: Dictionary = saves.defaults()
	legacy.content_version = "phase0.1"
	legacy.checkpoint_id = "east_checkpoint"
	legacy.control_preferences.bindings = {"jump": [KEY_J]}
	t.check(saves.save(legacy) == OK, "Phase 0 schema-1 fixture saves without migration")
	var loaded: Dictionary = saves.load_save()
	t.check(loaded.content_version == "phase0.1" and loaded.checkpoint_id == "east_checkpoint", "Phase 0 checkpoint and content version load losslessly")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
