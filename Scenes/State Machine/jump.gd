
extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State

@export var jump_force: float = 400
@export var jump_gravity_multiplier: float = 1.7


func enter() -> void:
	super()
	parent.velocity.y = -jump_force

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * jump_gravity_multiplier * delta
	parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)

	var x_input = inputs.get_x_input()

	
	if parent.velocity.y > 0:
		return fall_state
		
	parent.move_and_slide()
	
	if parent.is_on_floor():
		if parent.velocity.x != 0:
			return move_state
		return idle_state
	
	return null
