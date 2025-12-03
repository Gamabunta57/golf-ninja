extends State

@export var idle_state: State
@export var rewind_speed: float = 800

var should_return: bool = false

func enter() -> void:
	super()
	#print("grapple rewind state")
	Global.grapple_is_anchored = false
	parent.set_collision_mask_value(2, false)

#func process_input(event: InputEvent) -> State:
	#return null

func process_physics(delta: float) -> State:
	var remaining_distance: float = (Global.player_body.global_position - parent.global_position).length()
	
	#if Global.rope_points.is_empty():
	var dir: Vector2 = (Global.player_body.global_position - parent.global_position).normalized()
	parent.velocity = dir * rewind_speed
	
	parent.move_and_slide()
	
	if remaining_distance < 25:
		return idle_state
	
	return null

func exit() -> void:
	parent.set_collision_mask_value(2, true)
	pass
