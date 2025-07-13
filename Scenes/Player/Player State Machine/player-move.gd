extends State

@export var fall_state: State
@export var idle_state: State
@export var jump_state: State

func enter() -> void:
	super()
	parent.velocity.y = 0

func process_physics(delta: float) -> void:
	
	if inputs.get_x_input() != 0:
		parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)
	else:
		parent.velocity.x = movements.horizontal_deceleration(parent.velocity.x, delta)
	
	if parent.is_on_floor() and is_zero_approx(parent.velocity.x) and inputs.get_x_input() == 0:
		change_state(idle_state)
		return
	
	if parent.velocity.y > 0 or !parent.is_on_floor():
		change_state(fall_state)
		return
	
	if inputs.get_jump_input() and parent.is_on_floor():
		change_state(jump_state)
		return
	
	parent.move_and_slide()
