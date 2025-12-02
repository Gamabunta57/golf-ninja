extends State

@export var rewind_state: State

var should_return: bool = false

func enter() -> void:
	parent.global_position = parent.anchor_position
	super()

#func process_input(event: InputEvent) -> State:
	#return null

func process_physics(delta: float) -> State:
	if not Global.grapple_is_anchored or not Global.can_grapple:
		return rewind_state

	return null

func exit() -> void:
	pass
