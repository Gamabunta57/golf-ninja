extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State

var original_rotation : float = 0.0

func enter() -> void:
	super()
	parent.state = "player teleport state"
	
	parent.set_collision_mask_value(2, false)
	
	original_rotation = parent.rotation
	
	parent.rotation = Global.kunai_normal.angle() + (PI / 2)
	parent.global_position -= Global.kunai_normal * 7
	

func process_physics(delta: float) -> State:
	parent.velocity = Vector2.ZERO
	
	if inputs.get_jump_just_release():
		if parent.is_on_floor():
			return idle_state
		else:
			return fall_state
	
	parent.move_and_slide()
	
	return null

func exit() -> void:
	Global.kunai_cooldown_ongoing = true
	parent.kunai_cooldown_timer.start()
	parent.set_collision_mask_value(2, true)
	Global.can_kunai = false
	Global.kunai_is_anchored = false
	
	
	var tween := parent.create_tween()
	var from := parent.rotation
	var to := original_rotation

	tween.tween_method(
		func(t):
			parent.rotation = lerp_angle(from, to, t),
		0.0,
		1.0,
		0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_damage_received() -> State:
	return hurt_state
