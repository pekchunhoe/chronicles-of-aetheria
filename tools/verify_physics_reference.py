"""Independent Python reference calculations, not a replacement for Godot tests."""
import math

G_M_PER_S2 = 9.81
fixtures = [
    ("projectile range", 14.0**2 * math.sin(math.radians(90)) / G_M_PER_S2, 19.98, 0.005, "m"),
    ("ramp acceleration", G_M_PER_S2 * (math.sin(math.pi / 6) - 0.20 * math.cos(math.pi / 6)), 3.21, 0.005, "m/s^2"),
    ("ideal fall speed", math.sqrt(2 * G_M_PER_S2 * 2.0), 6.26, 0.005, "m/s"),
    ("DC current", 12.0 / 6.0, 2.0, 1e-12, "A"),
]
for name, actual, expected, tolerance, unit in fixtures:
    assert abs(actual - expected) <= tolerance, name
    print(f"PASS: {name}: {actual:.12f} {unit}; abs tolerance {tolerance:g} {unit}")
print(f"Flight time reference: {28 * math.sin(math.pi / 4) / G_M_PER_S2:.16f} s")
