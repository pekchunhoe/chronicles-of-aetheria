class_name GauntletScanner
extends RefCounted
## Read-only presentation of evaluated, unit-tagged state. Never guesses measurements.


func describe(result: Dictionary) -> String:
	if not result.get("ok", false):
		return "Model unavailable: " + str(result.get("error", "Unknown error"))
	var lines: PackedStringArray = ["MODEL BENCH / idealized numerical preview"]
	var values: Dictionary = result.get("values", {})
	var units: Dictionary = result.get("units", {})
	for quantity in values:
		lines.append("%s = %.3f %s" % [quantity.replace("_", " "), values[quantity], units.get(quantity, "")])
	if result.has("acceptance"):
		var rule: Dictionary = result.acceptance
		lines.append("Target %.2f +/- %.2f %s / %s" % [rule.target, rule.absolute_tolerance,
			rule.unit, "within bounds" if result.get("success", false) else "try again"])
	lines.append("Assumptions: " + "; ".join(result.get("assumptions", [])))
	return "\n".join(lines)
