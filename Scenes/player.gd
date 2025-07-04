extends CharacterBody2D

@export var horizontal_acceleration := 100
@export var horizontal_deceleration := 800
@export var max_horizontal_speed := 40
@export var jump_velocity := -40
@export var gravity_up := 150
@export var gravity_down := 300

func _ready() -> void:
	set_collision_mask_value(4, false)
	
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
	
		# Vertical Movement
	var y_input = Input.get_axis("down","up")
	
	#  Staircase collision
	if y_input < -0.5 :
		set_collision_mask_value(5, false)
	elif y_input > 0.5:
		set_collision_mask_value(4, true)
	else:
		set_collision_mask_value(5, true)
		set_collision_mask_value(4, false)
	move_and_slide()
