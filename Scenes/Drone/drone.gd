extends CharacterBody2D

@onready var state_machine = $state_machine
#@onready var attack_area = $AttackArea2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@export var player_check: RayCast2D
@export var attack_cooldown_timer: Timer
@onready var bullets: Node2D = $"../Bullets"

var origin_position: Vector2
var direction : int = 1
var player_visible: bool = false
var distance_to_origin: float = 0.0
var last_player_position: Vector2
var player_in_attack_zone: bool = false
var ready_to_fire: bool = true

func _ready() -> void:
	state_machine.init(self)
	origin_position = global_position

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	if player_check.is_colliding():
		var collider = player_check.get_collider()
		if collider.is_in_group("Player"):
			player_visible = true
			last_player_position = collider.global_position - Vector2(0.0, 25.0)
		else:
			player_visible = false
	
	distance_to_origin = global_position.distance_to(origin_position)
	
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)

func flip_direction():
	direction *= -1
	scale.x *= -1

func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_attack_zone = true
	else:
		player_in_attack_zone = false

func _on_attack_zone_body_exited(body: Node2D) -> void:
	player_in_attack_zone = false # Replace with function body.

func _on_attack_cooldown_timeout() -> void:
	ready_to_fire = true
	attack_cooldown_timer.start()
