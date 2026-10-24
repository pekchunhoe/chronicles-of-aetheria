class_name ResearchProgress
extends RefCounted
## Stable story IDs; only apparatus collision signals can latch experimental relays.
const ROOT: String = "citadel.research."
var completed: Array[String] = []
var discoveries: Array[String] = []
var scholar_completed: Array[String] = []
var vector_unlocked: bool = false
var impulse_unlocked: bool = false
var shard: bool = false
var trial_enemy_defeated: bool = false


func record_contact(identity: String, accepted: bool) -> bool:
	if not accepted or identity in completed:
		return false
	completed.append(identity)
	return true


func discover(ids: Array) -> void:
	for identity in ids:
		if str(identity) not in discoveries:
			discoveries.append(str(identity))


func restore(data: Dictionary) -> void:
	var saved: Variant = data.get("puzzle_state", {}).get(ROOT + "progress", {})
	if not saved is Dictionary:
		saved = {}
	for key in ["completed", "scholar_completed"]:
		var values: Variant = saved.get(key, [])
		if values is Array:
			for value in values:
				if value is String and value not in get(key):
					get(key).append(value)
	for identity in data.get("discoveries", []):
		if identity is String and identity.begins_with("mechanics.") and identity not in discoveries:
			discoveries.append(identity)
	vector_unlocked = ROOT + "vector_sight" in data.get("unlocks", [])
	impulse_unlocked = ROOT + "impulse_strike" in data.get("unlocks", [])
	shard = ROOT + "axiom_shard" in data.get("collected_crystals", [])
	trial_enemy_defeated = bool(saved.get("trial_enemy_defeated", false))


func snapshot(data: Dictionary) -> void:
	data.puzzle_state[ROOT + "progress"] = {"completed": completed.duplicate(), "scholar_completed": scholar_completed.duplicate(), "trial_enemy_defeated": trial_enemy_defeated}
	for entry in [[vector_unlocked, "vector_sight"], [impulse_unlocked, "impulse_strike"]]:
		if entry[0] and ROOT + entry[1] not in data.unlocks:
			data.unlocks.append(ROOT + entry[1])
	if shard and ROOT + "axiom_shard" not in data.collected_crystals:
		data.collected_crystals.append(ROOT + "axiom_shard")
	for identity in discoveries:
		if identity not in data.discoveries:
			data.discoveries.append(identity)
