extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State
@export var move_state: State
@export var teleport_state: State

@export var kunai_max_reach: float = 250

var kunai_distance: float = 0.0

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
	kunai_distance = parent.global_position.distance_to(Global.kunai_position)
	
	if kunai_distance >= kunai_max_reach:
		Global.kunai_stop_throw = true
	
	if Global.kunai_is_anchored:
		return teleport_state
		
	if not inputs.get_jump_input():
		if kunai_distance > 200:
			Global.release_kunai = true
			if parent.is_on_floor():
				return idle_state
			else:
				return fall_state
	
	return null

func exit() -> void:
	exit_kunai()

func _on_damage_received() -> State:
	return hurt_state
	
func exit_kunai() -> void:
	parent.kunai_cooldown_timer.start()
	Global.kunai_cooldown_ongoing = true
	parent.global_position = Global.kunai_position
	parent.velocity = Vector2.ZERO
	Global.camera_mode = Global.CameraMode.PLAYER
	kunai_distance = 0.0
	Global.kunai_stop_throw = false
