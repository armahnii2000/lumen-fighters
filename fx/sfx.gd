class_name Sfx
extends Node

## Efectos de sonido generados por código (sin assets): tonos cortos para golpe y KO.
## Sustituibles por SFX reales después. En headless el driver de audio es dummy (seguro).

var _player: AudioStreamPlayer
var _hit: AudioStreamWAV
var _ko: AudioStreamWAV

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_hit = _tone(220.0, 0.10, 2.2)
	_ko = _tone(90.0, 0.35, 1.4)

func play_hit() -> void:
	_play(_hit)

func play_ko() -> void:
	_play(_ko)

func _play(s: AudioStreamWAV) -> void:
	if _player != null and s != null:
		_player.stream = s
		_player.play()

static func _tone(freq: float, dur: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(rate)
		var env: float = pow(1.0 - t / dur, decay)
		var sample: float = sin(TAU * freq * t) * env
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
