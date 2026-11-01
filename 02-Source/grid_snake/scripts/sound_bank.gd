extends Node
## Original synthesized effects and a quiet, procedural four-note ambient bed.

var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor: int = 0
var master_volume: float = 0.65
var music_timer: float = 0.0
var music_step: int = 0
var music_enabled: bool = true

func _ready() -> void:
	for i in range(16):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	sounds["shot"] = tone(760.0, 230.0, 0.075, 0.12)
	sounds["scatter"] = tone(250.0, 85.0, 0.13, 0.22, 0.3)
	sounds["rail"] = tone(1200.0, 100.0, 0.22, 0.18)
	sounds["hit"] = tone(130.0, 55.0, 0.13, 0.3, 0.55)
	sounds["boom"] = tone(95.0, 28.0, 0.28, 0.38, 0.65)
	sounds["dash"] = tone(240.0, 850.0, 0.18, 0.19, 0.15)
	sounds["pickup"] = tone(650.0, 1350.0, 0.2, 0.2)
	sounds["click"] = tone(700.0, 1000.0, 0.06, 0.15)
	sounds["upgrade"] = tone(350.0, 1100.0, 0.42, 0.22)
	sounds["warning"] = tone(180.0, 175.0, 0.45, 0.22)
	for i in range(4):
		sounds["pad%d" % i] = tone([130.81, 155.56, 196.0, 174.61][i], [130.81, 155.56, 196.0, 174.61][i], 2.5, 0.07)

func tone(start: float, finish: float, duration: float, gain: float, noise: float = 0.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count := int(22050 * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var generator := RandomNumberGenerator.new()
	generator.seed = 4281
	for i in range(count):
		var t := float(i) / count
		phase += TAU * lerpf(start, finish, t) / 22050.0
		var envelope := minf(t * 40.0, 1.0) * pow(1.0 - t, 1.7)
		var value := (sin(phase) * (1.0 - noise) + generator.randf_range(-1, 1) * noise) * gain * envelope
		bytes.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767))
	stream.data = bytes
	return stream

func play(effect: String, gain: float = 1.0) -> void:
	if not sounds.has(effect) or master_volume <= 0.001:
		return
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.stream = sounds[effect]
	voice.volume_db = linear_to_db(master_volume * gain)
	voice.play()

func _process(delta: float) -> void:
	if not music_enabled:
		return
	music_timer -= delta
	if music_timer <= 0.0:
		music_timer = 2.15
		play("pad%d" % (music_step % 4), 0.6)
		music_step += 1

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()
