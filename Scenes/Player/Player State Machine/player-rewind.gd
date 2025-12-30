extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State
@export var move_state: State
@export var grappling_max_speed := 900

func enter() -> void:
	super()
	parent.state = "player rewind state"
	Global.player_centric = true

func process_physics(delta: float) -> State:
	
	# 1. Target is always the Grapple Body
	var target_pos = parent.grapple_body.global_position
	var distance_to_target = parent.global_position.distance_to(target_pos)
	
	# 2. Check if reached the Harpoon
	if distance_to_target < 10:
		parent.velocity = Vector2.ZERO
		#Global.can_grapple = false # Force exit
	else:
		# Move directly towards target
		var dir: Vector2 = (target_pos - parent.global_position).normalized()
		parent.velocity = dir * grappling_max_speed
	
	parent.move_and_slide()
	
	# 3. Exit Conditionsget_jump_just_release()
	# If the rope_collision detected a wall mid-rewind, Global.can_grapple becomes false
	if inputs.get_jump_just_release():
		Global.can_grapple = false
		if parent.is_on_floor():
			if parent.velocity.x != 0:
				return move_state
			else:
				return idle_state
		else:
			return fall_state
	
	return null

func exit() -> void:
	parent.velocity *= 0.5

func _on_damage_received() -> State:
	return hurt_state
