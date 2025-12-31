extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State
@export var move_state: State
@export var teleport_state: State

func enter() -> void:
	super()
	parent.state = "player kunai state"
	Global.can_kunai = true
	parent.velocity = Vector2.ZERO
	parent.kunai_count += 1
	parent.kunai_cooldown_timer.start()
	Global.release_kunai = false

func process_physics(delta: float) -> State:
	parent.velocity = Vector2.ZERO
	
	if Global.kunai_is_anchored:
		return teleport_state
		
	if inputs.get_jump_just_release():
		Global.release_kunai = true
	
	if inputs.get_jump_input_just_pressed():
		if parent.is_on_floor():
			return idle_state
		else:
			return fall_state
	
	return null

func exit() -> void:
	parent.kunai_cooldown_timer.start()
	Global.kunai_cooldown_ongoing = true
	parent.global_position = Global.kunai_position
	parent.velocity = Vector2.ZERO
	Global.camera_mode = Global.CameraMode.PLAYER

func _on_damage_received() -> State:
	return hurt_state
