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

var last_y_velocity: float = 0
var time_ellapsed: float = 0.0
var facing_slope: bool = false

func enter() -> void:
	super()
	print("slide")
	parent.velocity = Vector2.ZERO
	time_ellapsed = 0.0

func process_input(event: InputEvent) -> State:
	if sign(Global.direction) == sign(parent.get_floor_normal().x):
		facing_slope = false
	else:
		facing_slope = true
	
	if inputs.get_jump_input():
		if not facing_slope:
			return grappling_state
		else:
			return jump_state
	
	return null

func process_physics(delta: float) -> State:
		
	if wall_collider.is_colliding() and parent.get_floor_angle() == 0:
		return idle_state
	
	movements.flip_direction(inputs, parent)
	
	var floor_normal := parent.get_floor_normal()

	var slope_tangent := Vector2(floor_normal.y, -floor_normal.x).normalized()

	# Force tangent to point downhill
	if slope_tangent.y < 0:
		slope_tangent = -slope_tangent

	# Set the velocity along slope
	if sign(inputs.get_x_input()) == sign(floor_normal.x):
		parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)
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
