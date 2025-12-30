extends State

@export var anchor_state: State
@export var idle_state: State

@export var speed: float = 1000
#@export var deceleration: float = 1000
@export var gravity_multiplier: float = 1.5


func enter() -> void:
	super()
	parent.state = "kunai throw state"
	parent.velocity = parent.kunai_angle * speed * Vector2(Global.direction,1)
	parent.rotation = parent.velocity.angle() + (PI / 2)

func process_physics(delta: float) -> State:
	parent.velocity.y += gravity * gravity_multiplier * delta
	parent.rotation = parent.velocity.angle() + (PI / 2)
	
	if parent.move_and_slide():
		#parent.anchor_position = parent.global_position
		var collision = parent.get_last_slide_collision()
		if collision:
			Global.kunai_normal = collision.get_normal()
		parent.kunai_anchored = true
		return anchor_state
	#
	if not Global.can_kunai:
		return idle_state
	
	return null

func exit() -> void:
	pass
