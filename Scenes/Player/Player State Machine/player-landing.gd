extends State

@export var idle_state: State
@export var jump_state: State
@export var move_state: State
@export var fall_state: State
@export var hurt_state: State

@export var deceleration: float = 400
@export var moving_threshold: float = 100

func process_physics(delta: float) -> State:
	var x_input = inputs.get_x_input()
	
	parent.velocity.x = movements.horizontal_deceleration(parent.velocity.x, delta)
	#move_toward(parent.velocity.x, 0, deceleration * delta)
	
	parent.move_and_slide()
		
	if parent.velocity.x == 0 and parent.is_on_floor():
		return idle_state
	
	if !parent.is_on_floor():
		return fall_state

	if x_input != 0 and abs(parent.velocity.x) <= moving_threshold and parent.is_on_floor():
		return move_state

	if inputs.get_jump_input() and parent.is_on_floor():
		return jump_state
	
	return null

func on_area_entered(body: Node2D) -> State:
	parent.last_attacker = body
	return hurt_state
