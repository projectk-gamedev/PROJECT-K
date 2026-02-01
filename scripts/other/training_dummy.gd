extends Area2D

func take_damage():
	print("Dummy Hit!")
	# Visual feedback: Flash the dummy white
	modulate = Color(10, 10, 10) # Overbright white
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
