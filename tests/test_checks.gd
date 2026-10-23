extends RefCounted
var passed: int = 0
var failed: int = 0


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)


func near(actual: float, expected: float, tolerance: float, label: String) -> void:
	check(is_finite(actual) and absf(actual - expected) <= tolerance,
		"%s (got %.10f; expected %.10f +/- %.10f)" % [label, actual, expected, tolerance])


func summary() -> int:
	print("RESULT: %d passed, %d failed" % [passed, failed])
	return 0 if failed == 0 else 1
