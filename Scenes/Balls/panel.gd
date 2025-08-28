extends Panel

func _process(delta: float) -> void:
	# Keep the panel always upright
	self.rotation = 0.0
	
	# Keep the panel above the ball
	#var offset: Vector2 = Vector2(0, -50) # adjust Y offset to your liking
	#self.global_position = global_position + offset
