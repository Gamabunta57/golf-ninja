extends State

@export var jump_state: State
@export var idle_state: State
@export var move_state: State
@export var landing_state: State

@export var fall_gravity_multiplier: float = 0.5

var last_y_velocity: float = 0

func enter() -> void:
	super()

func process_input(event: InputEvent) -> State:
	if inputs.get_jump_input() and parent.is_on_floor():
		return jump_state
	
	return null

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)

	if parent.velocity.y > 0:
		last_y_velocity = parent.velocity.y
	
	parent.move_and_slide()
	
	
	if parent.is_on_floor():
		if is_zero_approx(parent.velocity.x):
			return idle_state
		elif not is_zero_approx(parent.velocity.x) and last_y_velocity < 100 and last_y_velocity != 0:
			return move_state
		else:
			return landing_state
	
	return null
