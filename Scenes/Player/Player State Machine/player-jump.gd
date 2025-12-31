extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State
@export var hurt_state: State
@export var slide_state: State

@export var max_jump_time: float = 0.22
@export var max_jump_speed: float = 400.0

@export var move_speed: float = 600
@export var max_speed: float = 400
@export var deceleration: float = 12000

var time_elapsed: float = 0.0
var curve_ratio: float

func enter() -> void:
	super()
	parent.state = "player jump state"
	parent.jump_count += 1
	time_elapsed = 0.0
	parent.is_jumping = true
	parent.is_jump_released = false

func process_physics(delta: float) -> State:
	
	# 1. Update Jump Timer
	time_elapsed += delta
	
	if not inputs.get_jump_input():
		parent.is_jump_released = true
		
	# 2. Apply Velocity from Curve
	if time_elapsed < max_jump_time:
		parent.velocity.y = -(time_elapsed / max_jump_time) * max_jump_speed
	else:
		return fall_state
	
	if inputs.get_x_input() != 0:
		parent.velocity.x = movements.horizontal_movement(parent.velocity.x, deceleration, move_speed, max_speed, delta, inputs)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, deceleration * delta)
	
	parent.move_and_slide()
	
	# 3. Handle Jump Release (Variable Jump Height)
	# Using >= is safer for floats than ==
	if inputs.get_jump_just_release() or time_elapsed >= max_jump_time:
		return fall_state

	# 4. Ceiling Check
	# If we hit a ceiling while jumping, we should stop jumping and fall.
	if parent.is_on_ceiling():
		parent.velocity.y = 0
		return fall_state

	# 5. Floor Check (The Fix)
	# Only check for landing if we have been jumping for at least 0.1 seconds.
	# This prevents the "instant cancel" bug at the start of the jump.
	if time_elapsed > 0.1:
		if parent.is_on_floor():
			if parent.velocity == Vector2.ZERO:
				return idle_state
			else:
				if parent.get_floor_angle() < 1:
					return move_state
				else:
					return slide_state

	return null

func _on_damage_received() -> State:
	return hurt_state
