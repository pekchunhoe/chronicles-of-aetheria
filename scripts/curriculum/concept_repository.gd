class_name ConceptRepository
extends RefCounted
## Offline metadata only. Curriculum codes never form save-file identities.

const SEMESTERS: Array[String] = ["Semester 1", "Semester 2"]
var concepts: Dictionary = {}
var curricula: Dictionary = {}
var errors: Array[String] = []


func load_content() -> bool:
	concepts.clear()
	curricula.clear()
	errors.clear()
	for folder in ["res://content/concepts", "res://content/curricula"]:
		for filename in DirAccess.get_files_at(folder):
			if filename.get_extension() != "json":
				continue
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join(filename)))
			if not data is Dictionary:
				errors.append("Invalid JSON object: " + filename)
				continue
			var key: String = "concept_id" if folder.ends_with("concepts") else "version"
			if not data.get(key) is String or str(data.get(key, "")).is_empty():
				errors.append("Missing identity: " + filename)
				continue
			var target: Dictionary = concepts if key == "concept_id" else curricula
			if target.has(data[key]):
				errors.append("Duplicate identity: " + str(data[key]))
				continue
			target[data[key]] = data
	for curriculum in curricula.values():
		if not curriculum.get("semesters") is Array:
			errors.append("Curriculum semesters must be an array.")
			continue
		var seen: Array = []
		for semester in curriculum.semesters:
			if not semester is Dictionary or not semester.get("display_name") in SEMESTERS:
				errors.append("Unknown semester display identity.")
				continue
			if semester.display_name in seen:
				errors.append("Duplicate semester display identity.")
			seen.append(semester.display_name)
			if not semester.get("topics") is Array:
				errors.append("Topics must be a dynamic array.")
				continue
			for topic in semester.topics:
				for concept_id in topic.get("concept_ids", []):
					if not concepts.has(concept_id):
						errors.append("Unknown mapped concept: " + str(concept_id))
		if seen.size() != SEMESTERS.size():
			errors.append("Both fixed semester identities are required.")
	return errors.is_empty() and not concepts.is_empty() and not curricula.is_empty()


func get_concept(concept_id: String) -> Dictionary:
	return concepts.get(concept_id, {}).duplicate(true)


func mappings_for(concept_id: String, version: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var curriculum: Dictionary = curricula.get(version, {})
	for semester in curriculum.get("semesters", []):
		for topic in semester.get("topics", []):
			if concept_id in topic.get("concept_ids", []):
				matches.append({"version": version, "semester": semester.display_name,
					"syllabus_code": semester.get("syllabus_code", ""), "topic_id": topic.topic_id,
					"alignment_status": curriculum.get("alignment_status", "unverified")})
	return matches
