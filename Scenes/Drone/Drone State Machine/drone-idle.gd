extends State

@export var attack_state: State
@export var patrol_state: State
@export var chase_state: State
@export var returning_state: State
@export var return_timer: Timer
@export var player_check: RayCast2D

var should_return : bool = false
var player: CharacterBody2D


func enter() -> void:
	super()
	parent.velocity.x = 0
	return_timer.start()


func process_physics(delta: float) -> State:
	if player_check.is_colliding():
		var collider = player_check.get_collider()
		if collider.is_in_group("Player"):
			return chase_state 
	
	if parent.global_position.distance_to(parent.origin_position) > 1 and should_return:
		return returning_state
	
	return null
	

func on_body_entered(body: Node2D) -> State:
	return attack_state


func _on_return_timer_timeout() -> void:
	should_return = true

func exit() -> void:
	return_timer.stop()
	should_return = false
