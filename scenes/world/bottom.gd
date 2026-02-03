extends Area2D

func _on_body_entered(body):
	# Print to console so we know the physics worked
	print("ENTITY DETECTED BY KILLPLANE: ", body.name)
	
	# Check if the thing that fell is actually the player
	if body is CharacterBody2D: 
		print("Player fell! Reloading...")
		get_tree().reload_current_scene()
