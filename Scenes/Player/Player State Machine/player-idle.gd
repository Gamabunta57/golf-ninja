extends State

@export var fall_state: State
@export var jump_state: State
@export var grappling_state: State
@export var move_state: State
@export var hurt_state: State
@export var shooting_state: State
@export var slide_state: State
@export var wall_collider : RayCast2D

func enter() -> void:
	super()
	#print("idle_state")
	parent.velocity.x = 0


func process_physics(delta: float) -> State:
	if inputs.get_x_input() != 0:
		return move_state
	
	if inputs.get_shooting_input() and parent.is_ball_nearby and not parent.cancel_shooting:
		return shooting_state
	
	if !parent.is_on_floor():
		return fall_state
	
	if parent.can_jump:
		return jump_state
	
	if Global.can_grapple:
		return grappling_state
	
	
	if parent.is_on_floor() and parent.get_floor_angle() > 1:
		return slide_state
		
	return null

func on_area_entered(body: Node2D) -> State:
	parent.last_attacker = body
	return hurt_state

func _on_damage_received() -> State:
	return hurt_state
