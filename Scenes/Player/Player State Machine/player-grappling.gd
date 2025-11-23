extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State

#@export var grappling_velocity_curve: Curve
@export var grappling_max_speed := 1000.0


var time_elapsed: float = 0.0 
var curve_ratio: float
var origin_position: Vector2
var target_position: Vector2
var original_distance: float

func enter() -> void:
	super()
	Global.player_centric = true
	parent.grappling_time_elapsed = 0.0
	parent.velocity = Vector2.ZERO
	target_position = parent.anchor + Vector2(0,25)
	original_distance = (target_position - parent.global_position).length()
	
func process_physics(delta: float) -> State:
	if inputs.get_jump_release():
		parent.can_grapple = false
		return fall_state
	
	var remaining_distance : float = (target_position - parent.global_position).length()
	
	if remaining_distance < 25:
		parent.velocity = Vector2.ZERO
		time_elapsed = 0
	else:
		time_elapsed += delta
		var dir: Vector2 = (target_position - parent.global_position).normalized()
		#print("OG: ", int(original_distance)," remaining: ", int(remaining_distance))
		#print("OG: ", int(original_distance))
		var grappling_speed : float = min(original_distance * 10,  grappling_max_speed)
		var speed : float = (remaining_distance / original_distance) * grappling_speed #* grappling_velocity_curve.sample(clamp(0, time_elapsed, 1))
		parent.velocity = dir * speed
	
	parent.move_and_slide()
	
	if parent.is_on_floor():
		return idle_state
		
	return null

func _on_damage_received() -> State:
	return hurt_state
