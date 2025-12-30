extends State

@export var throw_state: State

func enter() -> void:
	super()
	parent.state = "kunai idle state"
	parent.global_position = Global.player_body.global_position + parent.kunai_origin_offset
	parent.velocity = Vector2.ZERO
	parent.rotation = 0
	parent.kunai_anchored = false

func process_physics(delta: float) -> State:
	parent.global_position = Global.player_body.global_position + parent.kunai_origin_offset
	parent.velocity = Vector2.ZERO
	
	parent.move_and_slide()
	
	if Global.can_kunai and not Global.kunai_cooldown_ongoing:
		Global.kunai_cooldown_ongoing = false
		return throw_state
	
	return null

func exit() -> void:
	pass
