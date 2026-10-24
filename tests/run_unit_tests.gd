extends SceneTree
const Checks = preload("res://tests/test_checks.gd")
const PhysicsTests = preload("res://tests/unit/test_physics.gd")
const RepositoryTests = preload("res://tests/unit/test_repositories.gd")
const SafeArea = preload("res://scripts/platform/safe_area.gd")
const ActionTests = preload("res://tests/unit/test_action_components.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t := Checks.new()
	PhysicsTests.new().run(t)
	RepositoryTests.new().run(t)
	ActionTests.new().run(t)
	preload("res://tests/unit/test_mechanics.gd").new().run(t)
	var insets: Vector4 = SafeArea.calculate_insets(Rect2(0, 0, 1280, 720), Rect2(48, 20, 1200, 680))
	t.check(insets == Vector4(48, 20, 32, 20), "safe area accounts for asymmetric landscape insets")
	t.check(SafeArea.calculate_insets(Rect2(0, 0, 640, 360), Rect2()) == Vector4.ZERO, "invalid safe area falls back without hiding controls")
	quit(t.summary())
