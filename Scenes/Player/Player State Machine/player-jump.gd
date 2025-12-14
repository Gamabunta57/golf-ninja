extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State
@export var hurt_state: State
@export var slide_state: State
@export var jump_velocity_curve: Curve

@export var max_jump_time: float = 0.22
@export var max_jump_speed: float = 300.0

var time_elapsed: float = 0.0
var curve_ratio: float

func enter() -> void:
	super()
	print("jump state")
	Global.player_centric = true
	time_elapsed = 0.0
	curve_ratio = 1.0 / max_jump_time
	parent.is_jumping = true

func process_physics(delta: float) -> State:
	
	# 1. Update Jump Timer
	time_elapsed += delta
	
	# 2. Apply Velocity from Curve
	if time_elapsed < max_jump_time:
		# Note: We use sample() on the curve. 
		# Ensure your curve Y-axis goes from 0 to 1 (or -1 to 0 depending on setup)
		parent.velocity.y = -jump_velocity_curve.sample(time_elapsed * curve_ratio) * max_jump_speed
	else:
		return fall_state

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

func exit() -> void:
	print("exit jummp")

func _on_damage_received() -> State:
	return hurt_state
