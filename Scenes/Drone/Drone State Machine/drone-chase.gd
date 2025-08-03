extends State

@export var attack_state: State
@export var idle_state: State
@export var speed: float = 100.0
@export var chase_threshold: float = 20
@export var player_check: RayCast2D
@export var navigation_agent: NavigationAgent2D

var last_player_position: Vector2
var player_visible: bool = false
@export var path_recalculation_interval: float = 0.5
var time_since_last_path_recalc: float = 0.0

func enter() -> void:
	super()
	if navigation_agent:
		navigation_agent.target_position = last_player_position
	
	time_since_last_path_recalc = 0.0


func process_physics(delta: float) -> State:
	if player_check.is_colliding():
		var collider = player_check.get_collider()
		if collider.is_in_group("Player"):
			last_player_position = collider.global_position - Vector2(0.0, 50.0)
			player_visible = true
		else:
			player_visible = false
			
	# Pathfinding Logic
	if navigation_agent:
		time_since_last_path_recalc += delta
	if time_since_last_path_recalc >= path_recalculation_interval:
			navigation_agent.target_position = last_player_position
			time_since_last_path_recalc = 0.0
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction_to_next_point: Vector2 = Vector2(0.0, 0.0)
	
	# Stop before reaching the player
	if parent.global_position.distance_to(last_player_position) >= 50:
		direction_to_next_point = (next_path_position - parent.global_position).normalized()
	
	parent.velocity = direction_to_next_point * speed
	
	parent.move_and_slide()
	
	if parent.velocity.is_zero_approx() and not player_visible:
			return idle_state
		
	return null
