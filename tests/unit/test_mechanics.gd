extends RefCounted


func run(t: RefCounted) -> void:
	var f: Dictionary = MechanicsModel.incline(10, 30, 0.4, 0.2)
	t.near(f.weight_n, 98.1, 1e-10, "weight mg [N]")
	t.near(f.normal_n, 84.9570921113, 1e-9, "normal reaction [N]")
	t.near(f.parallel_n, 49.05, 1e-10, "downslope gravitational component [N]")
	t.near(f.friction_n, -16.9914184223, 1e-9, "kinetic friction opposes downhill motion [N]")
	t.near(f.a, 3.21, 0.005, "required incline acceleration benchmark [m s^-2]")
	t.check(not f.static, "30 degree release exceeds static threshold")
	var resting: Dictionary = MechanicsModel.incline(10, 15, 0.4, 0.2)
	t.check(resting.static, "15 degree cargo stays at rest")
	t.near(resting.friction_n, -25.3901483246, 1e-9, "static friction adjusts below its maximum")
	t.near(resting.net_n, 0, 1e-10, "balanced static net force")
	t.near(MechanicsModel.incline(10, 0, 0.4, 0.2).friction_n, 0, 1e-10, "level stationary cargo has no phantom friction")
	t.check(MechanicsModel.incline(10, rad_to_deg(atan(0.4)), 0.4, 0.2).static, "limiting static equality remains at rest")
	t.check(MechanicsModel.incline(10, 30, 0.4, 0.2, -2).friction_n > 0, "uphill cargo friction acts downhill")
	t.near(MechanicsModel.incline(10, 90, 0.4, 0.2).a, 9.81, 1e-10, "vertical limiting guide has zero normal force")
	var p: Dictionary = {"mass": 10.0, "angle": 15.0, "mu_s": 0.4, "mu_k": 0.2, "g": 9.81}
	var stopped: Dictionary = MechanicsModel.incline_step(0, -0.1, 1, p)
	t.near(stopped.v, 0, 1e-10, "uphill stop becomes static without overshoot")
	t.check(stopped.s < 0, "uphill travel before stopping retains signed displacement")
	p.angle = 30.0
	t.check(MechanicsModel.incline_step(0, -0.1, 1, p).v > 0, "steep guide reverses uphill motion after stopping")
	for rate in [30, 60, 120]:
		var s: float = 0
		var v: float = 0
		for index in range(rate):
			var next: Dictionary = MechanicsModel.incline_step(s, v, 1.0 / rate, p)
			s = next.s
			v = next.v
		t.near(s, 1.602929078887, 1e-10, "exact incline displacement independent of timestep at %d Hz" % rate)
		t.near(v, 3.205858157775, 1e-10, "exact incline velocity at %d Hz" % rate)
	for args in [[0, 30, 0.4, 0.2, 0, 9.81], [10, -1, 0.4, 0.2, 0, 9.81], [10, 30, 0.1, 0.2, 0, 9.81], [10, 30, 0.4, -0.2, 0, 9.81], [10, 30, 0.4, 0.2, 0, 0], [NAN, 30, 0.4, 0.2, 0, 9.81]]:
		t.check(not MechanicsModel.incline.callv(args).ok, "reject nonphysical incline parameters " + str(args))
	var projectile: Dictionary = MechanicsModel.projectile(14, 45)
	t.near(projectile.velocity.x, 9.899494936612, 1e-6, "projectile initial horizontal velocity")
	t.near(projectile.velocity.y, 9.899494936612, 1e-6, "projectile initial vertical velocity")
	t.near(projectile.range, 19.98, 0.005, "required projectile range benchmark [m]")
	t.near(projectile.flight, 2.018245654763, 1e-6, "equal-height flight time [s]")
	t.near(projectile.height, 4.994903160041, 1e-6, "maximum height above launch [m]")
	var at_one: Dictionary = MechanicsModel.projectile_state(14, 45, 1)
	t.near(at_one.position.x, 9.899494936612, 1e-6, "analytic x(t) at one second")
	t.near(at_one.position.y, 4.994494936612, 1e-6, "analytic y(t) at one second")
	t.near(at_one.velocity.y, 0.089494936612, 1e-6, "analytic vertical velocity at one second")
	var high: Dictionary = MechanicsModel.projectile(14, 45, 9.81, 2)
	t.check(high.times.size() == 2 and high.range < projectile.range, "higher receiver has ascending and descending positive roots")
	for time in high.times:
		t.near(MechanicsModel.projectile_state(14, 45, time).position.y, 2, 1e-5, "unequal-height quadratic root reaches specified elevation")
	var low: Dictionary = MechanicsModel.projectile(14, 45, 9.81, -2)
	t.check(low.times.size() == 1 and low.range > projectile.range, "lower receiver rejects negative time and has longer flight")
	t.check(not MechanicsModel.projectile(14, 45, 9.81, 6).reachable, "unreachable elevation has no imaginary trajectory")
	t.near(MechanicsModel.projectile(14, 45, 10).range, 19.6, 1e-6, "selected gravity drives the same projectile model")
	t.check(not MechanicsModel.projectile(-1, 45).ok and not MechanicsModel.projectile(14, 91).ok and not MechanicsModel.projectile(14, 45, 0).ok, "reject invalid launcher domain")
	t.check(not MechanicsModel.projectile_state(14, 45, -1).ok and not MechanicsModel.projectile(INF, 45).ok, "reject nonphysical projectile time and infinity")
	for mass in [2.0, 5.0]:
		var impulse: Dictionary = MechanicsModel.impulse(mass, Vector2.ZERO, Vector2(10, 0))
		t.near(impulse.velocity.x, 5 if mass == 2 else 2, 1e-9, "required impulse mass dependence at %.0f kg" % mass)
		t.near(impulse.momentum.x, 10, 1e-9, "momentum increase equals delivered impulse")
	var vector: Dictionary = MechanicsModel.impulse(2, Vector2(3, -1), Vector2(-4, 6))
	t.check(vector.velocity.is_equal_approx(Vector2(1, 2)), "directional impulse adds vector velocity change")
	t.check(vector.delta_p.is_equal_approx(Vector2(-4, 6)), "vector impulse equals vector momentum change")
	t.near(100 * 0.1, 10, 1e-12, "average force times delivery duration gives impulse")
	t.check(not MechanicsModel.impulse(0, Vector2.ZERO, Vector2.ONE).ok and not MechanicsModel.impulse(2, Vector2(NAN, 0), Vector2.ONE).ok, "reject invalid mass and nonfinite impulse state")
	var energy: Dictionary = MechanicsModel.energy(2, 2, 3, 100, 0.2)
	t.near(energy.potential, 39.24, 1e-10, "gravitational potential energy [J]")
	t.near(energy.kinetic, 9, 1e-10, "kinetic energy [J]")
	t.near(energy.spring, 2, 1e-10, "elastic spring energy [J]")
	var fall: Dictionary = MechanicsModel.fall(2, 2)
	t.near(fall.speed, 6.26, 0.005, "required ideal descent speed benchmark [m s^-1]")
	t.near(0.5 * 2 * fall.speed * fall.speed, fall.initial_j, 1e-10, "conservative mechanical energy balance")
	var lossy: Dictionary = MechanicsModel.fall(2, 2, 0.2)
	t.near(lossy.heat_j, 7.848, 1e-10, "documented guide loss [J]")
	t.near(0.5 * 2 * lossy.speed * lossy.speed + lossy.heat_j, lossy.initial_j, 1e-10, "thermal transfer closes energy balance")
	t.near((2 * 9.81 - 0.2 * 2 * 9.81) * 2, 0.5 * 2 * lossy.speed * lossy.speed, 1e-10, "net work equals change in kinetic energy")
	t.check(not MechanicsModel.fall(-1, 2).ok and not MechanicsModel.fall(2, 2, 1).ok and not MechanicsModel.energy(2, 2, 3, -1).ok, "energy domain validation")
	t.check(MechanicsModel.to_pixels(Vector2(2, 3)) == Vector2(128, -192), "SI to world projection uses 64 px per metre and flips up")
	for kind in ["incline", "projectile", "momentum", "energy"]:
		var state := ExperimentState.new()
		state.configure(kind)
		for variant in range(2):
			var question: Dictionary = ScholarChallenges.build(kind, state.parameters, variant)
			t.check(ScholarChallenges.check_answer(question, str(question.expected)).correct, "Scholar exact model answer accepted: " + question.id)
			t.check(ScholarChallenges.check_answer(question, "%.2f" % question.expected).correct, "Scholar rounding accepted: " + question.id)
			t.check(not ScholarChallenges.check_answer(question, str(question.expected + 10)).correct, "Scholar wrong answer explains without progression: " + question.id)
	var question: Dictionary = ScholarChallenges.build("energy", {"mass": 2.0, "height": 2.0, "loss": 0.0, "g": 9.81})
	t.check(not ScholarChallenges.check_answer(question, "nan").valid and not ScholarChallenges.check_answer(question, "hello").valid, "Scholar rejects nonfinite and malformed answers")
	t.check(ScholarChallenges.check_answer(question, "6,26").correct, "Scholar accepts decimal comma")
	var journal := PhysicsCodex.new()
	t.check(journal.load_entries(), "nine complete offline Codex records load")
	for entry in journal.entries:
		t.check(journal.text_for(entry).contains(entry.equations) and entry.assumptions.length() > 30 and entry.example.length() > 30, "Codex equations, assumptions, units and worked example: " + entry.id)
	var glyph_font: FontFile = load("res://assets/fonts/DejaVuSans.ttf")
	var server: TextServer = TextServerManager.get_primary_interface()
	var missing: Array[String] = []
	for character in FileAccess.get_file_as_string("res://content/journal/research_codex.json"):
		if character.unicode_at(0) > 127 and not server.font_has_char(glyph_font.get_rids()[0], character.unicode_at(0)) and character not in missing:
			missing.append(character)
	t.check(missing.is_empty(), "bundled font contains every non-ASCII Codex glyph without system fonts: " + str(missing))
	var si_missing: Array[String] = []
	for character in "θμΔ²ₛₖₚₙₑₜₐᵥₓᵧ⁻¹Σ√≤≥∥λ°½−×₀₁₂":
		if not server.font_has_char(glyph_font.get_rids()[0], character.unicode_at(0)): si_missing.append(character)
	t.check(si_missing.is_empty(), "bundled SI, Greek, subscript, superscript and operator glyphs: " + str(si_missing))
	t.check(GameTheme.body_font().fallbacks.has(glyph_font), "UI body font retains its base and includes the packaged scientific fallback")
	var saves := SaveRepository.new("res://artifacts/phase3-migration.json")
	for version in ["phase0.1", "phase1.0", "phase2.0"]:
		var old: Dictionary = saves.defaults()
		old.content_version = version
		old.unlocks = ["citadel.training.complete"]
		old.discoveries = ["physics.mechanics.linear_motion.projectile_range"]
		var progression := ResearchProgress.new()
		progression.restore(old)
		t.check(not progression.vector_unlocked and progression.completed.is_empty(), "legacy save gives safe research defaults: " + version)
		progression.snapshot(old)
		t.check(old.unlocks.size() == 1 and old.discoveries.size() == 1, "research migration retains legacy progress: " + version)
