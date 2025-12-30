extends CharacterBody2D

@onready var state_machine = $state_machine
#@onready var attack_area = $AttackArea2D
@export var path_recalculation_interval: float = 0.5

var state: String
var should_chase_player: bool = false
var should_chase_ball: bool = false

var player_visible: bool = false

@export var target_check: RayCast2D
@export var attack_cooldown_timer: Timer
@onready var bullets: Node2D = $"../Bullets"

var origin_position: Vector2
var direction : int = 1

var distance_to_origin: float = 0.0

var player_in_attack_zone: bool = false
var ready_to_fire: bool = true

func _ready() -> void:
	state_machine.init(self)
	origin_position = global_position

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
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
	
