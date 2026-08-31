extends Node2D

var game_over: bool = false
@onready var p1: CharacterBody2D = $P1
@onready var p2: CharacterBody2D = $P2
@onready var p1_health: ProgressBar = $UI/P1Health
@onready var p2_health: ProgressBar = $UI/P2Health
@onready var p1_lumen: ProgressBar = $UI/P1Lumen
@onready var p2_lumen: ProgressBar = $UI/P2Lumen
@onready var winner_label: Label = $UI/WinnerLabel
@onready var cam: Camera2D = $Camera2D

var shake_strength: float = 0.0

func _ready():
	p1.opponent = p2
	p2.opponent = p1
	p1_health.max_value = p1.max_health
	p2_health.max_value = p2.max_health
	p1_lumen.max_value = p1.max_lumen
	p2_lumen.max_value = p2.max_lumen
	winner_label.visible = false

func _process(delta):
	p1_health.value = p1.health
	p2_health.value = p2.health
	p1_lumen.value = p1.lumen
	p2_lumen.value = p2.lumen

	# camera follow center
	var center = (p1.global_position + p2.global_position) * 0.5
	center.y = 280
	cam.global_position = cam.global_position.lerp(center, 0.08)
	# slight zoom based on distance
	var dist = abs(p1.global_position.x - p2.global_position.x)
	var target_zoom = clamp(1.2 - dist/800.0, 0.85, 1.1)
	cam.zoom = cam.zoom.lerp(Vector2(target_zoom, target_zoom), 0.05)

	if shake_strength > 0:
		cam.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		shake_strength = lerp(shake_strength, 0.0, delta * 12.0)
		if shake_strength < 0.2:
			shake_strength = 0
			cam.offset = Vector2.ZERO

	if not game_over:
		if p1.health <= 0 or p2.health <= 0:
			game_over = true
			var winner = "PLAYER 2 WINS!" if p1.health <= 0 else "PLAYER 1 WINS!"
			if p1.health <=0 and p2.health <=0:
				winner = "DOUBLE KO!"
			winner_label.text = winner + "\n[R] RESTART"
			winner_label.visible = true

	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func shake(amount: float):
	shake_strength = max(shake_strength, amount * 6.0)
