extends State

@export var idle_state: State
var time_ellapsed: float = 0.0

func enter() -> void:
	super()
	parent.state = "kunai anchor state"
	parent.velocity = Vector2.ZERO
	Global.kunai_is_anchored = true
	#print(Global.player_body.rotation)
	parent.velocity = Vector2.ZERO
	time_ellapsed = 0.0

func process_physics(delta: float) -> State:
	parent.velocity = Vector2.ZERO
	
	if not Global.can_kunai:
		time_ellapsed += delta
		if time_ellapsed >= 0.2:
			return idle_state
	
	return null

func exit() -> void:
	time_ellapsed = 0.0
