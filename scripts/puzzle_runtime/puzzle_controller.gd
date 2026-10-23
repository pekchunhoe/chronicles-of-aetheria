class_name PuzzleController
extends RefCounted
## Declarative acceptance bounds; does not execute expressions from content.

const Model = preload("res://scripts/physics_models/physics_model.gd")
signal evaluated(result: Dictionary)
var definition: Dictionary = {}
var solved: bool = false


func load_definition(path: String) -> bool:
	definition.clear()
	solved = false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema_version") != 1:
		return false
	if not data.get("puzzle_id") is String or not data.get("inputs_si") is Dictionary:
		return false
	if not data.get("acceptance") is Dictionary or not data.get("model_id") is String:
		return false
	var acceptance: Dictionary = data.acceptance
	if not acceptance.get("quantity") is String or not acceptance.get("unit") is String:
		return false
	for field in ["target", "absolute_tolerance"]:
		var number: Variant = acceptance.get(field)
		if not (number is float or number is int) or not is_finite(float(number)):
			return false
	if float(acceptance.absolute_tolerance) < 0.0:
		return false
	var preview: Dictionary = Model.evaluate(data.model_id, data.inputs_si)
	if not preview.ok or preview.units.get(acceptance.quantity) != acceptance.unit:
		return false
	definition = data.duplicate(true)
	return true


func try_inputs(inputs_si: Dictionary) -> Dictionary:
	if definition.is_empty():
		return {"ok": false, "error": "No valid puzzle loaded."}
	var result: Dictionary = Model.evaluate(definition.model_id, inputs_si)
	if result.ok:
		var rule: Dictionary = definition.acceptance
		var observed: float = result.values[rule.quantity]
		result["success"] = absf(observed - float(rule.target)) <= float(rule.absolute_tolerance)
		result["acceptance"] = rule.duplicate(true)
		result["puzzle_id"] = definition.puzzle_id
		solved = solved or result.success
	result["solved"] = solved
	evaluated.emit(result)
	return result
