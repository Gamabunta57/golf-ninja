extends State

@export var idle_state: State
@export var jump_state: State
@export var move_state: State
@export var fall_state: State
@export var deceleration: float = 400

func process_physics(delta: float) -> State:
	var x_input = movement.get_x_movement()
	
	parent.velocity.x = move_toward(parent.velocity.x, 0, deceleration * delta)
	
	parent.move_and_slide()
		
	if parent.velocity.x == 0 and parent.is_on_floor():
		return idle_state
	
	if !parent.is_on_floor():
		return fall_state
	
	if x_input != 0 and abs(parent.velocity.x) <= 10 and parent.is_on_floor():
		return move_state

	if movement.get_jump() and parent.is_on_floor():
		return jump_state
	
	return null
