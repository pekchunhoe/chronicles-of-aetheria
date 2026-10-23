extends RefCounted
const Model = preload("res://scripts/physics_models/physics_model.gd")


func run(t: RefCounted) -> void:
	# Rounded published fixtures: absolute tolerance 0.005 in the named SI unit.
	# Additional unrounded references were independently calculated with Python math.
	# Projectile: level landing, constant downward g, no drag; right/up positive.
	var projectile: Dictionary = Model.evaluate("ideal_projectile_v1", {"u_m_per_s": 14.0, "theta_deg": 45.0})
	t.check(projectile.ok, "projectile accepts SI input")
	t.near(projectile.values.range_m, 19.98, 0.005, "projectile 14 m/s at 45 deg: range [m]")
	t.near(projectile.values.range_m, 19.9796126401631, 1e-10, "projectile unrounded independent reference [m]")
	t.near(projectile.values.flight_time_s, 2.0182456547628265, 1e-12, "projectile flight time [s]")
	t.check(projectile.units.range_m == "m" and projectile.units.flight_time_s == "s", "projectile unit metadata")
	# Ramp: already sliding down, kinetic friction only; positive down plane.
	var ramp: Dictionary = Model.evaluate("sliding_ramp_v1", {"theta_deg": 30.0, "mu_k": 0.20})
	t.near(ramp.values.acceleration_m_per_s2, 3.21, 0.005, "30 deg ramp, mu_k 0.20: acceleration [m/s^2]")
	t.near(ramp.values.acceleration_m_per_s2, 3.205858157775, 1e-10, "ramp unrounded independent reference [m/s^2]")
	t.check(ramp.units.acceleration_m_per_s2 == "m/s^2", "ramp unit metadata")
	# Ideal energy conversion: start at rest, zero losses, g = 9.81 m/s^2.
	var falling: Dictionary = Model.evaluate("ideal_fall_v1", {"height_m": 2.0})
	t.near(falling.values.speed_m_per_s, 6.26, 0.005, "2 m ideal fall: speed [m/s]")
	t.near(falling.values.speed_m_per_s, 6.26418390534633, 1e-10, "fall unrounded independent reference [m/s]")
	t.near(0.5 * pow(falling.values.speed_m_per_s, 2), 19.62, 1e-10, "specific energy conserved [J/kg]")
	# Steady DC, ideal source, ohmic load; reference-current direction follows voltage.
	var circuit: Dictionary = Model.evaluate("ohms_law_v1", {"voltage_v": 12.0, "resistance_ohm": 6.0})
	t.near(circuit.values.current_a, 2.0, 1e-12, "12 V across 6 ohm: current [A]")
	t.check(circuit.units.current_a == "A", "circuit unit metadata")
	for fixture in [projectile, ramp, falling, circuit]:
		t.check(not fixture.assumptions.is_empty() and fixture.g_m_per_s2 == 9.81, "explicit assumptions and g")
	t.check(not Model.evaluate("ohms_law_v1", {"voltage_v": 12, "resistance_ohm": 0}).ok, "reject zero resistance")
	t.check(not Model.evaluate("ideal_fall_v1", {"height_m": -1}).ok, "reject negative drop height")
	t.check(not Model.evaluate("ideal_projectile_v1", {"u_m_per_s": 14, "theta_deg": 91}).ok, "reject unsupported launch angle")
	t.check(not Model.evaluate("sliding_ramp_v1", {"theta_deg": 30, "mu_k": -0.2}).ok, "reject negative friction")
	t.check(not Model.evaluate("ideal_fall_v1", {"height_m": "2"}).ok, "reject string masquerading as SI value")
	t.check(not Model.evaluate("ideal_fall_v1", {"height_m": INF}).ok, "reject infinity")
	t.check(not Model.evaluate("ideal_fall_v1", {"height_m": NAN}).ok, "reject NaN")
	t.check(not Model.evaluate("not_a_model", {}).ok, "reject unknown model ID")
	var slowing: Dictionary = Model.evaluate("sliding_ramp_v1", {"theta_deg": 0, "mu_k": 0.20})
	t.near(slowing.values.acceleration_m_per_s2, -1.962, 1e-12, "sliding horizontal object decelerates; no false static solution")
	t.near(Model.metres_to_pixels(20), 1280, 1e-10, "20 m puzzle world distance is 1280 px")
	t.near(Model.pixels_to_metres(Model.metres_to_pixels(3.2)), 3.2, 1e-12, "SI/world scale round trip")
