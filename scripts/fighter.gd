extends CharacterBody2D

@export var player_id: int = 1 # 1 or 2
@export var max_health: int = 100
@export var max_lumen: int = 100

var health: int = 100
var lumen: float = 50.0
var is_blocking: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var facing: int = 1 # 1 right, -1 left
var opponent: CharacterBody2D

# movement
var speed: float = 260.0
var jump_force: float = -520.0
var gravity: float = 1200.0

# attack data
var attack_cooldown: float = 0.0
var hit_cooldown: float = 0.0 # invincibility after hit
var stun_time: float = 0.0

@onready var body_sprite: ColorRect = $Body
@onready var blade: Line2D = $Blade
@onready var blade_light: PointLight2D = $Blade/PointLight2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var blade_area: Area2D = $BladeArea
@onready var blade_collision: CollisionShape2D = $BladeArea/CollisionShape2D

var blade_base_length: float = 40.0
var blade_dim_length: float = 18.0

func _ready():
	health = max_health
	lumen = 50
	add_to_group("fighters")
	# setup collision layers
	hurtbox.monitoring = false
	hitbox.monitoring = false
	blade_area.monitoring = false
	blade_collision.disabled = true
	# connect signals
	if not blade_area.area_entered.is_connected(_on_blade_hit):
		blade_area.area_entered.connect(_on_blade_hit)
	update_blade_visual(0)
	# set initial color
	if player_id == 1:
		body_sprite.color = Color(0.2, 0.6, 1.0, 1)
		blade.default_color = Color(0.4, 0.9, 1.0, 1)
		blade_light.color = Color(0.4, 0.9, 1.0, 1)
	else:
		body_sprite.color = Color(1.0, 0.3, 0.4, 1)
		blade.default_color = Color(1.0, 0.4, 0.5, 1)
		blade_light.color = Color(1.0, 0.4, 0.5, 1)

func _physics_process(delta):
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return

	if stun_time > 0:
		stun_time -= delta
		velocity.x = move_toward(velocity.x, 0, 600 * delta)
		velocity.y += gravity * delta
		move_and_slide()
		_update_facing()
		_handle_timers(delta)
		return

	_handle_input(delta)
	_handle_timers(delta)
	_apply_gravity(delta)
	move_and_slide()
	_update_facing()
	_clamp_to_arena()
	_regen_lumen(delta)

func _handle_timers(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			is_attacking = false
			blade_area.monitoring = false
			blade_collision.disabled = true
	if hit_cooldown > 0:
		hit_cooldown -= delta

func _regen_lumen(delta):
	if not is_attacking and not is_blocking:
		lumen = min(max_lumen, lumen + 4.0 * delta) # 4 per sec idle
	update_blade_visual(delta)

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_facing():
	if opponent and not is_dead:
		facing = 1 if opponent.global_position.x > global_position.x else -1
		body_sprite.scale.x = facing * 1.0 # flip body if needed
		# blade side
		blade.position.x = 12 * facing

func _clamp_to_arena():
	global_position.x = clamp(global_position.x, 40, 1240)
	# keep above floor handled by collision

func _handle_input(delta):
	var left = "p1_left" if player_id == 1 else "p2_left"
	var right = "p1_right" if player_id == 1 else "p2_right"
	var jump = "p1_jump" if player_id == 1 else "p2_jump"
	var block = "p1_block" if player_id == 1 else "p2_block"
	var jab = "p1_jab" if player_id == 1 else "p2_jab"
	var slash = "p1_slash" if player_id == 1 else "p2_slash"
	var special = "p1_special" if player_id == 1 else "p2_special"

	# blocking
	is_blocking = Input.is_action_pressed(block) and is_on_floor() and attack_cooldown <= 0 and stun_time <= 0
	if is_blocking:
		velocity.x = move_toward(velocity.x, 0, 1200 * delta)
		body_sprite.color = body_sprite.color.lerp(Color(0.9,0.9,0.9,1), 0.2)
	else:
		# restore color
		if player_id == 1:
			body_sprite.color = Color(0.2, 0.6, 1.0, 1)
		else:
			body_sprite.color = Color(1.0, 0.3, 0.4, 1)

	if is_blocking or is_attacking:
		# no movement while attacking/blocking except little
		if not is_attacking:
			velocity.x = move_toward(velocity.x, 0, 800 * delta)
	else:
		var dir = Input.get_axis(left, right)
		velocity.x = dir * speed
		if Input.is_action_just_pressed(jump) and is_on_floor():
			velocity.y = jump_force

		# attacks
		if Input.is_action_just_pressed(jab):
			_do_jab()
		elif Input.is_action_just_pressed(slash):
			_do_slash()
		elif Input.is_action_just_pressed(special):
			_do_special()

func _do_jab():
	if attack_cooldown > 0: return
	is_attacking = true
	attack_cooldown = 0.25
	lumen = min(max_lumen, lumen + 5) # jabs generate light
	_activate_blade(12, 8, 0.18)
	# quick forward nudge
	velocity.x += facing * 60
	_flash_blade(Color(1,1,1,1))

func _do_slash():
	if attack_cooldown > 0: return
	if lumen < 10:
		# dim slash - weak
		is_attacking = true
		attack_cooldown = 0.35
		_activate_blade(6, 8, 0.25)
		velocity.x += facing * 40
	else:
		lumen -= 10
		is_attacking = true
		attack_cooldown = 0.45
		_activate_blade(16, 14, 0.32)
		velocity.x += facing * 90
		_flash_blade(Color(1,1,0.6,1))

func _do_special():
	if attack_cooldown > 0: return
	if lumen < 25:
		# not enough - just flicker
		_flash_blade(Color(1,0.3,0.3,1))
		return
	lumen -= 25
	is_attacking = true
	attack_cooldown = 0.6
	# photon burst - 1 projectile for demo (full would be 3)
	_spawn_projectile()
	_flash_blade(Color(1,1,1,1))
	# knockback self a bit
	velocity.x -= facing * 30

func _activate_blade(damage: int, knock: float, duration: float):
	blade_area.set_meta("damage", damage)
	blade_area.set_meta("knock", knock)
	blade_area.monitoring = true
	blade_collision.disabled = false
	# auto disable after duration
	await get_tree().create_timer(duration).timeout
	if blade_area:
		blade_area.monitoring = false
		blade_collision.disabled = true

func _spawn_projectile():
	var proj = Area2D.new()
	proj.name = "Photon"
	proj.position = global_position + Vector2(20 * facing, -12)
	proj.collision_layer = 2
	proj.collision_mask = 2
	proj.set_meta("damage", 18)
	proj.set_meta("owner_id", player_id)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	col.shape = shape
	proj.add_child(col)
	var vis = ColorRect.new()
	vis.size = Vector2(16,16)
	vis.position = Vector2(-8,-8)
	vis.color = blade.default_color
	proj.add_child(vis)
	var light = PointLight2D.new()
	light.energy = 1.2
	light.color = blade.default_color
	light.texture_scale = 0.3
	proj.add_child(light)
	# motion script via tween
	get_tree().current_scene.add_child(proj)
	var tween = proj.create_tween()
	tween.tween_property(proj, "position:x", proj.position.x + 700 * facing, 0.65)
	tween.tween_callback(proj.queue_free)
	# check hit every frame via area
	proj.area_entered.connect(func(area):
		if area.name == "Hurtbox" and area.get_parent() != self:
			var target = area.get_parent()
			if target.has_method("take_hit") and target.player_id != player_id:
				target.take_hit(18, 20 * facing, false)
				_spawn_hit_particles(target.global_position)
				proj.queue_free()
	)

func _on_blade_hit(area):
	if area.name != "Hurtbox": return
	var target = area.get_parent()
	if target == self: return
	if not target.has_method("take_hit"): return
	if target.player_id == player_id: return
	if blade_area.monitoring == false: return
	# prevent self hit loops
	var dmg = blade_area.get_meta("damage") if blade_area.has_meta("damage") else 10
	var knock = blade_area.get_meta("knock") if blade_area.has_meta("knock") else 10
	# clash check - if both attacking
	if target.is_attacking and target.blade_area.monitoring:
		_do_clash(target)
		return
	target.take_hit(dmg, knock * facing, target.is_blocking)
	# lumen steal on hit
	if not target.is_blocking:
		lumen = min(max_lumen, lumen + 3)
	_spawn_hit_particles(target.global_position)

func _do_clash(other):
	# push both back
	velocity.x = -facing * 180
	other.velocity.x = other.facing * -180
	attack_cooldown = 0.2
	other.attack_cooldown = 0.2
	_spawn_hit_particles((global_position + other.global_position)/2 + Vector2(0,-10))

func take_hit(damage: int, knock: float, blocked: bool):
	if is_dead: return
	if hit_cooldown > 0: return
	if blocked:
		if lumen >= 5:
			lumen -= 5
			damage = int(damage * 0.3) # 70% reduction
			knock *= 0.3
			_flash_body(Color(0.7,0.7,1,1))
			hit_cooldown = 0.15
		else:
			# block break
			is_blocking = false
			stun_time = 0.4
			damage = int(damage * 0.6)
	else:
		_flash_body(Color(1,0.2,0.2,1))
		stun_time = 0.18 if damage < 15 else 0.32
		hit_cooldown = 0.25

	health -= damage
	health = max(0, health)
	velocity.x += knock * 12
	velocity.y = min(velocity.y, -80) if not is_on_floor() else velocity.y - 20
	if health <= 0:
		die()
	# screen shake via camera
	if get_tree().current_scene.has_method("shake"):
		get_tree().current_scene.shake( (damage / 10.0) )

func _flash_blade(col: Color):
	var tween = create_tween()
	var orig = blade.default_color
	blade.default_color = col
	tween.tween_property(blade, "default_color", orig, 0.12)

func _flash_body(col: Color):
	var orig = body_sprite.color
	body_sprite.color = col
	await get_tree().create_timer(0.08).timeout
	if body_sprite:
		if player_id == 1:
			body_sprite.color = Color(0.2, 0.6, 1.0, 1)
		else:
			body_sprite.color = Color(1.0, 0.3, 0.4, 1)

func _spawn_hit_particles(pos: Vector2):
	var p = CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.amount = 12
	p.lifetime = 0.25
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector2(0,-1)
	p.spread = 60
	p.gravity = Vector2(0, 400)
	p.initial_velocity_min = 80
	p.initial_velocity_max = 180
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = blade.default_color
	get_tree().current_scene.add_child(p)
	await get_tree().create_timer(0.4).timeout
	if p: p.queue_free()

func update_blade_visual(_delta):
	var ignited = lumen > 10
	var target_len = blade_base_length if ignited else blade_dim_length
	# blade is Line2D from 0,0 to length,0
	var cur_len = blade.points[1].x if blade.points.size() > 1 else 0
	var new_len = lerp(cur_len, target_len, 0.15)
	blade.points = PackedVector2Array([Vector2(0,0), Vector2(new_len, 0)])
	blade.width = 8 if ignited else 4
	blade_light.energy = 1.8 if ignited else 0.4
	blade_light.visible = true
	# flicker when dim
	if not ignited:
		blade.default_color.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02)
	else:
		blade.default_color.a = 1.0
	# update blade collision shape length
	if blade_collision and blade_collision.shape:
		var rect = blade_collision.shape as RectangleShape2D
		if rect:
			rect.size.x = new_len
			blade_collision.position.x = new_len/2

func die():
	is_dead = true
	velocity = Vector2(-facing * 100, -250)
	body_sprite.color = Color(0.3,0.3,0.3,1)
	blade.visible = false
	blade_light.visible = false
	blade_area.monitoring = false
