extends Node
## Presentation-only settings, stored inside the existing schema-1 preferences.
signal changed
signal impact_requested(amount: float)
var quality: int = 1
var reduced_motion: bool = false
var shake_strength: float = 0.25


func configure(preferences: Dictionary) -> void:
	var conservative: bool = OS.has_feature("web") or OS.has_feature("android") or OS.has_feature("ios")
	quality = clampi(int(preferences.get("effects_quality", 0 if conservative else 1)), 0, 2)
	reduced_motion = bool(preferences.get("reduced_motion", false))
	shake_strength = clampf(float(preferences.get("camera_shake", 0.0 if conservative else 0.25)), 0.0, 1.0)
	changed.emit()


func snapshot(preferences: Dictionary) -> void:
	preferences.effects_quality = quality
	preferences.reduced_motion = reduced_motion
	preferences.camera_shake = shake_strength


func impact(strength: float) -> void:
	if not reduced_motion and shake_strength > 0.0:
		impact_requested.emit(clampf(strength * shake_strength, 0.0, 3.0))
