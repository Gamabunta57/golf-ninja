extends State

@export var patrol_state: State
@export var attack_growth: Timer
@export var attack_cool_down: Timer
@export var hitbox: CollisionShape2D

var player: CharacterBody2D
var delta_x: float
var should_patrol: bool

@export var initial_hitbox_scale: Vector2 = Vector2(1.0, 1.0) # Starting scale
@export var hitbox_scale_growth: Vector2 = Vector2(1.12, 1.12)   # Scale at the end of growth

func enter() -> void:
	super()
	hitbox.disabled = true
	should_patrol = false
	player = get_tree().get_first_node_in_group("Player")
	
	attack_growth.connect("timeout", Callable(self, "_on_attack_growth_timeout"))
	attack_cool_down.connect("timeout", Callable(self, "_on_attack_cool_down_timeout"))
	
	hitbox.scale = initial_hitbox_scale
	attack_growth.start()
	flip()

func on_body_exited(body: Node2D) -> State:
	flip()
	should_patrol = true
	return null

func _on_attack_growth_timeout():
	attack_growth.stop()
	attack_cool_down.start()
	hitbox.disabled = true

func _on_attack_cool_down_timeout():
	if should_patrol:
		attack_growth.stop()
	else:
		attack_growth.start()
		
	attack_cool_down.stop()

func process_physics(delta: float) -> State:
	
	if attack_growth.time_left > 0:
		hitbox.scale *=  hitbox_scale_growth
		hitbox.disabled = false
	else:
		hitbox.scale = initial_hitbox_scale
		hitbox.disabled = true
	
	if should_patrol and attack_cool_down.time_left == 0 and attack_growth.time_left == 0:
		hitbox.scale = initial_hitbox_scale
		hitbox.disabled = true
		return patrol_state
	
	return null

func flip() -> void:
	delta_x = player.global_position.x - parent.global_position.x
	if delta_x  * parent.direction < 0:
		parent.flip_direction()
