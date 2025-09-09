extends State

@export var attack_state: State
@export var idle_state: State
@export var speed: float = 100.0
@export var min_distance_to_target: float = 50
@export var navigation_agent: NavigationAgent2D

@export var path_recalculation_interval: float = 0.5
var time_since_last_path_recalc: float = 0.0

func enter() -> void:
	super()
	if navigation_agent and parent.current_target:
		navigation_agent.target_position = parent.current_target_position
	time_since_last_path_recalc = 0.0

func process_physics(delta: float) -> State:
	if parent.current_target == null and not parent.has_last_known_position:
		return idle_state

	var target_pos: Vector2 = parent.current_target_position
	if parent.current_target == null and parent.has_last_known_position:
		target_pos = parent.last_known_position

	# Pathfinding
	time_since_last_path_recalc += delta
	if time_since_last_path_recalc >= path_recalculation_interval:
		navigation_agent.target_position = target_pos
		time_since_last_path_recalc = 0.0

	var next_path_position = navigation_agent.get_next_path_position()
	var direction_to_next_point: Vector2 = Vector2.ZERO

	var distance_to_target: float = parent.global_position.distance_to(target_pos)
	if distance_to_target >= min_distance_to_target:
		direction_to_next_point = (next_path_position - parent.global_position).normalized()

	parent.velocity = direction_to_next_point * speed
	parent.move_and_slide()

	# Attack only if actively chasing the player
	if parent.player_in_attack_zone and parent.current_target and parent.current_target.is_in_group("Player"):
		return attack_state

	# If reached last known position, let Idle handle returnTimer
	if parent.current_target == null and distance_to_target <= min_distance_to_target:
		parent.has_last_known_position = false
		return idle_state

	return null
