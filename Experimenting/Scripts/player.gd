class_name Player extends CharacterBody2D

#an attempt to simplify the code from the other player script

@export var ghost_node : PackedScene

var speed = 180
var max_speed = 220
var jump_velocity = -320.0
var jump_cut = true

var jump_available = true
var jump_buffer : bool = false

var jump_pad = true

var max_fall_speed = 240
var is_grounded = false
var is_jumping = false

var dead : bool

var dash_speed = 48000
var can_dash = false
var just_dashed = false
#var is_dashing = false

var axis = Vector2()
var can_turn = true
var can_ledge = true
@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var dust = preload("res://Scenes/LandingParticles.tscn")
@onready var dash_cooldown: Timer = $DashCooldown
@onready var dash_recover: Timer = $DashRecover
@onready var ghost_timer: Timer = $Ghost_Timer
@onready var particles = $GPUParticles2D
@onready var player_body = $CollisionShape2D
@onready var player_hurtbox = $Area2D/CollisionShape2D
@onready var dash_hurtbox = $Dash_Hurtbox/CollisionShape2D

@export var jump_buffer_time = 0.1
@onready var coyote_timer: Timer = $Coyote_Timer
@export var coyote_time: float = .11

@onready var ray_cast_container = $RayCastContainer
@onready var ray_cast_1: RayCast2D = $RayCastContainer/RayCast1
@onready var ray_cast_2: RayCast2D = $RayCastContainer/RayCast2
@onready var ray_cast_3: RayCast2D = $RayCastContainer/RayCast3

var normal_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var wall_climbing = false
var grabbing_ledge = false
var climbing_ledge = false
var can_grab = true
var fall_gravity = 720
var normal_fall_gravity = 720

var wall_slide_gravity = 300
var max_wall_slide_speed = 100
var wall_sliding = false

func _ready():
	Global.playerBody = self
	Global.player_alive = true
	dead = false

func _physics_process(delta):
	get_gravity(delta)
	get_input_axis()
	if !dead:
		if grabbing_ledge and Input.is_action_just_pressed("Jump"):
			grabbing_ledge = false
			climbing_ledge = true

		var direction = Input.get_axis("ui_left", "ui_right")
		if grabbing_ledge:
			direction = 0
		
		wall_climbing_logic(delta)
		ledge_detection()
		climbing_ledge_logic()
		wall_slide_logic(delta)
		if just_dashed:
			player_hurtbox.disabled = true
			dash_hurtbox.disabled = false
		else:
			player_hurtbox.disabled = false
			dash_hurtbox.disabled = true
		#jump stuff
		if !Global.is_dashing:
			jump_logic()
		
		#dash stuff
		if !can_dash and is_on_floor() and !just_dashed and dash_recover.time_left <= 0:
			can_dash = true
		if Input.is_action_just_pressed("Dash"):
			if !climbing_ledge:
				if can_dash and is_on_floor():
					if dash_cooldown.time_left <= 0:
						new_dash(delta)
				elif can_dash and !Global.is_dashing:
					new_dash(delta)
		if just_dashed:
			velocity.x = move_toward(velocity.x, 0 * axis.x, 500 * delta)
			if axis.y >= 0:
				velocity.y = move_toward(velocity.y, 0 * axis.y, 1000 * delta)
			else:
				velocity.y = move_toward(velocity.y,0* axis.y,1400 * delta)
		#base movement
		if !Global.is_dashing:
			if !climbing_ledge:
				if direction:
					velocity.x = move_toward(velocity.x,direction * speed,1000* delta)
				else:
					velocity.x = move_toward(velocity.x, 0,1000 * delta)
		update_animations(direction)
	else: velocity *= 0
	move_and_slide()

func wall_slide_logic(delta):
	if is_on_wall_only() and velocity.y >= 0 and !just_dashed:
		if Input.is_action_pressed("Left") or Input.is_action_pressed("Right"):
			wall_sliding = true
		else: wall_sliding = false
	else: wall_sliding = false
	
	if wall_sliding:
		max_fall_speed = 80
	else:
		max_fall_speed = 240

func climbing_ledge_logic():
	if climbing_ledge:
		var tween = create_tween()
		player_body.disabled = true
		tween.tween_property(self,"position",ray_cast_3.get_collision_point(),.08)
		await tween.finished

func ledge_detection():
	if ray_cast_3.is_colliding() and !Global.is_dashing and can_ledge:
		if ray_cast_2.is_colliding() and !ray_cast_1.is_colliding():
			grabbing_ledge = true
			wall_sliding = false
			#jump_available = true
			can_dash = true
		if grabbing_ledge:
			velocity.y = 0
	else:
		grabbing_ledge = false

func wall_climbing_logic(delta):
	if grabbing_ledge:
		if Input.is_action_just_pressed("Down"):
			can_ledge = false
			await get_tree().create_timer(.1).timeout
			can_ledge = true

func get_input_axis():
	axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	axis = axis.normalized()
	
	if axis == Vector2.ZERO:
		if animated_sprite.flip_h:
			axis.x = -1
		else:
			axis.x = 1

func update_animations(direction):
	if grabbing_ledge or wall_climbing or climbing_ledge or wall_sliding:
		can_turn = false
	else: can_turn = true
	#sets the animation and direction of character
	if axis.x > 0 and can_turn:
		animated_sprite.offset.x = 0
		animated_sprite.flip_h = false
		ray_cast_container.scale.x = -1
	elif axis.x < 0 and can_turn:
		animated_sprite.offset.x = -34
		animated_sprite.flip_h = true
		ray_cast_container.scale.x = 1
		
	if !just_dashed:
		if grabbing_ledge:
			animated_sprite.play("Ledge_Grab")
		elif wall_sliding:
			animated_sprite.play("Wall_Sliding")
		else:
			if climbing_ledge:
				if animated_sprite.flip_h:
					#animated_sprite.offset.x = -25
					pass
				elif !animated_sprite.flip_h:
					#animated_sprite.offset.x = -10
					pass
				#animated_sprite.offset.y = 11.5
				animated_sprite.play("Mid_Jump")
				await animated_sprite.animation_finished
				player_body.disabled = false
				climbing_ledge = false
				#animated_sprite.offset.y = 0
			else:
				animated_sprite.offset.y = 0
				if is_on_floor():
					if direction == 0:
						animated_sprite.play("Idle")
					elif direction:
						animated_sprite.play("Run")
				else:
					if velocity.y >= 0:
						animated_sprite.play("Fall")
					elif velocity.y <= 0:
						animated_sprite.play("Jump")
	else: 
		animated_sprite.play("Dash")

func get_jump_gravity(velocity: Vector2):
	if velocity.y < 0:
		return gravity
	return fall_gravity

func get_gravity(delta):
	if !climbing_ledge:
		if !just_dashed:
			if not is_on_floor():
				if jump_available:
					if coyote_timer.is_stopped():
						coyote_timer.start(coyote_time)
				velocity.y += get_jump_gravity(velocity) * delta
				velocity.y = min(velocity.y,max_fall_speed)
			else: 
				jump_cut = true
				jump_available = true
				coyote_timer.stop()
				if jump_buffer:
					jump()
					jump_buffer = false

func jump():
	grabbing_ledge = false
	jump_available = false
	velocity.y = jump_velocity

func jump_logic():
	if Input.is_action_just_released("Jump") and velocity.y <= jump_velocity / 2 and jump_cut:
		velocity.y = jump_velocity / 2
	if Input.is_action_just_pressed("Jump"):
		if jump_available:
			jump_cut = true
			jump()
		elif !jump_available and is_on_wall() and Input.is_action_pressed("Right") and !climbing_ledge:
			velocity.y = -280
			velocity.x = -210
		elif !jump_available and is_on_wall() and Input.is_action_pressed("Left") and !climbing_ledge:
			velocity.y = -280
			velocity.x = 210
		else:
			jump_buffer = true
			get_tree().create_timer(jump_buffer_time).timeout.connect(jump_buffer_timeout)

	if !is_grounded and is_on_floor() and !climbing_ledge:
		var instance = dust.instantiate()
		instance.global_position = $Marker2D.global_position
		get_parent().add_child(instance)
	is_grounded = is_on_floor()

func new_dash(delta):
	velocity = Vector2.ZERO
	Global.is_dashing = true
	Global.hit_stop_short()
	wall_sliding = false
	just_dashed = true
	animation_player.play("camera_shake")
	dash_cooldown.start()
	dash_recover.start()
	can_dash = false
	jump_cut = false
	grabbing_ledge = false
	ghost_timer.start()
	
	if just_dashed:
		particles.emitting = true
	if axis.y and !axis.x:
		velocity.y = axis.y * dash_speed * 0.56* delta
	elif axis.x and !axis.y:
		velocity.x = axis.x * dash_speed *0.52* delta
	#regular dash logic
	else:
		velocity.x = axis.x * dash_speed * 0.66* delta
		velocity.y = axis.y * dash_speed * 0.72* delta
	await get_tree().create_timer(.12).timeout
	Global.is_dashing = false

func _on_dash_cooldown_timeout():
	particles.emitting = false
	just_dashed = false
	ghost_timer.stop()

func die():
	velocity = Vector2.ZERO
	dead = true
	animated_sprite.play("Die")
	await get_tree().create_timer(1).timeout
	Global.respawn_player()
	dead = false
	
func coyote_timeout():
	jump_available = false

func jump_buffer_timeout():
	jump_buffer = false

func add_ghost():
	var ghost = ghost_node.instantiate()
	ghost.set_property(position.x,position.y-9,animated_sprite.scale)
	get_tree().current_scene.add_child(ghost)
	if !animated_sprite.flip_h:
		ghost.position.x = position.x -10
		ghost.flip_h = false
	elif animated_sprite.flip_h:
		ghost.position.x = position.x +10
		ghost.flip_h = true
	if axis.y and !axis.x:
		if animated_sprite.flip_h:
			ghost.position.x = position.x +6
			ghost.flip_h = true
		else:
			ghost.position.x = position.x -6
			ghost.flip_h = false

func _on_ghost_timer_timeout():
	add_ghost()
