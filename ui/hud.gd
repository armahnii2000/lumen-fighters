class_name HUD
extends CanvasLayer

## HUD simple: dos barras de vida que leen la salud de cada fighter (presentación pura).
## Sustituible por un HUD con sprites/arte más adelante sin tocar la lógica.

const BAR_W := 170.0

@onready var p1_fill: ColorRect = $P1Fill
@onready var p2_fill: ColorRect = $P2Fill
@onready var timer_label: Label = $Timer
@onready var msg_label: Label = $Message
@onready var p1_pips: Label = $P1Pips
@onready var p2_pips: Label = $P2Pips

var p1: Fighter
var p2: Fighter

func set_timer(seconds: int) -> void:
	if timer_label != null:
		timer_label.text = str(seconds)

func set_rounds(a: int, b: int) -> void:
	if p1_pips != null:
		p1_pips.text = "O".repeat(a)
	if p2_pips != null:
		p2_pips.text = "O".repeat(b)

func set_message(text: String) -> void:
	if msg_label != null:
		msg_label.text = text

func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b

func _process(_delta: float) -> void:
	if p1 != null:
		p1_fill.size.x = BAR_W * clampf(float(p1.health) / float(p1.max_health), 0.0, 1.0)
	if p2 != null:
		var w := BAR_W * clampf(float(p2.health) / float(p2.max_health), 0.0, 1.0)
		p2_fill.size.x = w
		p2_fill.position.x = 204.0 + (BAR_W - w)   # la barra de P2 drena hacia el centro
