extends State

@export var fall_state: State
@export var chase_state: State
@export var attack_state: State
@export var idle_state: State
@export var speed: float = 200.0
@export var ground_check: RayCast2D
@export var wall_check_down: RayCast2D
@export var wall_check_up: RayCast2D
@export var player_check: RayCast2D

var should_idle: bool = false

func enter() -> void:
	super()
	parent.velocity.x = 0

func exit() -> void:
	should_idle = false

func process_physics(delta: float) -> State:
		# Flip on wall or no ground	
	if wall_check_down.is_colliding() or wall_check_up.is_colliding() or not ground_check.is_colliding():
		parent.flip_direction()
		should_idle = true
	
	# Move forward
	parent.velocity.x = speed * parent.direction
	
	parent.move_and_slide()
	
	if !parent.is_on_floor():
		return fall_state
	
	if should_idle:
		return idle_state
	
	
	if parent.player_in_attack_zone:
		return attack_state
	
	if player_check.is_colliding():
		var collider = player_check.get_collider()
		if collider and collider.is_in_group("Player"):
			print("chase")
			return chase_state
		else:
			return null
			
	return null
