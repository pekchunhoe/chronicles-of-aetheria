extends SceneTree
## Audits locally installed candidate fonts without importing or modifying them.
func _initialize() -> void:
	var characters: String = "θμΔ²ₛₖₚₙₑₜₐᵥₓᵧ⁻¹Σ√≤≥∥λ°½−×₀₁₂↓"
	var paths: PackedStringArray = OS.get_cmdline_user_args()
	if paths.is_empty(): paths = PackedStringArray(["res://assets/fonts/DejaVuSans.ttf"])
	for path in paths:
		if not FileAccess.file_exists(path):
			printerr("Missing font: ", path)
			quit(1)
			return
		var font := FontFile.new()
		font.data = FileAccess.get_file_as_bytes(path)
		var missing: String = ""
		for character in characters:
			if not TextServerManager.get_primary_interface().font_has_char(font.get_rids()[0], character.unicode_at(0)):
				missing += character
		print("FONT AUDIT: ", path, " missing=[", missing, "] bytes=", font.data.size())
	quit()
