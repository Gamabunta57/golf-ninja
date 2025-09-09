extends State

@export var attack_state: State
@export var chase_state: State
@export var returning_state: State
@export var return_timer: Timer

var should_return: bool = false

func enter() -> void:
	super()
	parent.velocity = Vector2.ZERO
	return_timer.start()

func process_physics(delta: float) -> State:
	# If we have a current or last known target, chase
	if parent.current_target or parent.has_last_known_position:
		return chase_state
	
	# Return to origin if timer elapsed
	if parent.distance_to_origin > 1 and should_return:
		return returning_state
	
	# Attack only if in zone and target is the player
	if parent.player_in_attack_zone and parent.current_target and parent.current_target.is_in_group("Player"):
		return attack_state
	
	return null

func _on_return_timer_timeout() -> void:
	should_return = true

func exit() -> void:
	return_timer.stop()
	should_return = false
