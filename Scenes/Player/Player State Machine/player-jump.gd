
extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State
@export var hurt_state: State
@export var jump_velocity_curve: Curve

@export var max_jump_time: float = 0.2       
@export var max_jump_speed: float = 510.0

var time_elapsed: float = 0.0 
var curve_ratio: float

func enter() -> void:
	super()
	time_elapsed = 0.0
	curve_ratio = 1/max_jump_time

func process_physics(delta: float) -> State:
	
	if time_elapsed < max_jump_time:
		time_elapsed += delta
		parent.velocity.y = -jump_velocity_curve.sample(time_elapsed * curve_ratio) * max_jump_speed
	else:
		return fall_state
	
	parent.move_and_slide()
	
	if inputs.get_jump_release() or time_elapsed == max_jump_time:
		return fall_state
	
	
	if parent.is_on_floor():
		if parent.velocity.x != 0:
			return move_state
		return idle_state
	
	return null

func _on_damage_received() -> State:
	return hurt_state
