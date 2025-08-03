extends State

@export var attack_state: State
@export var idle_state: State
@export var chase_state: State
@export var speed: float = 100.0
@export var player_check: RayCast2D
@export var navigation_agent: NavigationAgent2D

func enter() -> void:
	super()
	print("returning")
	navigation_agent.target_position = parent.origin_position
	
func process_physics(delta: float) -> State:
	if parent.player_visible:
			return chase_state
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction_to_next_point = (next_path_position - parent.global_position).normalized()
	
	parent.velocity = direction_to_next_point * speed
	
	
	if parent.distance_to_origin <= 1 :
		return idle_state
		
	parent.move_and_slide()
	
	return null
