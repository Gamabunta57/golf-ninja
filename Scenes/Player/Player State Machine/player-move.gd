extends State

@export var fall_state: State
@export var idle_state: State
@export var jump_state: State
@export var grappling_state: State
@export var hurt_state: State
@export var shooting_state: State

func enter() -> void:
	super()
	parent.velocity.y = 0
	Global.player_centric = true

func process_input(event: InputEvent) -> State:
	if inputs.get_shooting_input() and parent.is_ball_nearby and not parent.cancel_shooting:
		return shooting_state
	
	return null

func process_physics(delta: float) -> State:
	
	if inputs.get_x_input() != 0:
		parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)
	else:
		parent.velocity.x = movements.horizontal_deceleration(parent.velocity.x, delta)
	
	movements.flip_direction(inputs, parent)
	
	parent.move_and_slide()
	
	if parent.is_on_floor() and is_zero_approx(parent.velocity.x) and inputs.get_x_input() == 0:
		return idle_state
	
	if parent.velocity.y > 0 or !parent.is_on_floor():
		parent.should_coyote = true
		return fall_state
	
	if parent.can_grapple:
		return grappling_state
	
	#if inputs.get_jump_input() and parent.is_on_floor() and parent.can_jump and not parent.can_draw_grappling:
		#return jump_state
		
	return null
	
func _on_damage_received() -> State:
	return hurt_state
