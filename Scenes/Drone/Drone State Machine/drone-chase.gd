extends State

@export var attack_state: State
@export var idle_state: State
@export var speed: float = 100.0
@export var min_distance_to_target: float = 10
@export var navigation_agent: NavigationAgent2D

#@export var path_recalculation_interval: float = 0.5
#var time_since_last_path_recalc: float = 0.0

func enter() -> void:
	super()
	#time_since_last_path_recalc = 0.0
	print("chase")

func process_physics(delta: float) -> State:
	var next_path_position = navigation_agent.get_next_path_position()
	var direction_to_next_point = (next_path_position - parent.global_position).normalized()
	
	parent.velocity = direction_to_next_point * speed
	
	parent.move_and_slide()

	if parent.player_in_attack_zone and parent.player_visible:
		return attack_state

	var remaining_distance = parent.global_position.distance_to(navigation_agent.target_position)
	#print(str("remaining distance: ",int(remaining_distance)))
	if remaining_distance <= min_distance_to_target:
		parent.should_chase_player = false
		parent.should_chase_ball = false
		return idle_state

	return null
