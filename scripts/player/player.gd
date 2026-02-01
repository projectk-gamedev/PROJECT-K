extends CharacterBody2D

# --- CONFIGURATION ---
@export var speed = 300.0
@export var jump_velocity = -600.0
@export var gravity = 1500.0

# --- STATE MACHINE ---
enum { IDLE, RUN, JUMP, FALL, ATTACK }
var current_state = IDLE

# --- ATTACK CONFIG ---
var is_attacking = false

func _physics_process(delta):
	# 1. APPLY GRAVITY (Always active unless on a ladder/climbing)
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. STATE HANDLER (The Brain)
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
	
	# Debug Helper: This prints the state to the Output window so you know it works
	# print(current_state) 

# --- STATE LOGIC FUNCTIONS ---

func state_idle_logic(delta):
	# Slow down to 0
	velocity.x = move_toward(velocity.x, 0, speed)
	
	# Transition Checks
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(JUMP)
	elif Input.is_action_just_pressed("attack"):
		change_state(ATTACK)
	elif Input.get_axis("move_left", "move_right") != 0:
		change_state(RUN)
	elif not is_on_floor():
		change_state(FALL)

func state_run_logic(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		# Flip Sprite
		if direction < 0: $Sprite2D.flip_h = true
		else: $Sprite2D.flip_h = false
	else:
		change_state(IDLE) # Stop running if no input
		
	# Transition Checks
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(JUMP)
	elif Input.is_action_just_pressed("attack"):
		change_state(ATTACK)
	elif not is_on_floor():
		change_state(FALL)

func state_jump_logic(delta):
	# Initial Jump Force (Only happens once when entering state)
	# We handle the force in the change_state function for cleanliness
	
	# Air control (Optional: allow moving while jumping?)
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		
	if velocity.y > 0: # If we start falling down
		change_state(FALL)

func state_fall_logic(delta):
	# Air control
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		
	if is_on_floor():
		change_state(IDLE)

func state_attack_logic(delta):
	# FREEZE MOVEMENT while attacking
	velocity.x = move_toward(velocity.x, 0, speed)
	
	# 2. Turn ON the Hitbox
	$SwordHitbox.monitoring = true
	$Sprite2D.modulate = Color(1, 0, 0) # Red for feedback
	
	# 3. Wait for the swing to "finish"
	await get_tree().create_timer(0.3).timeout 
	
	# 4. Turn OFF the Hitbox
	$SwordHitbox.monitoring = false
	$Sprite2D.modulate = Color(1, 1, 1)
	change_state(IDLE)

# --- HELPER TO SWITCH STATES ---
func change_state(new_state):
	current_state = new_state
	
	# Special entry logic
	if new_state == JUMP:
		velocity.y = jump_velocity

func _on_sword_hitbox_area_entered(area):
	# Check if what we hit has a "take_damage" function
	if area.has_method("take_damage"):
		area.take_damage()
