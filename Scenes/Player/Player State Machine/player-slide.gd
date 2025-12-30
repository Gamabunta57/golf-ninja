extends State

@export var jump_state: State
@export var move_state: State
@export var grappling_state: State
@export var idle_state: State
@export var fall_state: State
@export var hurt_state: State
@export var flip_timer: float = 0.1
@export var wall_collider : RayCast2D

@export var slide_velocity: float = 150

@export var move_speed: float = 600
@export var max_speed: float = 400
@export var deceleration: float = 12000

var last_y_velocity: float = 0
var time_ellapsed: float = 0.0
var facing_slope: bool = false

func enter() -> void:
	super()
	parent.state = "player slide state"
	parent.velocity = Vector2.ZERO
	time_ellapsed = 0.0
	parent.jump_count = 0
	#parent.grapple_count = 0
	#Global.can_grapple = false
	parent.kunai_count = 0
	Global.can_kunai = false

func process_physics(delta: float) -> State:
		
	if wall_collider.is_colliding() and parent.get_floor_angle() == 0:
		return idle_state
	
	#if parent.can_jump:
		#return jump_state
		#
	#if Global.can_grapple and not Global.grapple_cooldown_ongoing:
		#return grappling_state
	
	if parent.is_on_floor() and inputs.get_jump_input_just_pressed():
		if parent.jump_count < parent.max_jump_count:
			return jump_state
		
	movements.flip_direction(inputs)
	
	var floor_normal := parent.get_floor_normal()

	var slope_tangent := Vector2(floor_normal.y, -floor_normal.x).normalized()

	# Force tangent to point downhill
	if slope_tangent.y < 0:
		slope_tangent = -slope_tangent

	# Set the velocity along slope
	if sign(inputs.get_x_input()) == sign(floor_normal.x):
		parent.velocity.x = movements.horizontal_movement(parent.velocity.x, deceleration, move_speed, max_speed, delta, inputs)
		parent.velocity.y += gravity * delta
		
	else:
		parent.velocity = slope_tangent * slide_velocity
	
	#if parent.velocity.y < 0:
		#parent.velocity.y = 0
	
	parent.move_and_slide()

	
	if not parent.is_on_floor():
		return fall_state
	
	if parent.is_on_floor() and parent.get_floor_angle() < 1:
		if inputs.get_x_input() == 0:
			return idle_state
		else:
			return move_state
	
	return null

func exit() -> void:
	time_ellapsed = 0.0

func _on_damage_received() -> State:
	return hurt_state
