class_name ScholarChallenges
extends RefCounted
## Deterministic local questions from a frozen copy of the exact apparatus parameters.
static func build(kind: String, source: Dictionary, variant: int = 0) -> Dictionary:
	var p: Dictionary = source.duplicate(true)
	var question: String
	var expected: float
	var unit: String
	var steps: String
	match kind:
		"incline":
			var f: Dictionary = MechanicsModel.incline(p.mass, p.angle, p.mu_s, p.mu_k, 0, p.g)
			if variant % 2 == 1:
				question = "Will cargo released from rest slide downhill? Enter 1 for yes or 0 for no."
				expected = 0 if f.static else 1
				unit = "1 = yes; 0 = no"
				steps = "1. W∥ = mg sin θ = %.4f N.\n2. fₛ,max = μₛmg cos θ = %.4f N.\n3. Slide only if W∥ > fₛ,max. Answer: %d." % [f.parallel_n, f.static_limit_n, int(expected)]
			else:
				question = "Find the initial downhill acceleration of cargo released from rest. First check static friction."
				expected = f.a
				unit = "m s⁻²"
				steps = "1. W∥ = %.4f N; limiting static friction = %.4f N.\n2. %s\n3. a = ΣF / m = %.5f m s⁻²." % [f.parallel_n, f.static_limit_n, "Static friction balances the drive; ΣF = 0." if f.static else "Sliding: subtract μₖN from mg sin θ.", expected]
		"projectile":
			var trajectory: Dictionary = MechanicsModel.projectile(p.speed, p.angle, p.g, p.target_y - p.launch_y)
			if not trajectory.reachable or variant % 2 == 1:
				question = "Find maximum height above the launch point."
				expected = trajectory.height
				unit = "m"
				steps = "1. uᵧ = u sin θ = %.5f m s⁻¹.\n2. At the apex vᵧ = 0.\n3. H = uᵧ² / (2g) = %.5f m." % [trajectory.velocity.y, expected]
			else:
				question = "Find horizontal displacement when the projectile DESCENDS through the receiver centre's elevation. Ignore contact size and obstructions."
				expected = trajectory.range
				unit = "m"
				steps = "1. Δy = %.3f m; uᵧ = %.5f m s⁻¹.\n2. Solve ½gt² − uᵧt + Δy = 0. Use the later positive root: t = %.5f s.\n3. Δx = u cos θ t = %.5f m. A receiver at another x can still be missed." % [p.target_y - p.launch_y, trajectory.velocity.y, trajectory.flight, expected]
		"momentum":
			question = "Find the immediate rightward velocity change from a +10 N s net impulse. Ignore other impulses during delivery."
			expected = 10.0 / p.mass
			unit = "m s⁻¹"
			steps = "1. J = Δp = mΔv.\n2. Δv = 10 / %.2f = %.5f m s⁻¹.\n3. Later rail friction changes this velocity; it is not part of the instantaneous strike." % [p.mass, expected]
			if variant % 2 == 1:
				question = "Find momentum change from the +10 N s impulse."
				expected = 10.0
				unit = "kg m s⁻¹"
				steps = "1. Δp = J.\n2. 1 N s = 1 kg m s⁻¹.\n3. Δp = +10 kg m s⁻¹ for either cargo mass."
		"energy":
			var energy: Dictionary = MechanicsModel.fall(p.height, p.mass, p.loss, p.g)
			question = "Find the incident speed after the full descent; include the selected guide loss fraction."
			expected = energy.speed
			unit = "m s⁻¹"
			steps = "1. Eₚ = mgh = %.5f J.\n2. Thermal transfer = λmgh = %.5f J.\n3. ½mv² = mgh(1 − λ).\n4. v = √[2gh(1 − λ)] = %.5f m s⁻¹." % [energy.initial_j, energy.heat_j, expected]
			if variant % 2 == 1:
				question = "Find the initial gravitational potential energy relative to the receiver."
				expected = energy.initial_j
				unit = "J"
				steps = "1. Set h = 0 at the receiver.\n2. Eₚ = mgh = %.2f × %.2f × %.2f = %.5f J." % [p.mass, p.g, p.height, expected]
		_:
			return {}
	return {"id": kind + "." + str(variant % 2), "question": question, "expected": expected, "unit": unit,
		"steps": steps, "parameters": p, "tolerance": maxf(0.01, absf(expected) * 0.005)}


static func check_answer(challenge: Dictionary, answer: String) -> Dictionary:
	var cleaned: String = answer.strip_edges().replace(",", ".")
	if not cleaned.is_valid_float() or not is_finite(cleaned.to_float()):
		return {"valid": false, "correct": false, "feedback": "Enter a finite number in the stated unit. Scientific notation is accepted."}
	var correct: bool = absf(cleaned.to_float() - challenge.expected) <= challenge.tolerance
	return {"valid": true, "correct": correct, "feedback": ("Archive seal earned. " if correct else "Try comparing the force or energy terms below. ") + "Accepted tolerance: ±%.4f %s.\n\n%s" % [challenge.tolerance, challenge.unit, challenge.steps]}
