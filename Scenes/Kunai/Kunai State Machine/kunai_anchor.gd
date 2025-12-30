extends State

@export var idle_state: State

func enter() -> void:
	super()
	parent.state = "kunai anchor state"
	#parent.anchor_position = parent.global_position
	parent.velocity = Vector2.ZERO
	Global.kunai_is_anchored = true

func process_physics(delta: float) -> State:
	parent.velocity = Vector2.ZERO
	
	if not Global.can_kunai:
		return idle_state
	
	return null

func exit() -> void:
	pass
