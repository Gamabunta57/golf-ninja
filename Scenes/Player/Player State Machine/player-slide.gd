extends State

@export var jump_state: State
@export var grappling_state: State
@export var idle_state: State
@export var fall_state: State
@export var hurt_state: State
@export var flip_timer: float = 0.1


@export var slide_velocity: float = 150

var last_y_velocity: float = 0
var time_ellapsed: float = 0.0

func enter() -> void:
	super()
	print("slide")
	parent.velocity = Vector2.ZERO
	time_ellapsed = 0.0

func process_physics(delta: float) -> State:
	 
	var floor_normal := parent.get_floor_normal()
	
	time_ellapsed += delta
	if time_ellapsed > flip_timer:
		parent.direction = sign(floor_normal.x)
	# Tangent along the slope
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

	parent.move_and_slide()

	
	if parent.can_grapple:
		return grappling_state
	
	if inputs.get_jump_input() and parent.is_on_floor() and parent.can_jump and not parent.can_draw_grappling:
		return jump_state
	
	if not parent.is_on_floor():
		return fall_state
	
	if not parent.is_on_slope:
		return idle_state
	
	return null

func exit() -> void:
	time_ellapsed = 0.0

func _on_damage_received() -> State:
	return hurt_state
