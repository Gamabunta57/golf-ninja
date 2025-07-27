extends State

@export var fall_state: State
@export var attack_state: State
@export var idle_state: State
@export var patrol_state: State
@export var speed: float = 300.0
@export var ground_check: RayCast2D
@export var player_check: RayCast2D

func enter() -> void:
	super()

func process_physics(delta: float) -> State:
		# Flip on wall or no ground	
	if parent.is_on_wall() or not ground_check.is_colliding():
		parent.velocity.x = 0
	
	# Move forward
	parent.velocity.x = speed * parent.direction
	
	parent.move_and_slide()
	
	if !parent.is_on_floor():
		return fall_state
	
	if not player_check.is_colliding():
		return patrol_state
		
	
	return null

func on_body_entered(body: Node2D) -> State:
	if body.is_in_group("Player"):
		return attack_state
	return null
