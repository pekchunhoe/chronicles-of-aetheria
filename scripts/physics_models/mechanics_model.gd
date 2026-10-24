class_name MechanicsModel
extends RefCounted
## Scene-independent SI models. Incline: positive downhill. Projectiles: right/up.
## Parameter limits keep interactive experiments finite and physically meaningful.
const G: float = 9.81
const SCALE: float = 64.0


static func valid(values: Array) -> bool:
	for value in values:
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
	return true


static func incline(m: float, angle: float, mu_s: float, mu_k: float, v: float = 0.0, g: float = G) -> Dictionary:
	if not valid([m, angle, mu_s, mu_k, v, g]) or m <= 0 or g <= 0 or angle < 0 or angle > 90 or mu_k < 0 or mu_s < mu_k:
		return {"ok": false}
	var theta: float = deg_to_rad(angle)
	var weight: float = m * g
	var normal: float = weight * cos(theta)
	var drive: float = weight * sin(theta)
	var stationary: bool = absf(v) < 1e-9 and drive <= mu_s * normal + 1e-9
	var friction: float = -drive if stationary else -mu_k * normal * (signf(v) if absf(v) >= 1e-9 else 1.0)
	return {"ok": true, "weight_n": weight, "normal_n": normal, "parallel_n": drive,
		"friction_n": friction, "static_limit_n": mu_s * normal, "net_n": drive + friction,
		"a": (drive + friction) / m, "static": stationary}


static func incline_step(s: float, v: float, dt: float, p: Dictionary) -> Dictionary:
	var forces: Dictionary = incline(p.mass, p.angle, p.mu_s, p.mu_k, v, p.g)
	if not forces.ok or not valid([s, v, dt]) or dt < 0:
		return {"ok": false}
	var a: float = forces.a
	# Integrate constant force exactly; split at zero speed to prevent friction reversal chatter.
	if absf(v) > 1e-9 and v * a < 0 and -v / a <= dt:
		var stop: float = -v / a
		var at_rest: Dictionary = incline(p.mass, p.angle, p.mu_s, p.mu_k, 0.0, p.g)
		var remainder: float = dt - stop
		return {"ok": true, "s": s + v * stop + 0.5 * a * stop * stop + 0.5 * at_rest.a * remainder * remainder,
			"v": at_rest.a * remainder, "a": at_rest.a}
	return {"ok": true, "s": s + v * dt + 0.5 * a * dt * dt, "v": v + a * dt, "a": a}


static func projectile(u: float, angle: float, g: float = G, elevation: float = 0.0) -> Dictionary:
	if not valid([u, angle, g, elevation]) or u < 0 or u > 200 or angle < 0 or angle > 90 or g <= 0:
		return {"ok": false}
	var velocity := Vector2(u * cos(deg_to_rad(angle)), u * sin(deg_to_rad(angle)))
	var discriminant: float = velocity.y * velocity.y - 2.0 * g * elevation
	if discriminant < -1e-10:
		return {"ok": true, "reachable": false, "velocity": velocity, "times": [], "height": velocity.y * velocity.y / (2.0 * g)}
	var times: Array[float] = []
	for time in [(velocity.y - sqrt(maxf(0, discriminant))) / g, (velocity.y + sqrt(maxf(0, discriminant))) / g]:
		if time > 1e-9 and (times.is_empty() or absf(time - times[-1]) > 1e-9):
			times.append(time)
	return {"ok": true, "reachable": not times.is_empty(), "velocity": velocity, "times": times,
		"height": velocity.y * velocity.y / (2.0 * g), "flight": times[-1] if not times.is_empty() else 0.0,
		"range": velocity.x * times[-1] if not times.is_empty() else 0.0}


static func projectile_state(u: float, angle: float, t: float, g: float = G) -> Dictionary:
	var result: Dictionary = projectile(u, angle, g)
	if not result.ok or not valid([t]) or t < 0:
		return {"ok": false}
	var initial: Vector2 = result.velocity
	return {"ok": true, "position": Vector2(initial.x * t, initial.y * t - 0.5 * g * t * t),
		"velocity": Vector2(initial.x, initial.y - g * t), "acceleration": Vector2(0, -g)}


static func impulse(mass: float, initial: Vector2, j: Vector2) -> Dictionary:
	if not valid([mass, initial.x, initial.y, j.x, j.y]) or mass <= 0:
		return {"ok": false}
	var final: Vector2 = initial + j / mass
	return {"ok": true, "velocity": final, "delta_v": j / mass, "momentum": final * mass, "delta_p": j}


static func energy(mass: float, height: float, speed: float, k: float = 0.0, compression: float = 0.0, g: float = G) -> Dictionary:
	if not valid([mass, height, speed, k, compression, g]) or mass <= 0 or height < 0 or k < 0 or g <= 0:
		return {"ok": false}
	return {"ok": true, "potential": mass * g * height, "kinetic": 0.5 * mass * speed * speed,
		"spring": 0.5 * k * compression * compression}


static func fall(height: float, mass: float, loss: float = 0.0, g: float = G) -> Dictionary:
	if not valid([height, mass, loss, g]) or height < 0 or mass <= 0 or loss < 0 or loss >= 1 or g <= 0:
		return {"ok": false}
	# A constant upward guide resistance loss*m*g transfers mechanical energy to heat.
	return {"ok": true, "a": g * (1.0 - loss), "speed": sqrt(2.0 * g * height * (1.0 - loss)),
		"initial_j": mass * g * height, "heat_j": mass * g * height * loss}


static func to_pixels(si: Vector2) -> Vector2:
	return Vector2(si.x, -si.y) * SCALE
