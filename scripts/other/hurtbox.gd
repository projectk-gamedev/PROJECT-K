extends Area2D

func take_damage():
	# This sends the hit signal up to the main HollowGuard script
	get_parent().take_damage()
