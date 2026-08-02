class_name Fighter
extends CharacterBody2D

## Personaje genérico. La MISMA clase sirve para P1, P2 y CPU: consume un InputFrame por
## tick y no sabe quién lo controla. Los estados deciden QUÉ hacer; el Fighter expone el
## CÓMO (moverse, atacar) e integra física. Las colisiones globales (paredes, pushbox) y
## la resolución de golpes las coordina MatchManager.

@export_group("Movement")
@export var walk_fwd_speed: float = 180.0
@export var walk_back_speed: float = 140.0
@export var dash_fwd_speed: float = 420.0
@export var dash_fwd_frames: int = 16
@export var dash_back_speed: float = 360.0
@export var dash_back_frames: int = 14

@export_group("Jump")
@export var jump_startup_frames: int = 4
@export var jump_speed: float = -640.0
@export var jump_h_speed: float = 170.0
@export var gravity: float = 1800.0

@export_group("Combat")
@export var team: int = 0
@export var max_health: int = 1000
@export var hurtbox_offset: Vector2 = Vector2(0, -48)
@export var hurtbox_size: Vector2 = Vector2(44, 96)
@export var crouch_hurtbox_offset: Vector2 = Vector2(0, -28)
@export var crouch_hurtbox_size: Vector2 = Vector2(44, 56)

@export_group("Setup")
@export var ground_y: float = 180.0
@export var wall_left: float = -100000.0
@export var wall_right: float = 100000.0
@export var body_color: Color = Color(0.2, 0.5, 0.95)
@export var input_source: InputSource

@onready var state_machine: StateMachine = $StateMachine
@onready var visual: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Torso
@onready var head: Polygon2D = $Visual/Head
@onready var limb: Polygon2D = $Visual/Limb

const GROUNDED_STATES := ["Idle", "Walk", "Crouch"]
const BTN_KEYS := ["lp", "mp", "hp", "lk", "mk", "hk"]
const ATTACK_PRIORITY := ["hp", "hk", "mp", "mk", "lp", "lk"]

var input: InputFrame = InputFrame.new()
var vel: Vector2 = Vector2.ZERO
var facing_right: bool = true
var opponent: Fighter = null
var on_ground: bool = true

var health: int = 1000
var moves: Dictionary = {}
var current_move: MoveData = null
var move_has_hit: bool = false
var hitstun_frames: int = 0
var hitstop_frames: int = 0
var blockstun_frames: int = 0
var knockdown_frames: int = 0
var throw_pressed: bool = false
var invuln_frames: int = 0
var combo_count: int = 0

var specials: Dictionary = {}
var _numpad_history: Array = []
var _projectile_spawned: bool = false

const NEUTRAL_STATES := ["Idle", "Walk", "Crouch"]
const THROW_DAMAGE := 120
const KNOCKDOWN_FRAMES := 40
const MOTION_WINDOW := 12
const NUMPAD_HISTORY := 24
const PUNCHES := ["hp", "mp", "lp"]
const KICKS := ["hk", "mk", "lk"]
const PROJECTILE_SCENE := preload("res://projectile/projectile.tscn")

var dash_frames_current: int = 0
var just_pressed: Array = []

var _dash := DashInput.new()
var _dash_signal: int = 0
var _prev_buttons := [false, false, false, false, false, false]

func _ready() -> void:
	_apply_base_colors()
	health = max_health
	moves = MoveSet.default_normals()
	specials = MoveSet.default_specials()
	if input_source == null:
		for child in get_children():
			if child is InputSource:
				input_source = child
				break
	state_machine.setup(self)

func _apply_base_colors() -> void:
	($Visual/Torso as Polygon2D).color = body_color
	($Visual/Head as Polygon2D).color = body_color
	($Visual/LegFront as Polygon2D).color = body_color
	($Visual/LegBack as Polygon2D).color = body_color.darkened(0.35)
	($Visual/Limb as Polygon2D).color = body_color.lightened(0.3)

func _process(_delta: float) -> void:
	# Presentación pura: pose + tinte de la silueta según el estado (lee el estado, no lo maneja).
	if body == null:
		return
	var st: String = String(state_machine.current_state.name) if state_machine.current_state != null else "Idle"
	# Pose: facing (flip), agachado (squash), derribado (rotado), prejump (leve squash).
	var sy := 1.0
	var rot := 0.0
	match st:
		"Crouch":
			sy = 0.72
		"JumpStartup":
			sy = 0.9
		"Knockdown":
			rot = deg_to_rad(78.0)
	visual.scale = Vector2(float(facing()), sy)
	visual.rotation = rot
	# Extremidad de golpe: visible en los frames activos del ataque.
	limb.visible = st == "Attack" and is_attack_active()
	# Tinte (flash de feedback).
	var tint := body_color
	match st:
		"Hitstun":
			tint = Color(1, 1, 1)
		"Blockstun":
			tint = Color(0.55, 0.92, 1.0)
		"Attack":
			tint = body_color.lightened(0.3) if is_attack_active() else body_color.lightened(0.12)
		"Knockdown":
			tint = body_color.darkened(0.4)
	body.color = tint
	head.color = tint if st == "Hitstun" else body_color

func _physics_process(delta: float) -> void:
	# Hitstop: congela por completo a ambos (impacto). Ni input, ni estado, ni física.
	if hitstop_frames > 0:
		hitstop_frames -= 1
		return
	if input_source != null:
		input = input_source.poll()
	if invuln_frames > 0:
		invuln_frames -= 1
	_dash_signal = _dash.update(input.horizontal())
	_update_button_edges()
	_update_throw_press()
	if state_machine.current_state != null and state_machine.current_state.name in GROUNDED_STATES:
		_update_facing()
	_push_numpad()
	state_machine.physics_update(delta)
	_integrate(delta)

func _push_numpad() -> void:
	_numpad_history.push_front(current_numpad())
	if _numpad_history.size() > NUMPAD_HISTORY:
		_numpad_history.pop_back()

## Dirección actual en numpad, relativa al facing (adelante = hacia el rival).
func current_numpad() -> int:
	var screen := input.horizontal()
	var fb := 0
	if screen == facing():
		fb = 1
	elif screen == -facing():
		fb = -1
	var v := 0
	if input.up:
		v = 1
	elif input.down:
		v = -1
	return MotionParser.to_numpad(fb, v)

func _integrate(delta: float) -> void:
	position += vel * delta
	position.x = clampf(position.x, wall_left, wall_right)
	if position.y >= ground_y:
		position.y = ground_y
		if vel.y > 0.0:
			vel.y = 0.0
		on_ground = true
	else:
		on_ground = false

func _update_facing() -> void:
	if opponent == null:
		return
	facing_right = opponent.global_position.x >= global_position.x

func _update_button_edges() -> void:
	just_pressed.clear()
	var cur := [input.lp, input.mp, input.hp, input.lk, input.mk, input.hk]
	for i in 6:
		if cur[i] and not _prev_buttons[i]:
			just_pressed.append(BTN_KEYS[i])
	_prev_buttons = cur

## Agarre: LP+LK (edge en uno con el otro mantenido), solo desde estado neutro.
func _update_throw_press() -> void:
	var st := state_machine.current_state
	var neutral := st != null and st.name in NEUTRAL_STATES
	throw_pressed = neutral and ((("lp" in just_pressed) and input.lk) or (("lk" in just_pressed) and input.lp))

func facing() -> int:
	return 1 if facing_right else -1

func consume_dash() -> int:
	var d: int = _dash_signal
	_dash_signal = 0
	return d

# --- Movimiento (usado por los estados) ---

func walk(screen_dir: int) -> void:
	var is_fwd: bool = screen_dir == facing()
	vel.x = screen_dir * (walk_fwd_speed if is_fwd else walk_back_speed)

func stop_horizontal() -> void:
	vel.x = 0.0

func begin_dash(screen_dir: int) -> void:
	var is_fwd: bool = screen_dir == facing()
	vel.x = screen_dir * (dash_fwd_speed if is_fwd else dash_back_speed)
	dash_frames_current = dash_fwd_frames if is_fwd else dash_back_frames

func launch_jump(h_dir: int) -> void:
	vel.y = jump_speed
	vel.x = h_dir * jump_h_speed
	on_ground = false

func apply_gravity(delta: float) -> void:
	vel.y += gravity * delta

# --- Ataques ---

## Intenta iniciar un normal según la postura ("st"/"cr"/"j"). Devuelve true si arrancó.
func try_start_attack(stance: String) -> bool:
	for btn in ATTACK_PRIORITY:
		if btn in just_pressed:
			var key: String = stance + "." + btn
			if moves.has(key):
				start_move(moves[key])
				return true
	return false

func start_move(m: MoveData) -> void:
	current_move = m
	move_has_hit = false
	_projectile_spawned = false
	invuln_frames = m.invuln_startup
	if on_ground:
		vel.x = 0.0

## Intenta iniciar un especial según el buffer de motion + botón. Prioridad: DP > QCF > QCB.
func try_start_special() -> bool:
	var punch := _pressed_strength(PUNCHES)
	var kick := _pressed_strength(KICKS)
	if punch != "" and MotionParser.matches(_numpad_history, [6, 2, 3], MOTION_WINDOW):
		start_move(specials["dp." + punch])
		return true
	if punch != "" and MotionParser.matches(_numpad_history, [2, 3, 6], MOTION_WINDOW):
		start_move(specials["hadouken." + punch])
		return true
	if kick != "" and MotionParser.matches(_numpad_history, [2, 1, 4], MOTION_WINDOW):
		start_move(specials["tatsu." + kick])
		return true
	return false

## Devuelve "l"/"m"/"h" del botón más fuerte recién pulsado de la lista, o "" si ninguno.
func _pressed_strength(buttons: Array) -> String:
	for i in buttons.size():
		if buttons[i] in just_pressed:
			return ["h", "m", "l"][i]   # buttons van de fuerte a débil
	return ""

func spawn_projectile(m: MoveData) -> void:
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position + Vector2(facing() * 44.0, -60.0)
	proj.velocity_x = facing() * m.projectile_speed
	proj.team = team
	proj.owner_facing = facing()
	proj.move = m
	get_parent().add_child(proj)

func is_invulnerable() -> bool:
	return invuln_frames > 0

## True si el fighter tiene un hitbox activo este frame.
func is_attack_active() -> bool:
	if current_move == null:
		return false
	var st := state_machine.current_state
	if st == null or st.name != "Attack":
		return false
	return MovePhase.phase_at(st.state_frame, current_move.startup, current_move.active, current_move.recovery) == MovePhase.ACTIVE

func hitbox_rect() -> Rect2:
	var off := current_move.hitbox_offset
	var cx := global_position.x + off.x * facing()
	var cy := global_position.y + off.y
	var sz := current_move.hitbox_size
	return Rect2(cx - sz.x / 2.0, cy - sz.y / 2.0, sz.x, sz.y)

func hurtbox_rect() -> Rect2:
	var crouching := state_machine.current_state != null and state_machine.current_state.name == "Crouch"
	var off := crouch_hurtbox_offset if crouching else hurtbox_offset
	var sz := crouch_hurtbox_size if crouching else hurtbox_size
	var c := global_position + off
	return Rect2(c.x - sz.x / 2.0, c.y - sz.y / 2.0, sz.x, sz.y)

func set_hitstop(n: int) -> void:
	hitstop_frames = n

## True si el defensor está bloqueando este golpe (dirección + postura correctas).
func is_blocking(m: MoveData) -> bool:
	if not on_ground:
		return false
	var st := state_machine.current_state
	if st == null or not (st.name in ["Idle", "Walk", "Crouch", "Blockstun"]):
		return false
	var holding_back := input.horizontal() == -facing()
	return BlockRules.can_block(holding_back, input.down, m.hits_low, m.hits_overhead)

## Recibe un golpe limpio (con damage scaling si es continuación de combo).
func receive_hit(m: MoveData, attacker_facing: int) -> void:
	var st := state_machine.current_state
	if st != null and st.name == "Hitstun":
		combo_count += 1
	else:
		combo_count = 1
	var dmg := DamageCalculator.scaled_damage(m.damage, combo_count - 1)
	health = max(health - dmg, 0)
	vel = Vector2(attacker_facing * m.pushback, 0.0)
	if m.causes_knockdown:
		knockdown_frames = KNOCKDOWN_FRAMES
		state_machine.transition_to("Knockdown")
	else:
		hitstun_frames = m.hitstun
		state_machine.transition_to("Hitstun")

## Recibe un golpe bloqueado: chip damage (puede matar) + blockstun + poco pushback.
func receive_block(m: MoveData, attacker_facing: int) -> void:
	var chip: int = int(round(m.damage * 0.15))
	health = max(health - chip, 0)
	blockstun_frames = m.blockstun
	vel = Vector2(attacker_facing * m.pushback * 0.5, 0.0)
	state_machine.transition_to("Blockstun")

func is_throwable() -> bool:
	return on_ground and (state_machine.current_state != null and state_machine.current_state.name in NEUTRAL_STATES)

func do_throw(victim: Fighter) -> void:
	current_move = null
	state_machine.transition_to("Throw")
	victim.get_thrown(facing())

func get_thrown(thrower_facing: int) -> void:
	health = max(health - THROW_DAMAGE, 0)
	knockdown_frames = KNOCKDOWN_FRAMES
	vel = Vector2(thrower_facing * 120.0, 0.0)
	state_machine.transition_to("Knockdown")

func throw_tech() -> void:
	current_move = null
	vel = Vector2(-facing() * 200.0, 0.0)
	state_machine.transition_to("Idle")
