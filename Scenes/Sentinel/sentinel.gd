extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@export var cooldown_timer: Timer

#var target: CharacterBody2D = null 
var state: String
var direction: int = 1
var player_in_attack_zone: bool = false
var player_position: Vector2
var attack_cooldown: bool = false


func _ready() -> void:
	state_machine.init(self)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)

func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_attack_zone = true
		player_position = body.global_position
	else:
		player_in_attack_zone = false

func _on_attack_zone_body_exited(body: Node2D) -> void:
	player_in_attack_zone = false
	
func _on_attack_cooldown_timeout() -> void:
	attack_cooldown = false
	cooldown_timer.stop()

func flip_direction():
	direction *= -1
	scale.x *= -1

func flip() -> void:
	var delta_x = player_position.x - global_position.x
	if delta_x * direction < 0:
		flip_direction()
