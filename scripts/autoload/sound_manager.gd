extends Node

var _pools: Dictionary = {}  # String -> Array[AudioStreamPlayer]
var _idx:   Dictionary = {}  # String -> int (round-robin)


func _ready() -> void:
	_make_pool("pew",     _gen_pew(),     3, -7.0)
	_make_pool("boom",    _gen_boom(),    4, -4.0)
	_make_pool("ding",    _gen_ding(),    2, -7.0)
	_make_pool("victory", _gen_victory(), 1, -3.0)


func _make_pool(name: String, samples: PackedFloat32Array,
		count: int, vol_db: float) -> void:
	var stream := _make_wav(samples)
	var pool: Array = []
	for _i in range(count):
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = vol_db
		add_child(p)
		pool.append(p)
	_pools[name] = pool
	_idx[name] = 0


func play(sound: String) -> void:
	if not _pools.has(sound):
		return
	# Use untyped locals: Dictionary returns Variant, typed annotations would be hard errors
	var pool = _pools[sound]
	var i    = int(_idx[sound])
	var p: AudioStreamPlayer = pool[i] as AudioStreamPlayer
	if p == null:
		return
	if p.playing:
		p.stop()
	p.play()
	_idx[sound] = (i + 1) % (pool as Array).size()


func play_shoot()     -> void: play("pew")
func play_explosion() -> void: play("boom")
func play_pickup()    -> void: play("ding")
func play_victory()   -> void: play("victory")


# ── WAV builder ───────────────────────────────────────────────────────────────

func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format  = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo  = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, clampi(int(samples[i] * 32767.0), -32768, 32767))
	wav.data = data
	return wav


# ── Sound generators ──────────────────────────────────────────────────────────

func _gen_pew() -> PackedFloat32Array:
	# Square-wave chirp 700 Hz → 120 Hz, 80 ms — retro "pew"
	var rate := 22050
	var dur  := 0.08
	var n    := int(rate * dur)
	var out  := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t     := float(i) / float(rate)
		var frac  := float(i) / float(n)
		var phase := TAU * (700.0 * t + 0.5 * (120.0 - 700.0) * t * t / dur)
		var sq    := 1.0 if sin(phase) >= 0.0 else -1.0
		out[i] = sq * pow(1.0 - frac, 1.5) * 0.42
	return out


func _gen_boom() -> PackedFloat32Array:
	# White noise + 65 Hz thump, 550 ms exponential decay
	var rate := 22050
	var n    := int(rate * 0.55)
	var out  := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	for i in range(n):
		var t    := float(i) / float(rate)
		var env  := exp(-float(i) / float(n) * 7.0)
		out[i] = (rng.randf_range(-1.0, 1.0) * 0.55 + sin(t * TAU * 65.0) * 0.35) * env
	return out


func _gen_ding() -> PackedFloat32Array:
	# Bell chord: 1047 + 1568 + 2093 Hz sine harmonics, 280 ms
	var rate := 22050
	var n    := int(rate * 0.28)
	var out  := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t   := float(i) / float(rate)
		var env := exp(-float(i) / float(n) * 5.0)
		var s   := (sin(t * TAU * 1047.0) * 0.50
				  + sin(t * TAU * 1568.0) * 0.30
				  + sin(t * TAU * 2093.0) * 0.15)
		out[i] = s * env * 0.65
	return out


func _gen_victory() -> PackedFloat32Array:
	# 4-note ascending square-wave fanfare: C5 E5 G5 C6
	var rate   := 22050
	var note_n := int(rate * 0.12)
	var freqs  := [523.25, 659.25, 783.99, 1046.50]
	var total  := note_n * freqs.size() + int(rate * 0.18)
	var out    := PackedFloat32Array()
	out.resize(total)
	for ni in range(freqs.size()):
		var freq  : float = freqs[ni]
		var start : int   = ni * note_n
		for i in range(note_n):
			var t    := float(i) / float(rate)
			var frac := float(i) / float(note_n)
			var env  := 1.0 - frac * 0.35
			if frac > 0.82:
				env = (1.0 - frac) / 0.18 * 0.65
			var sq := 1.0 if sin(t * TAU * freq) >= 0.0 else -1.0
			out[start + i] = sq * env * 0.42
	return out
