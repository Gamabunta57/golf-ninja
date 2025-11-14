extends State

@export var attack_state: State
@export var idle_state: State
@export var chase_state: State
@export var speed: float = 100.0
@export var navigation_agent: NavigationAgent2D

func enter() -> void:
	super()
	navigation_agent.target_position = parent.origin_position
	#print("returning")
	
func process_physics(delta: float) -> State:
	if parent.should_chase_player or parent.should_chase_ball:
			return chase_state
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction_to_next_point = (next_path_position - parent.global_position).normalized()
	
	parent.velocity = direction_to_next_point * speed
	
	parent.move_and_slide()
	
	if parent.distance_to_origin <= 10 :
		return idle_state
		
	if parent.player_in_attack_zone and parent.player_visible:
		return attack_state
	
	return null
