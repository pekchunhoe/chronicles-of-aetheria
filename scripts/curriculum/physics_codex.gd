class_name PhysicsCodex
extends RefCounted
var entries: Array = []
var metadata: Dictionary = {}


func load_entries() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/journal/research_codex.json"))
	if not parsed is Dictionary or not parsed.get("entries") is Array:
		return false
	metadata = parsed
	entries = parsed.entries
	return entries.size() == 9


func text_for(entry: Dictionary) -> String:
	return "[b]%s[/b]\n\n%s\n\n[color=#83dfc4]%s[/color]\n\n[b]Symbols and SI units[/b]\n%s\n\n[b]Conditions[/b]\n%s\n\n[b]Worked example[/b]\n%s\n\n[b]Discovery[/b]\n%s\n\nSemester 1 · Official curriculum mapping unverified.\nSemester 2 remains a separate permanent semester identity." % [entry.title, entry.explanation, entry.equations, entry.symbols, entry.assumptions, entry.example, entry.discovery]
