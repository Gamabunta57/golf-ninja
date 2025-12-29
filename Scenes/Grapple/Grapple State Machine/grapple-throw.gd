extends State

@export var anchor_state: State
@export var idle_state: State
@export var rewind_state: State
@export var speed: float = 4000

func enter() -> void:
	print("Grapple Throw State")
	super()
	parent.global_position = parent.player.global_position + parent.grapple_origin_offest

#func process_input(event: InputEvent) -> State:
	#return null

func process_physics(delta: float) -> State:
	
	var movement_vector = Vector2(parent.grapple_angle.x * Global.direction * speed * delta, parent.grapple_angle.y * speed * delta)
	
	var collision = parent.move_and_collide(movement_vector)
	
	if collision: 
		parent.anchor_position = parent.global_position
		parent.velocity = Vector2.ZERO
		Global.grapple_is_anchored = true
		return anchor_state
	
	if not Global.can_grapple:
		if parent.global_position.distance_to(Global.player_body.global_position) < 1.0:
			return idle_state
		else:
			return rewind_state
	
	return null

func exit() -> void:
	pass
