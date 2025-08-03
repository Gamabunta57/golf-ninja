extends State

@export var fall_state: State
@export var chase_state: State
@export var attack_state: State
@export var idle_state: State
@export var speed: float = 100.0
@export var ground_check: RayCast2D
@export var player_check: RayCast2D

var should_idle: bool = false

func enter() -> void:
	super()
	parent.velocity.x = 0

func exit() -> void:
	should_idle = false

func process_physics(delta: float) -> State:
		# Flip on wall or no ground	
	if parent.is_on_wall() or not ground_check.is_colliding():
		parent.flip_direction()
		should_idle = true
	
	# Move forward
	parent.velocity.x = speed * parent.direction
	
	parent.move_and_slide()
	
	if !parent.is_on_floor():
		return fall_state
	
	if should_idle:
		return idle_state
		
	if player_check.is_colliding():
		return chase_state
	
	if parent.player_in_attack_zone:
		return attack_state
	
	return null
