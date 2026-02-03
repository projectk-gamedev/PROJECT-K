extends CharacterBody2D

# --- VARIABLES ---
var speed = 150.0
var chase_speed = 200.0
var gravity = 1500.0
var knockback_force = 300.0
var direction = 1

# State Flags
var player = null          # For detecting/chasing
var player_in_range = null # For damaging the player
var is_hurt = false        
var can_hit_player = true  # Cooldown flag

# --- NODES ---
@onready var edge_check = $EdgeCheck
@onready var visual = $ColorRect 
@onready var detection_area = $DetectionArea 

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. CONTINUOUS DAMAGE CHECK (With Range Fail-Safe)
	if player_in_range and can_hit_player:
		# CHECK: Are they actually close enough? (e.g., 60 pixels)
		var distance = global_position.distance_to(player_in_range.global_position)
		
		if distance > 60: 
			# Player is too far! Force the enemy to forget them.
			print("Player out of range - Stopping attack loop")
			player_in_range = null 
		else:
			# Player is close, hit them!
			damage_player()

	# 3. If we are hurt... (The rest of your code is fine)
	if is_hurt:
		move_and_slide()
		return 

	# 4. Movement Logic (Chase or Patrol)
	if player:
		# Chase
		direction = position.direction_to(player.position).x
		if direction > 0:
			velocity.x = chase_speed
			direction = 1
		else:
			velocity.x = -chase_speed
			direction = -1
	else:
		# Patrol
		if not edge_check.is_colliding() or is_on_wall():
			direction *= -1
			edge_check.position.x = 25 * direction 
		velocity.x = direction * speed

	move_and_slide()

# --- NEW FUNCTION: HANDLES DAMAGING THE PLAYER ---
func damage_player():
	if player_in_range.has_method("take_damage"):
		# Send enemy position for knockback
		player_in_range.take_damage(global_position)
		
		# Start Cooldown
		can_hit_player = false
		print("Hit Player! Cooldown started.")
		
		# Cooldown is now 0.5 seconds
		await get_tree().create_timer(0.5).timeout 
		can_hit_player = true

# --- HITTING THE PLAYER SIGNALS (UPDATED) ---
# Connect these to your ContactDamageArea
func _on_contact_damage_area_body_entered(body):
	if body.name == "Player":
		player_in_range = body # Remember that the player is touching us

func _on_contact_damage_area_body_exited(body):
	if body.name == "Player":
		player_in_range = null # Player left, stop trying to hit them

# --- HIT BY PLAYER LOGIC (When Enemy takes damage) ---
# NEW/FIXED (No arguments inside the parentheses)
func take_damage():
	print("Guard took a hit!")
	
	# 1. Flash White
	if visual:
		visual.color = Color(10, 10, 10) 
		await get_tree().create_timer(0.1).timeout
		visual.color = Color(0.5, 0, 0.5)
# --- DETECTION AREA SIGNALS ---

func _on_detection_area_body_entered(body):
	if body.name == "Player":
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null
