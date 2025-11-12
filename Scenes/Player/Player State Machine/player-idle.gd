extends State

@export var fall_state: State
@export var jump_state: State
@export var move_state: State
@export var hurt_state: State
@export var shooting_state: State

func enter() -> void:
	super()
	parent.velocity.x = 0

func process_input(event: InputEvent) -> State:
	if inputs.get_jump_input() and parent.is_on_floor() and parent.can_jump:
		return jump_state
		
	if inputs.get_x_input() != 0:
		return move_state
	
	if inputs.get_shooting_input() and parent.is_ball_nearby and not parent.cancel_shooting and not Global.player_hidden:
		return shooting_state
	
	return null

func process_physics(delta: float) -> State:
	if !parent.is_on_floor():
		return fall_state
	return null

func on_area_entered(body: Node2D) -> State:
	parent.last_attacker = body
	return hurt_state

func _on_damage_received() -> State:
	return hurt_state
