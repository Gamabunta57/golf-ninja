extends State

@export var fall_state: State
@export var attack_state: State
@export var idle_state: State
@export var patrol_timer: Timer
@export var speed: float = 100.0
@export var ground_check: RayCast2D

var should_idle: bool = false

func enter() -> void:
	super()
	parent.velocity.x = 0
	print("patroling")
	patrol_timer.start()
	patrol_timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func exit() -> void:
	patrol_timer.stop()
	should_idle = false

func _on_timer_timeout() -> void:
	should_idle = true

func process_physics(delta: float) -> State:
		# Flip on wall or no ground	
	if parent.is_on_wall() or not ground_check.is_colliding():
		flip_direction()
	
	# Move forward
	parent.velocity.x = speed * parent.direction
	
	parent.move_and_slide()
	
	if !parent.is_on_floor():
		return fall_state
	if should_idle:
		return idle_state
		
	return null

func on_body_entered(body: Node2D) -> State:
	# Check for the player and set it as the target
	if body.is_in_group("Player"):
		#parent.target = body # Store the target
		print("Player detected, attacking!")
		return attack_state
	return null

func flip_direction():
	parent.direction *= -1
	parent.scale.x *= -1
