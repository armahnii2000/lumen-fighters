class_name MatchManager
extends Node2D

## Orquestador del combate. Tras mover a los fighters aplica lo "global": paredes,
## pushbox, resolución de golpes (hitbox↔hurtbox) y cámara.
## (Rounds, timer, HUD y KO llegan en la Fase 6.)

@export var stage_left: float = 40.0
@export var stage_right: float = 344.0
@export var pushbox_min_sep: float = 44.0
@export var throw_range: float = 60.0
@export var view_width: float = 384.0
@export var cam_min_zoom: float = 0.85
@export var cam_max_zoom: float = 1.6
@export var cam_margin: float = 90.0

@onready var camera: Camera2D = $Camera2D

const HIT_SPARK := preload("res://fx/hit_spark.tscn")

var p1: Fighter
var p2: Fighter
var hud: HUD = null
var _shake: int = 0

func _ready() -> void:
	process_priority = 100   # correr DESPUÉS de que los fighters integren
	p1 = $Player1
	p2 = $Player2
	p1.opponent = p2
	p2.opponent = p1
	p1.team = 0
	p2.team = 1
	for f in [p1, p2]:
		f.wall_left = stage_left
		f.wall_right = stage_right
	hud = get_node_or_null("HUD")
	if hud != null:
		hud.setup(p1, p2)

func _physics_process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	# Pushbox
	var sep := StagePhysics.separate(p1.position.x, p2.position.x, pushbox_min_sep)
	p1.position.x = sep[0]
	p2.position.x = sep[1]
	# Paredes
	p1.position.x = StagePhysics.clamp_wall(p1.position.x, stage_left, stage_right)
	p2.position.x = StagePhysics.clamp_wall(p2.position.x, stage_left, stage_right)
	# Agarres (antes que los golpes: tienen prioridad si ambos conectan)
	Throws.resolve(p1, p2, throw_range)
	# Golpes (con feedback: chispa + screen shake al conectar)
	if Combat.resolve(p1, p2):
		_on_hit(p2)
	if Combat.resolve(p2, p1):
		_on_hit(p1)
	# Proyectiles
	_process_projectiles(delta)
	# Cámara
	if camera != null:
		var cam := CameraLogic.compute(p1.position.x, p2.position.x, view_width, cam_min_zoom, cam_max_zoom, cam_margin)
		var off := 0.0
		if _shake > 0:
			off = 3.0 if (_shake % 2 == 0) else -3.0
			_shake -= 1
		camera.position.x = cam[0] + off
		camera.zoom = Vector2(cam[1], cam[1])

func _on_hit(defender: Fighter) -> void:
	_spawn_spark(defender.global_position + Vector2(0.0, -50.0))
	_shake = 6

func _spawn_spark(pos: Vector2) -> void:
	var spark := HIT_SPARK.instantiate()
	spark.global_position = pos
	add_child(spark)

func _process_projectiles(delta: float) -> void:
	for proj in get_tree().get_nodes_in_group("projectile"):
		proj.position.x += proj.velocity_x * delta
		if proj.position.x < -40.0 or proj.position.x > view_width + 40.0:
			proj.queue_free()
			continue
		for f in [p1, p2]:
			if f.team == proj.team or f.is_invulnerable():
				continue
			if proj.rect().intersects(f.hurtbox_rect()):
				if f.is_blocking(proj.move):
					f.receive_block(proj.move, proj.owner_facing)
				else:
					f.receive_hit(proj.move, proj.owner_facing)
				_on_hit(f)
				proj.queue_free()
				break
