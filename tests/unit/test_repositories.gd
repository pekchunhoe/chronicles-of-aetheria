extends RefCounted
const Saves = preload("res://scripts/core/save_repository.gd")
const Concepts = preload("res://scripts/curriculum/concept_repository.gd")
const Puzzle = preload("res://scripts/puzzle_runtime/puzzle_controller.gd")
const Scanner = preload("res://scripts/player/gauntlet_scanner.gd")
const CONCEPT: String = "physics.mechanics.linear_motion.projectile_range"


func run(t: RefCounted) -> void:
	var concepts := Concepts.new()
	t.check(concepts.load_content(), "offline concept/curriculum data load and cross-reference")
	t.check(concepts.get_concept(CONCEPT).model_id == "ideal_projectile_v1", "stable concept resolves model")
	var mapping: Array[Dictionary] = concepts.mappings_for(CONCEPT, "foundation_example_v1")
	t.check(mapping.size() == 1 and mapping[0].semester == "Semester 1", "fixed Semester 1 display identity")
	t.check(concepts.curricula.foundation_example_v1.semesters[1].display_name == "Semester 2", "fixed Semester 2 display identity")
	concepts.curricula.foundation_example_v1.semesters[0].syllabus_code = "REPLACEMENT_CODE"
	t.check(concepts.mappings_for(CONCEPT, "foundation_example_v1")[0].syllabus_code == "REPLACEMENT_CODE", "syllabus code is replaceable without changing concept")
	t.check(concepts.curricula.foundation_example_v1.semesters[1].topics.is_empty(), "no fixed topic count (empty semester allowed)")
	t.check(concepts.get_concept("missing").is_empty(), "missing concept is explicit")
	var puzzle := Puzzle.new()
	t.check(puzzle.load_definition("res://content/puzzles/projectile_bench.json"), "data-driven puzzle validates units and bounds")
	var result: Dictionary = puzzle.try_inputs({"u_m_per_s": 14.0, "theta_deg": 45.0})
	t.check(result.ok and result.success, "19.9796 m lies within 20.0 +/- 0.10 m")
	var retry: Dictionary = puzzle.try_inputs({"u_m_per_s": 1.0, "theta_deg": 45.0})
	t.check(retry.ok and not retry.success and retry.solved, "failed retry preserves existing solve")
	t.check(not puzzle.try_inputs({}).ok, "invalid puzzle inputs rejected")
	var text: String = Scanner.new().describe(result)
	t.check(text.contains("19.980 m") and text.contains("Assumptions:"), "scanner displays evaluated SI values and assumptions")
	var filename: String = "res://artifacts/unit_save_" + str(Time.get_ticks_usec()) + ".json"
	var saves := Saves.new(filename)
	var data: Dictionary = saves.load_save()
	t.check(data.save_schema_version == 1 and data.checkpoint_id == "room_start", "new save has versioned defaults")
	t.check(saves.save(data) == OK, "atomic initial save")
	data.checkpoint_id = "east_checkpoint"
	data.discoveries = [CONCEPT]
	t.check(saves.save(data) == OK, "atomic overwrite with backup")
	t.check(saves.load_save().checkpoint_id == "east_checkpoint", "checkpoint survives reload")
	t.check(saves.load_save().discoveries == [CONCEPT], "discoveries use stable concept IDs")
	_write(filename, "{broken")
	var recovered: Dictionary = saves.load_save()
	t.check(saves.recovered_from_backup and recovered.checkpoint_id == "room_start", "corrupt primary recovers last valid backup")
	t.check(saves.save(recovered) == OK, "recovered data can replace corrupt primary")
	t.check(saves.save({}) == ERR_INVALID_DATA, "refuse structurally invalid save")
	var future: Dictionary = saves.defaults()
	future.save_schema_version = 99
	_write(filename, JSON.stringify(future))
	t.check(saves.load_save().is_empty() and saves.last_error.begins_with("Unsupported save schema"), "future schema preserved for migration")
	t.check(saves.save(data) == ERR_UNAVAILABLE, "refuse overwriting future-schema save")
	for suffix in ["", ".bak", ".tmp"]:
		var absolute: String = ProjectSettings.globalize_path(filename + suffix)
		if FileAccess.file_exists(filename + suffix):
			DirAccess.remove_absolute(absolute)


func _write(filename: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(text)
	file.close()
