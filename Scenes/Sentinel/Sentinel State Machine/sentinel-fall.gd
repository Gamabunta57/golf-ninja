extends State

@export var idle_state: State
@export var landing_threshold: float = 600


@export var fall_gravity_multiplier: float = 2

var last_y_velocity: float = 0

func enter() -> void:
	super()

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	
	parent.move_and_slide()
	
	if parent.is_on_floor():
		return idle_state
	
	return null
