
extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State
@export var hurt_state: State

@export var initial_jump_force: float = 400
@export var jump_gravity_multiplier: float = 0.9

func enter() -> void:
	super()
	parent.velocity.y = -initial_jump_force

func process_physics(delta: float) -> State:
		
	parent.velocity.y -= 300 * delta

	parent.velocity.y += gravity * jump_gravity_multiplier * delta
	parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)
	
	parent.direction = sign(inputs.get_x_input())
	
	parent.move_and_slide()
	
	if inputs.get_jump_release():
		return fall_state
	
	if parent.velocity.y >= 0:
		return fall_state
		
	
	if parent.is_on_floor():
		if parent.velocity.x != 0:
			return move_state
		return idle_state
	
	return null

func _on_damage_received() -> State:
	return hurt_state
