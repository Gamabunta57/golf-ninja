extends State

@export var jump_state: State
@export var idle_state: State
@export var move_state: State
@export var landing_state: State

@export var fall_gravity_multiplier: float = 0.5
@export var move_speed: float = 100
@export var max_speed: float = 60

var last_y_velocity: float = 0

func enter() -> void:
	super()

func process_input(event: InputEvent) -> State:
	if movement.get_jump() and parent.is_on_floor():
		return jump_state
	
	return null

func process_physics(delta: float) -> State:
	var x_input = movement.get_x_movement()
	
	parent.velocity.x += x_input * move_speed * delta
	parent.velocity.x = clamp(parent.velocity.x, -max_speed, max_speed)
	
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	
	if parent.velocity.y > 0:
		last_y_velocity = parent.velocity.y
	
	parent.move_and_slide()
	
	print(parent.velocity.x)
	
	if parent.is_on_floor():
		if is_zero_approx(parent.velocity.x):
			return idle_state
		elif not is_zero_approx(parent.velocity.x) and last_y_velocity < 100 and last_y_velocity != 0:
			print('skip landing')
			return move_state
		else:
			return landing_state
	
	#print(parent.velocity.x)
	
	return null
