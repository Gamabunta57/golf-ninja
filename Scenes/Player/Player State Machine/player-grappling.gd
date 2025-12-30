extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State
@export var move_state: State
@export var rewind_state: State
@export var rope_collision: RayCast2D
@export var wall_collider : RayCast2D
@export var fall_gravity_multiplier: float = 0.5
@export var grappling_max_speed := 600.0 # Standardize speed

func enter() -> void:
	super()
	parent.state = "player grappling state"
	Global.player_centric = true
	# No need to clear points array anymore

func process_physics(delta: float) -> State:
	if inputs.get_jump_just_release():
		Global.can_grapple = false
		return fall_state
	
	# 1. Handle "Hit Wall" Logic (Stop player if they bump into something)
	if wall_collider.is_colliding():
		parent.velocity = Vector2.ZERO
	
	# 2. Handle Swing/Dampening (Optional, kept from your code)
	if sign(parent.velocity.x) == sign(inputs.get_x_input()):
		parent.velocity.x = move_toward(parent.velocity.x, 0, 300 * delta)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, 3000 * delta)
	
	#print(parent.velocity.y)
	parent.velocity.y = move_toward(parent.velocity.x, 0, delta)
	
	movements.flip_direction(inputs)
	parent.move_and_slide()
	
	# 3. Check Distance (Simple direct distance)
	var rope_distance = parent.global_position.distance_to(parent.grapple_body.global_position)
	
	# 4. Exit Conditions
	if not Global.can_grapple or rope_distance >= (Global.grapple_distance + 30):
		Global.grapple_is_anchored = false
		
		if parent.is_on_floor():
			if parent.velocity.x != 0:
				return move_state
			else:
				return idle_state
		else:
			return fall_state
			
	# 5. Handle Rewind Trigger (If harpoon hit the wall)
	if Global.grapple_is_anchored:
		return rewind_state
	
	return null

func exit() -> void:
	Global.grapple_cooldown_ongoing = true

func _on_damage_received() -> State:
	return hurt_state
