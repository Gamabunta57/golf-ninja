extends State

@export var fall_state: State
@export var attack_state: State
@export var patrol_state: State
@export var chase_state: State
@export var idle_timer: Timer
@export var cooldown: Timer
@export var player_check: RayCast2D
@export var detection_range: float = 500.0

var should_patrol : bool = false
var player: CharacterBody2D


func enter() -> void:
	super()
	parent.velocity.x = 0
	player = get_tree().get_first_node_in_group("Player")

func exit() -> void:
	idle_timer.stop()
	should_patrol = false
	
func _on_idle_timer_timeout() -> void:
	should_patrol = true

func process_physics(delta: float) -> State:
	if !parent.is_on_floor():
		return fall_state
	
	var distance = parent.global_position.distance_to(player.global_position)
	
	if distance < detection_range:
		if idle_timer.time_left == 0.0:
			idle_timer.start()
	else:
		if idle_timer.time_left > 0.0:
			idle_timer.stop()
	
	
	if player_check.is_colliding() and not parent.attack_cooldown:
		return chase_state
	
	if parent.attack_cooldown and not player_check.is_colliding() :
		var delta_x = parent.player_position.x - parent.global_position.x
		if delta_x * parent.direction > 0:
			parent.flip_direction()
	
	if should_patrol:
		return patrol_state
	
	if parent.player_in_attack_zone:
		return attack_state
		
	return null
