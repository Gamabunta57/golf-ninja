extends CharacterBody2D

@export var horizontal_acceleration := 100
@export var horizontal_deceleration := 800
@export var max_horizontal_speed := 40
@export var jump_velocity := -50
@export var gravity_up := 150
@export var gravity_down := 300


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += gravity_up * delta
		else:
			velocity.y += gravity_down * delta
	# Horizontal Movement
	var x_input = Input.get_axis("left", "right")
	
	if x_input != 0:
		velocity.x += x_input * horizontal_acceleration * delta
		velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, horizontal_deceleration * delta)
	
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Down the one-way
	if Input.is_action_just_pressed("down") and is_on_floor():
		print('down')
		
		velocity.y = 1


	move_and_slide()
