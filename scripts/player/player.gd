extends CharacterBody2D

# --- CONFIGURATION ---
@export var speed = 300.0
@export var jump_velocity = -600.0
@export var gravity = 1500.0

# --- STATE MACHINE ---
enum { IDLE, RUN, JUMP, FALL, ATTACK }
var current_state = IDLE

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	match current_state:
		IDLE:
			state_idle_logic(delta)
		RUN:
			state_run_logic(delta)
		JUMP:
			state_jump_logic(delta)
		FALL:
			state_fall_logic(delta)
		ATTACK:
			state_attack_logic(delta)
	
	move_and_slide()

# --- STATE LOGIC ---

func state_idle_logic(delta):
	# START playing when idle
	_play_animation("idle")
	
	velocity.x = move_toward(velocity.x, 0, speed)
	
	if Input.get_axis("move_left", "move_right") != 0:
		change_state(RUN)
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(JUMP)
	elif not is_on_floor():
		change_state(FALL)

func state_run_logic(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.flip_h = direction < 0
		# STOP playing while running (since no walk animation)
		$AnimatedSprite2D.stop() 
	else:
		change_state(IDLE)
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(JUMP)
	elif not is_on_floor():
		change_state(FALL)

func state_jump_logic(delta):
	$AnimatedSprite2D.stop() # Freeze while in air
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
	if velocity.y > 0:
		change_state(FALL)

func state_fall_logic(delta):
	$AnimatedSprite2D.stop() # Freeze while falling
	if is_on_floor():
		change_state(IDLE)

func state_attack_logic(delta):
	_play_animation("idle")
	# (Your attack timer logic here...)
	change_state(IDLE)

# --- THE HELPERS ---

func change_state(new_state):
	current_state = new_state
	if new_state == JUMP:
		velocity.y = jump_velocity

func _play_animation(anim_name: String):
	# This line is the key: if it's already playing, do nothing.
	# If it's NOT playing, start it.
	if not $AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != anim_name:
		$AnimatedSprite2D.play(anim_name)
