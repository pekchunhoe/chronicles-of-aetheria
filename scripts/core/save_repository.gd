class_name SaveRepository
extends RefCounted
## Versioned offline data. Same-directory temp + atomic rename; last valid backup.
## Unsupported future versions are preserved, never silently replaced.

const SCHEMA_VERSION: int = 1
const CONTENT_VERSION: String = "phase1.0"
const MAX_SAVE_BYTES: int = 1048576
var path: String
var last_error: String = ""
var recovered_from_backup: bool = false


func _init(save_path: String = "user://save_v1.json") -> void:
	path = save_path


func defaults() -> Dictionary:
	return {"save_schema_version": SCHEMA_VERSION, "content_version": CONTENT_VERSION,
		"checkpoint_id": "room_start", "unlocks": [], "collected_crystals": [], "equipment": {},
		"puzzle_state": {}, "discoveries": [], "mode_choices": {"learning": "Adventure"},
		"control_preferences": {"bindings": {}, "touch_visible": false, "touch_scale": 1.0, "touch_opacity": 0.8}}


func load_save() -> Dictionary:
	last_error = ""
	recovered_from_backup = false
	var primary: Dictionary = _read_valid(path)
	if not primary.is_empty():
		return primary
	# Do not downgrade a save from a future version, even if an older backup exists.
	if last_error.begins_with("Unsupported save schema"):
		return {}
	var backup: Dictionary = _read_valid(path + ".bak")
	if not backup.is_empty():
		recovered_from_backup = true
		last_error = "Recovered last valid backup."
		return backup
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		last_error = "Save and backup could not be read; existing files preserved."
		return {}
	last_error = ""
	return defaults()


func save(data: Dictionary) -> Error:
	last_error = ""
	if not _is_valid(data):
		last_error = "Refused invalid save data."
		return ERR_INVALID_DATA
	# Protect a future primary version from being overwritten by this engine content.
	var previous: Dictionary = _read_valid(path)
	if last_error.begins_with("Unsupported save schema"):
		return ERR_UNAVAILABLE
	last_error = ""
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Cannot open save temporary file."
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Writing save failed."
		return write_error
	if not previous.is_empty():
		var backup_error: Error = DirAccess.copy_absolute(
			ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
		if backup_error != OK:
			last_error = "Cannot preserve previous valid save as backup."
			return backup_error
	var replace_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if replace_error != OK:
		last_error = "Atomic save replacement failed; previous save/backup preserved."
	return replace_error


func _read_valid(filename: String) -> Dictionary:
	if not FileAccess.file_exists(filename):
		return {}
	var file: FileAccess = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return {}
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	if parsed.get("save_schema_version", 0) != SCHEMA_VERSION:
		last_error = "Unsupported save schema; migration is required."
		return {}
	return parsed if _is_valid(parsed) else {}


func _is_valid(data: Dictionary) -> bool:
	if data.get("save_schema_version") != SCHEMA_VERSION or not data.get("content_version") is String:
		return false
	if not data.get("checkpoint_id") is String:
		return false
	for key in ["unlocks", "collected_crystals", "discoveries"]:
		if not data.get(key) is Array:
			return false
	for key in ["equipment", "puzzle_state", "mode_choices", "control_preferences"]:
		if not data.get(key) is Dictionary:
			return false
	return true
