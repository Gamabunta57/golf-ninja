extends State

@export var attack_state: State
@export var idle_state: State
@export var speed: float = 100.0
@export var min_distance_to_target: float = 50
@export var navigation_agent: NavigationAgent2D

var player_visible: bool = false
@export var path_recalculation_interval: float = 0.5
var time_since_last_path_recalc: float = 0.0

func enter() -> void:
	super()
	if navigation_agent:
		navigation_agent.target_position = parent.last_player_position
	
	time_since_last_path_recalc = 0.0
	#print("chasing")


func process_physics(delta: float) -> State:
			
	# Pathfinding Logic
	time_since_last_path_recalc += delta
	
	if time_since_last_path_recalc >= path_recalculation_interval:
			navigation_agent.target_position = parent.last_player_position
			time_since_last_path_recalc = 0.0
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction_to_next_point: Vector2 = Vector2(0.0, 0.0)
	
	# Stop before reaching the player
	var distance_to_target: float = parent.global_position.distance_to(parent.last_player_position)
	
	if distance_to_target >= min_distance_to_target:
		direction_to_next_point = (next_path_position - parent.global_position).normalized()
	
	parent.velocity = direction_to_next_point * speed
	
	parent.move_and_slide()
	
	if parent.player_in_attack_zone and parent.player_visible:
		return attack_state
		
	if parent.velocity.is_zero_approx() and not player_visible:
			return idle_state
		
	return null
