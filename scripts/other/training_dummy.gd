extends Area2D

func take_damage():
	print("Dummy Hit!")
	# Visual feedback: Flash the dummy white
	modulate = Color(10, 10, 10) # Overbright white
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
func _ready():
	# Force the flash as soon as the game starts
	print("TEST: Attempting Flash...")
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	print("TEST: Flash complete.")
