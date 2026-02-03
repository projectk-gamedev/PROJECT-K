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
	# 1. MOVEMENT (Keep current speed but allow flipping)
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.flip_h = direction < 0
		# FIX: Move the hitbox to face the right way!
		if has_node("SwordHitbox"):
			$SwordHitbox.position.x = abs($SwordHitbox.position.x) * (direction)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# 2. START ATTACK (If not already mid-swing)
	if not is_attacking:
		is_attacking = true
		_play_animation("attack_needle")
		$AnimatedSprite2D.modulate = Color(1, 0, 0) # RESTORED: Visual feedback
		
		# 3. ENABLE HITBOX
		if has_node("SwordHitbox"):
			$SwordHitbox.monitoring = true
		
		# 4. SWING DURATION
		await get_tree().create_timer(0.4).timeout 
		
		# 5. RESET EVERYTHING
		if has_node("SwordHitbox"):
			$SwordHitbox.monitoring = false
		
		$AnimatedSprite2D.modulate = Color(1, 1, 1) # RESTORED: Reset color
		is_attacking = false
		
		# Return to appropriate state
		if Input.get_axis("move_left", "move_right") != 0:
			change_state(RUN)
		else:
			change_state(IDLE)

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
	print("SWORD TOUCHED: ", area.name) # This will tell us IF a collision happened
	if area.has_method("take_damage"):
		area.take_damage()
		
# Inside player.gd
# Inside player.gd - This MUST have 'source_pos' inside the brackets
# Inside player.gd
# Inside player.gd
# Inside player.gd
func take_damage(source_pos: Vector2): 
	# The 'source_pos' above is the CRITICAL part. 
	# It allows the Player to "catch" the position the Guard is sending.
	
	print("Player hit logic triggered!")
	
	# Knockback: Calculate direction away from the enemy
	var knockback_dir = (global_position - source_pos).normalized()
	velocity = knockback_dir * 600
	move_and_slide()
	
	# Visual feedback: Flash the sprite white
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.modulate = Color(10, 10, 10)
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate = Color(1, 1, 1)
