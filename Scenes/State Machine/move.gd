extends State

@export var fall_state: State
@export var idle_state: State
@export var jump_state: State

@export var move_speed: float = 100
@export var max_speed: float = 60
@export var deceleration: float = 300

func enter() -> void:
	super()
	parent.velocity.y = 0

func process_physics(delta: float) -> State:
	var x_input = movement.get_x_movement()
	var y_input = movement.get_y_movement()
	
	# HORIZONTAL MOVEMENT
	if x_input != 0:
		# --- SNAPPY DIRECTION CHANGE LOGIC ---
		if sign(x_input) != sign(parent.velocity.x) and not is_zero_approx(parent.velocity.x):
			# If we are changing direction, apply the strong deceleration to "brake" quickly.
			parent.velocity.x = move_toward(parent.velocity.x, 0, deceleration * delta)
		else:
			# Otherwise, apply normal acceleration.
			parent.velocity.x += x_input * move_speed * delta
		
		# Always clamp the velocity to the maximum speed.
		parent.velocity.x = clamp(parent.velocity.x, -max_speed, max_speed)
	else:
		# If there's no input, decelerate to a stop.
		parent.velocity.x = move_toward(parent.velocity.x, 0, deceleration * delta)
	
		#  Staircase collision
	if y_input < -0.5 :
		# move down the staircase
		parent.set_collision_mask_value(5, false)
		parent.set_collision_mask_value(3, true)

	elif y_input > 0.5:
		# move up the one way platform
		parent.set_collision_mask_value(4, true)
		parent.set_collision_mask_value(3, true)
		
	else:
		# reset collision
		parent.set_collision_mask_value(5, true)
		parent.set_collision_mask_value(4, false)
		parent.set_collision_mask_value(3, false)
	
	if parent.is_on_floor() and parent.velocity.x == 0 and x_input == 0:
		return idle_state
	
	if parent.velocity.y > 0 or !parent.is_on_floor():
		return fall_state
	
	if movement.get_jump() and parent.is_on_floor():
		return jump_state
	

	parent.move_and_slide()
	
	
	return null
