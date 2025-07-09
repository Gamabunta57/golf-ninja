extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State

@export var jump_force: float = 60
@export var jump_gravity_multiplier: float = 0.3

@export var move_speed: float = 50
@export var max_speed: float = 40

func enter() -> void:
	super()
	parent.velocity.y = -jump_force

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * jump_gravity_multiplier * delta
	
	var x_input = Input.get_axis("left", "right")

	parent.velocity.x += x_input * move_speed * delta
	parent.velocity.x = clamp(parent.velocity.x, -max_speed, max_speed)
	
	if parent.velocity.y > 0:
		return fall_state
		
	parent.move_and_slide()
	
	if parent.is_on_floor():
		if parent.velocity.x != 0:
			return move_state
		return idle_state
	
	return null
