"""Independent Python reference calculations, not a replacement for Godot tests."""
import math

G_M_PER_S2 = 9.81
fixtures = [
    ("projectile range", 14.0**2 * math.sin(math.radians(90)) / G_M_PER_S2, 19.98, 0.005, "m"),
    ("ramp acceleration", G_M_PER_S2 * (math.sin(math.pi / 6) - 0.20 * math.cos(math.pi / 6)), 3.21, 0.005, "m/s^2"),
    ("ideal fall speed", math.sqrt(2 * G_M_PER_S2 * 2.0), 6.26, 0.005, "m/s"),
    ("DC current", 12.0 / 6.0, 2.0, 1e-12, "A"),
    ("2 kg impulse response", 10 / 2, 5, 1e-12, "m/s"),
    ("5 kg impulse response", 10 / 5, 2, 1e-12, "m/s"),
    ("normal reaction", 10 * G_M_PER_S2 * math.cos(math.pi / 6), 84.9570921113, 1e-9, "N"),
    ("adjusting static friction", 10 * G_M_PER_S2 * math.sin(math.pi / 12), 25.3901483246, 1e-9, "N"),
    ("spring storage", .5 * 100 * .2**2, 2, 1e-12, "J"),
    ("guide heat", .2 * 2 * G_M_PER_S2 * 2, 7.848, 1e-12, "J"),
    ("lossy descent", math.sqrt(2 * G_M_PER_S2 * 2 * .8), 5.602856414, 1e-8, "m/s"),
]
for name, actual, expected, tolerance, unit in fixtures:
    assert abs(actual - expected) <= tolerance, name
    print(f"PASS: {name}: {actual:.12f} {unit}; abs tolerance {tolerance:g} {unit}")
print(f"Flight time reference: {28 * math.sin(math.pi / 4) / G_M_PER_S2:.16f} s")
uy = 14 * math.sin(math.pi / 4)
t = (uy + math.sqrt(uy**2 - 2 * G_M_PER_S2 * 2)) / G_M_PER_S2
assert abs(uy * t - .5 * G_M_PER_S2 * t*t - 2) < 1e-12
print(f"PASS: unequal-height quadratic, +2 m descending time {t:.12f} s")
assert 10 * G_M_PER_S2 * math.sin(math.pi / 12) < .4 * 10 * G_M_PER_S2 * math.cos(math.pi / 12)
print("PASS: 15-degree static hold below limiting friction")
