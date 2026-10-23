class_name CombatAudio
extends AudioStreamPlayer
## Short original synthesized cues. No external assets or runtime dependencies.
static var tones: Dictionary = {}


func cue(kind: String) -> void:
	if not tones.has(kind):
		var wave := AudioStreamWAV.new()
		wave.format = AudioStreamWAV.FORMAT_16_BITS
		wave.mix_rate = 22050
		var length: float = 0.13 if kind != "death" else 0.3
		var frequency: float = {"swing": 320.0, "heavy": 180.0, "hit": 130.0, "shot": 640.0, "relay": 880.0, "death": 85.0}.get(kind, 220.0)
		var samples := PackedByteArray()
		samples.resize(int(length * wave.mix_rate) * 2)
		for index in range(samples.size() / 2):
			var time: float = float(index) / wave.mix_rate
			var envelope: float = pow(1.0 - time / length, 2.0)
			var value: float = sin(TAU * frequency * time * (1.0 - 0.4 * time / length))
			samples.encode_s16(index * 2, int(value * envelope * 9000.0))
		wave.data = samples
		tones[kind] = wave
	stream = tones[kind]
	volume_db = -16.0
	play()


func _exit_tree() -> void:
	stop()
	stream = null
