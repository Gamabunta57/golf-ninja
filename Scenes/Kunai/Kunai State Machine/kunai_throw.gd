extends State

@export var anchor_state: State
@export var idle_state: State

@export var speed: float = 1200
@export var deceleration: float = 100
@export var gravity_multiplier: float = 2

@export var ray_collision: RayCast2D
@export var clearance: RayCast2D

var time_ellapsed: float = 0.0
@export var max_time: float = 0.5

var intitial_angle: Vector2

func enter() -> void:
	super()
	parent.state = "kunai throw state"
	parent.global_position += parent.kunai_origin_offset
	Global.kunai_position = parent.global_position
	Global.camera_mode = Global.CameraMode.KUNAI
	#parent.velocity = parent.kunai_angle * speed * Vector2(Global.direction, 1)
	parent.sprite.show()
	if inputs.get_x_input() == 0 and inputs.get_y_input() == 0:
		intitial_angle = parent.kunai_angle * Vector2(Global.direction, 1)
	else:
		intitial_angle = Vector2(inputs.get_x_input(), -inputs.get_y_input()).normalized()
		
	parent.velocity = intitial_angle * speed
	

func process_physics(delta: float) -> State:
	if not Global.can_kunai:
		return idle_state
	
	time_ellapsed += delta
	
	if not Global.kunai_stop_throw and not Global.release_kunai:
		var move_dir = intitial_angle * speed
		parent.velocity.x = move_dir.x
		parent.velocity.y += gravity * delta * 0.5
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, deceleration * delta)
		parent.velocity.y += gravity * gravity_multiplier * delta
	
	parent.rotation = parent.velocity.angle() + (PI / 2)
	
	#ray_collision.force_raycast_update()
	if ray_collision.is_colliding():
		Global.kunai_normal = ray_collision.get_collision_normal()
		parent.kunai_anchored = true
		Global.kunai_position = ray_collision.get_collision_point()
		Global.kunai_anchor_object = ray_collision.get_collider()
		return anchor_state
	
	clearance.force_raycast_update()
	if clearance.is_colliding() and not parent.kunai_anchored:
		var collision_point = clearance.get_collision_point()
		Global.kunai_position = collision_point - Vector2(0, -50)
	else:
		Global.kunai_position = parent.global_position
	
	parent.move_and_slide()
	
	return null

func exit() -> void:
	parent.sprite.hide()
	time_ellapsed = 0.0
