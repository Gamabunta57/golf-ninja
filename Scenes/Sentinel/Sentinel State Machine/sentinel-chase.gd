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
	
	if parent.player_in_attack_zone:
		return attack_state
	
	if not player_check.is_colliding():
		return patrol_state
	
	if player_check.is_colliding():
		var collider = player_check.get_collider()
		if collider and not collider.is_in_group("Player"):
			return patrol_state
		else:
			return null
	
	return null
