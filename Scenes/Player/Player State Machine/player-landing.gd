extends State

@export var idle_state: State
@export var jump_state: State
@export var move_state: State
@export var fall_state: State
@export var deceleration: float = 400
@export var moving_threshold: float = 100

func process_physics(delta: float) -> void:
	var x_input = inputs.get_x_input()
	
	parent.velocity.x = movements.horizontal_deceleration(parent.velocity.x, delta)
	#move_toward(parent.velocity.x, 0, deceleration * delta)
	
	parent.move_and_slide()
		
	if parent.velocity.x == 0 and parent.is_on_floor():
		change_state(idle_state)
	
	elif !parent.is_on_floor():
		change_state(fall_state)

	elif x_input != 0 and abs(parent.velocity.x) <= moving_threshold and parent.is_on_floor():
		change_state(move_state)

	elif inputs.get_jump_input() and parent.is_on_floor():
		change_state(jump_state)
