extends RayCast2D


func _physics_process(delta: float) -> void:
	# Only run checks if we are actually grappling
	if Global.can_grapple and Global.grapple_body:
		
		# 1. Point the RayCast directly at the Harpoon
		target_position = to_local(Global.grapple_body.global_position)
		
		# Force update to get immediate results this frame
		force_raycast_update()
		
		# 2. Check for Obstacles
		if is_colliding():
			# We hit a wall between player and harpoon!
			# Immediate consequence: Cut the rope.
			Global.can_grapple = false
	else:
		target_position = Vector2.ZERO
	
	queue_redraw()

func _draw() -> void:
	if Global.grapple_body:
		draw_line(Vector2.ZERO, to_local(Global.grapple_body.global_position), Color(1,1,1), 1.0)
