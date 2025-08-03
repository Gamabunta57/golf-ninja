extends CharacterBody2D

@onready var state_machine = $state_machine
#@onready var attack_area = $AttackArea2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@export var player_check: RayCast2D

var origin_position: Vector2
var direction : int = 1
var player_visible: bool = false
var distance_to_origin: float = 0.0
var last_player_position: Vector2

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
			last_player_position = collider.global_position - Vector2(0.0, 50.0)
		else:
			player_visible = false
	
	distance_to_origin = global_position.distance_to(origin_position)
	
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	state_machine.on_body_entered(body)

func _on_attack_area_2d_body_exited(body: Node2D) -> void:
	state_machine.on_body_exited(body)

func flip_direction():
	direction *= -1
	scale.x *= -1
