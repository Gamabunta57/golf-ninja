extends State

@export var jump_state: State
@export var idle_state: State
@export var move_state: State
@export var landing_state: State
@export var landing_threshold: float = 600
@export var fall_gravity_multiplier: float = 2

var last_y_velocity: float = 0

func enter() -> void:
	super()

func process_input(event: InputEvent) -> void:
	if inputs.get_jump_input() and parent.is_on_floor():
		change_state(jump_state)


func process_physics(delta: float) -> void:
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)

	if parent.velocity.y > 0:
		last_y_velocity = parent.velocity.y
	
	parent.move_and_slide()
	
	if parent.is_on_floor():
		if is_zero_approx(parent.velocity.x):
			change_state(idle_state)
		elif not is_zero_approx(parent.velocity.x) and last_y_velocity < landing_threshold and last_y_velocity != 0:
			change_state(move_state)
		else:
			change_state(landing_state)
