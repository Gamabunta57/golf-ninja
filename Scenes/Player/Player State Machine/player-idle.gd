extends State

@export var fall_state: State
@export var jump_state: State
@export var move_state: State

func enter() -> void:
	super()
	parent.velocity.x = 0

func process_input(event: InputEvent) -> void:
	if inputs.get_jump_input() and parent.is_on_floor():
		change_state(jump_state)
		return
		
	if inputs.get_x_input() != 0:
		change_state(move_state)
		return

func process_physics(delta: float) -> void:
	#parent.velocity.y += gravity * delta
	#parent.move_and_slide()
	if !parent.is_on_floor():
		change_state(fall_state)
