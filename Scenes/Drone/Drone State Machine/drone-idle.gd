extends State

@export var attack_state: State
@export var chase_state: State
@export var returning_state: State
@export var return_timer: Timer

var should_return : bool = false
var player: CharacterBody2D


func enter() -> void:
	super()
	parent.velocity = Vector2(0.0, 0.0)
	return_timer.start()
	#print('idle')


func process_physics(delta: float) -> State:
	if parent.player_visible:
		return chase_state
	
	if parent.distance_to_origin > 1 and should_return:
		return returning_state
	
	if parent.player_in_attack_zone and parent.player_visible:
		return attack_state
	
	return null

func _on_return_timer_timeout() -> void:
	should_return = true

func exit() -> void:
	return_timer.stop()
	should_return = false
