extends State

@export var fall_state: State
@export var patrol_state: State
@export var chase_state: State
@export var attack_state: State

func enter() -> void:
	super()
	parent.velocity.x = 0



func process_physics(delta: float) -> State:
	if !parent.is_on_floor():
		return fall_state
	return null
