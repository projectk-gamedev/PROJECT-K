extends CharacterBody2D

# 1. Variables - Defined clearly to prevent 'Nil' errors
var speed = 150.0
var gravity = 1500.0
var direction = 1

# 2. Node References - Ensure these names match your Scene Tree exactly!
@onready var edge_check = $EdgeCheck
@onready var visual = $ColorRect 

func _physics_process(delta):
	# Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Patrol Logic: Flip if we hit a wall or see a ledge
	if not edge_check.is_colliding() or is_on_wall():
		direction *= -1
		# Move the RayCast to the new 'front' side
		edge_check.position.x = 25 * direction 

	velocity.x = direction * speed
	move_and_slide()

# Called when the Player's sword hits the Guard's Hurtbox
func take_damage():
	print("Guard took a hit!")
	# Use 'visual' because the Guard is currently a ColorRect
	if visual:
		visual.color = Color(10, 10, 10) # Flash white
		await get_tree().create_timer(0.1).timeout
		visual.color = Color(0.5, 0, 0.5) # Back to Purple

# Connected via the 'body_entered' signal of the ContactDamageArea
func _on_contact_damage_area_body_entered(body):
	# Check if the thing we touched is the Player and has the damage function
	if body.has_method("take_damage"):
		# We MUST pass (global_position) because the Player expects it
		body.take_damage(global_position)
