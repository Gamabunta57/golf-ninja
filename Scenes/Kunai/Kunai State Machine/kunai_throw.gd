extends State

@export var anchor_state: State
@export var idle_state: State

@export var speed: float = 1000
#@export var deceleration: float = 1000
@export var gravity_multiplier: float = 1.5

@export var ray_collision: RayCast2D
@export var clearance: RayCast2D

func enter() -> void:
	super()
	parent.state = "kunai throw state"
	parent.global_position += parent.kunai_origin_offset
	Global.kunai_position = parent.global_position
	Global.camera_mode = Global.CameraMode.KUNAI
	parent.velocity = parent.kunai_angle * speed * Vector2(Global.direction,1)
	parent.rotation = parent.velocity.angle() + (PI / 2)
	parent.sprite.show()

func process_physics(delta: float) -> State:
	if not Global.can_kunai:
		return idle_state
		
	parent.velocity.y += gravity * gravity_multiplier * delta
	parent.rotation = parent.velocity.angle() + (PI / 2)
	
	#ray_collision.force_raycast_update()
	if ray_collision.is_colliding():
		#parent.anchor_position = parent.global_position
		#var collision = ray_collision.get_collision_point()
		Global.kunai_normal = ray_collision.get_collision_normal()
		parent.kunai_anchored = true
		Global.kunai_position = ray_collision.get_collision_point()
		return anchor_state
	
	clearance.force_raycast_update()
	if clearance.is_colliding() and not parent.kunai_anchored:
		print("clearance")
		var collision_point = clearance.get_collision_point()
		Global.kunai_position = collision_point - Vector2(0, -50)
	else:
		Global.kunai_position = parent.global_position
	
	parent.move_and_slide()
	
	return null

func exit() -> void:
	parent.sprite.hide()
