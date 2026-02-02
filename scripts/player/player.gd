extends CharacterBody2D

# --- CONFIGURATION ---
@export var speed = 300.0
@export var jump_velocity = -600.0
@export var gravity = 1500.0

# --- STATE MACHINE ---
enum { IDLE, RUN, JUMP, FALL, ATTACK }
var current_state = IDLE
var is_attacking = false

func _physics_process(delta):
	# Apply Gravity
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
	_play_animation("idle_needle")
	velocity.x = move_toward(velocity.x, 0, speed)
	
	if Input.is_action_just_pressed("attack"): 
		change_state(ATTACK)
	elif Input.get_axis("move_left", "move_right") != 0:
		change_state(RUN)
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(JUMP)
	elif not is_on_floor():
		change_state(FALL)

func state_run_logic(delta):
	# Use idle animation while running so it doesn't freeze
	_play_animation("idle_needle") 
	
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		change_state(IDLE)
	
	if Input.is_action_just_pressed("attack"): 
		change_state(ATTACK)
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(JUMP)
	elif not is_on_floor():
		change_state(FALL)

func state_jump_logic(delta):
	$AnimatedSprite2D.stop()
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.flip_h = direction < 0
			
	if velocity.y > 0:
		change_state(FALL)

func state_fall_logic(delta):
	$AnimatedSprite2D.stop()
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.flip_h = direction < 0
			
	if is_on_floor():
		change_state(IDLE)

func state_attack_logic(delta):
	# 1. MOVEMENT LOGIC (Runs every frame)
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# 2. GHOST TIMER LOCK (Prevents spamming)
	if is_attacking:
		return

	# 3. START ATTACK
	is_attacking = true
	_play_animation("attack_needle")
	
	# Try to enable hitbox if it exists, but don't crash if it's missing/misnamed
	if has_node("SwordHitbox"):
		$SwordHitbox.monitoring = true
	elif has_node("Swordhitbox"):
		$Swordhitbox.monitoring = true
	
	# Wait for animation
	await get_tree().create_timer(0.4).timeout 
	
	# 4. FINISH
	if has_node("SwordHitbox"):
		$SwordHitbox.monitoring = false
	elif has_node("Swordhitbox"):
		$Swordhitbox.monitoring = false
		
	is_attacking = false
	
	# Check input to decide next state
	var fresh_direction = Input.get_axis("move_left", "move_right")
	if fresh_direction:
		change_state(RUN)
	else:
		change_state(IDLE)

# --- THE HELPERS ---

func change_state(new_state):
	current_state = new_state
	if new_state == JUMP:
		velocity.y = jump_velocity

func _play_animation(anim_name: String):
	if $AnimatedSprite2D.animation != anim_name:
		$AnimatedSprite2D.play(anim_name)
	elif not $AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play(anim_name)

# Make sure to connect this signal in the Editor later when you are ready!
func _on_sword_hitbox_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage()
