class_name PhysicsModel
extends RefCounted
## Audited, scene-independent SI mathematics. No platformer or collision state.
## Positive directions: projectile right/up; ramp down the plane; fall down.

const G_M_PER_S2: float = 9.81
const WORLD_PIXELS_PER_METRE: float = 64.0


static func evaluate(model_id: String, inputs: Dictionary) -> Dictionary:
	match model_id:
		"ideal_projectile_v1":
			return _projectile(inputs)
		"sliding_ramp_v1":
			return _ramp(inputs)
		"ideal_fall_v1":
			return _fall(inputs)
		"ohms_law_v1":
			return _circuit(inputs)
	return _failure("Unknown model_id: " + model_id)


static func metres_to_pixels(metres: float) -> float:
	return metres * WORLD_PIXELS_PER_METRE


static func pixels_to_metres(pixels: float) -> float:
	return pixels / WORLD_PIXELS_PER_METRE


static func _valid_numbers(inputs: Dictionary, keys: Array) -> bool:
	for key in keys:
		var value: Variant = inputs.get(key)
		if not (value is float or value is int):
			return false
		if not is_finite(float(value)):
			return false
	return true


static func _projectile(inputs: Dictionary) -> Dictionary:
	if not _valid_numbers(inputs, ["u_m_per_s", "theta_deg"]):
		return _failure("Projectile requires finite u_m_per_s and theta_deg.")
	var speed: float = inputs.u_m_per_s
	var angle_deg: float = inputs.theta_deg
	if speed < 0.0 or angle_deg < 0.0 or angle_deg > 90.0:
		return _failure("Require speed >= 0 m/s and angle in [0, 90] degrees.")
	var angle: float = deg_to_rad(angle_deg)
	return _success("ideal_projectile_v1", {
		"range_m": speed * speed * sin(2.0 * angle) / G_M_PER_S2,
		"flight_time_s": 2.0 * speed * sin(angle) / G_M_PER_S2,
	}, {"range_m": "m", "flight_time_s": "s"}, [
		"Same launch and landing height", "Uniform g = 9.81 m/s^2", "Negligible air drag",
	])


static func _ramp(inputs: Dictionary) -> Dictionary:
	if not _valid_numbers(inputs, ["theta_deg", "mu_k"]):
		return _failure("Ramp requires finite theta_deg and dimensionless mu_k.")
	var angle_deg: float = inputs.theta_deg
	var friction: float = inputs.mu_k
	if angle_deg < 0.0 or angle_deg > 90.0 or friction < 0.0:
		return _failure("Require angle in [0, 90] degrees and mu_k >= 0.")
	var angle: float = deg_to_rad(angle_deg)
	return _success("sliding_ramp_v1", {
		"acceleration_m_per_s2": G_M_PER_S2 * (sin(angle) - friction * cos(angle)),
	}, {"acceleration_m_per_s2": "m/s^2"}, [
		"Object already sliding DOWN the plane; positive down the plane",
		"Constant kinetic friction; no air drag; uniform g = 9.81 m/s^2",
		"Negative acceleration means slowing; this model does not decide static friction or reversal",
	])


static func _fall(inputs: Dictionary) -> Dictionary:
	if not _valid_numbers(inputs, ["height_m"]):
		return _failure("Fall requires finite height_m.")
	var height: float = inputs.height_m
	if height < 0.0:
		return _failure("Require height_m >= 0 m.")
	return _success("ideal_fall_v1", {
		"speed_m_per_s": sqrt(2.0 * G_M_PER_S2 * height),
	}, {"speed_m_per_s": "m/s"}, [
		"Initially at rest", "Loss of gravitational potential energy becomes kinetic energy",
		"Negligible drag and dissipation; uniform g = 9.81 m/s^2",
	])


static func _circuit(inputs: Dictionary) -> Dictionary:
	if not _valid_numbers(inputs, ["voltage_v", "resistance_ohm"]):
		return _failure("Circuit requires finite voltage_v and resistance_ohm.")
	var voltage: float = inputs.voltage_v
	var resistance: float = inputs.resistance_ohm
	if resistance <= 0.0:
		return _failure("Resistance must be > 0 ohm; ideal short circuit is outside this model.")
	return _success("ohms_law_v1", {"current_a": voltage / resistance}, {
		"current_a": "A",
	}, ["Steady DC", "Ideal regulated source and ohmic equivalent load", "Positive current follows positive voltage"])


static func _success(model_id: String, values: Dictionary, units: Dictionary, assumptions: Array) -> Dictionary:
	for value in values.values():
		if not is_finite(float(value)):
			return _failure("Inputs overflow the finite numerical range.")
	return {"ok": true, "model_id": model_id, "values": values, "units": units,
		"assumptions": assumptions, "g_m_per_s2": G_M_PER_S2}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
