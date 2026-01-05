extends State

@export var throw_state: State

func enter() -> void:
	super()
	parent.state = "kunai idle state"
	parent.global_position = parent.player.global_position
	parent.velocity = Vector2.ZERO
	parent.rotation = 0
	parent.kunai_anchored = false
	parent.sprite.hide()
	Global.kunai_position = Vector2.ZERO
	Global.kunai_rotation_valid = false
	
func process_physics(delta: float) -> State:
	parent.global_position = parent.player.global_position
	parent.velocity = Vector2.ZERO
	
	
	parent.move_and_slide()
	
	if Global.can_kunai and not Global.kunai_cooldown_ongoing:
		Global.kunai_cooldown_ongoing = false
		return throw_state
	
	return null

func exit() -> void:
	pass
