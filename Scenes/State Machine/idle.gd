extends State

@export var fall_state: State
@export var jump_state: State
@export var move_state: State

func enter() -> void:
	super()
	parent.velocity.x = 0

func process_input(event: InputEvent) -> State:
	if inputs.get_jump_input() and parent.is_on_floor():
		return jump_state
		
	if inputs.get_x_input() != 0:
		return move_state
	
	return null

func process_physics(delta: float) -> State:
	#parent.velocity.y += gravity * delta
	#parent.move_and_slide()
	if !parent.is_on_floor():
		return fall_state
	return null
