extends State

@export var idle_state: State
@export var attack_cooldown_timer: Timer
@export var bullet: PackedScene

func enter() -> void:
	super()
	parent.velocity = Vector2.ZERO

func process_physics(delta: float) -> State:
	if not parent.player_in_attack_zone or not parent.player_visible or not parent.ready_to_fire:
		parent.should_chase_player = false
		return idle_state
	
	if parent.ready_to_fire and parent.player_visible:
		parent.ready_to_fire = false
		
		var new_bullet = bullet.instantiate()
		parent.bullets.add_child(new_bullet)
		new_bullet.global_position = parent.global_position 
		
		var bullet_direction = (Global.player_body.global_position - Vector2(0,25) - parent.global_position).normalized()
		new_bullet.set_bullet_direction(bullet_direction)
		new_bullet.set_origin_position(parent.global_position)
		
		attack_cooldown_timer.start()
	
	return null

func _exit_tree() -> void:
	attack_cooldown_timer.stop()
