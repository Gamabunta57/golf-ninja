extends State

@export var attack_state: State
@export var chase_state: State
@export var returning_state: State
@export var return_timer: Timer

var should_return: bool = false

func enter() -> void:
	super()
	parent.state = "drone idle state"
	should_return = false
	parent.velocity = Vector2.ZERO
	return_timer.start()
	#print("idle")

func process_physics(delta: float) -> State:
	#print(str("should return: ", should_return))
	if parent.should_chase_player or parent.should_chase_ball:
		return chase_state
	
	if parent.player_in_attack_zone and parent.player_visible:
		return attack_state
	
	if should_return:
		return returning_state 
	
	return null

func _on_return_timer_timeout() -> void: 
	if parent.distance_to_origin > 10:
		should_return = true

func exit() -> void:
	#should_return = false
	return_timer.stop()
