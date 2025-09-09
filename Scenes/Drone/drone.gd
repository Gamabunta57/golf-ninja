extends CharacterBody2D

@onready var state_machine = $state_machine
#@onready var attack_area = $AttackArea2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@export var target_check: RayCast2D
@export var attack_cooldown_timer: Timer
@onready var bullets: Node2D = $"../Bullets"

var targeting_player_first: bool = true
var origin_position: Vector2
var direction : int = 1

var distance_to_origin: float = 0.0


# Targeting
var current_target: Node2D = null
var current_target_position: Vector2 = Vector2.ZERO
var last_known_position: Vector2 = Vector2.ZERO
var has_last_known_position: bool = false
var player_in_attack_zone: bool = false
var ready_to_fire: bool = true

func _ready() -> void:
	state_machine.init(self)
	origin_position = global_position

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	#print(str("Player visible: ", player_visible))
	#print(str("Ball visible: ", ball_visible))
	
	if target_check.is_colliding():
		var collider = target_check.get_collider()
		
		if collider.is_in_group("Player") and not Global.player_hidden:
			current_target = collider
			current_target_position = collider.global_position - Vector2(0.0, 25.0)
			last_known_position = current_target_position
			has_last_known_position = true
		
		elif collider.is_in_group("Ball") and current_target == null:
			current_target = collider
			current_target_position = collider.global_position - Vector2(0.0, 25.0)
			last_known_position = current_target_position
			has_last_known_position = true
		
	else:
		# Target lost → keep last known position, but clear Node
		if current_target:
			last_known_position = current_target_position
			has_last_known_position = true
		current_target = null

	# If still tracking something, update position
	if current_target:
		current_target_position = current_target.global_position - Vector2(0.0, 25.0)
	
	
	distance_to_origin = global_position.distance_to(origin_position)
	
	state_machine.process_physics(delta)

func flip_direction():
	direction *= -1
	scale.x *= -1

func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_attack_zone = true
	else:
		player_in_attack_zone = false

func _on_attack_zone_body_exited(body: Node2D) -> void:
	player_in_attack_zone = false

func _on_attack_cooldown_timeout() -> void:
	ready_to_fire = true
	attack_cooldown_timer.start()
	
