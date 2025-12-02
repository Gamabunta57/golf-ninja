extends State

@export var throw_state: State

var should_return: bool = false

func enter() -> void:
	super()
	parent.velocity = Vector2.ZERO

#func process_input(event: InputEvent) -> State:
	#return null

func process_physics(delta: float) -> State:
	parent.global_position = parent.player.global_position + parent.grapple_origin_offest
	parent.velocity = Vector2.ZERO
	
	parent.move_and_slide()
	
	if Global.can_grapple:
		return throw_state
	
	return null

func exit() -> void:
	pass
