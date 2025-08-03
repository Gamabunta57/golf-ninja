class_name Player
extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var player_health: int = 5

var enemy_position: Vector2

func _ready() -> void:
	get_tree().call_group('UI', 'set_health')
	state_machine.init(self, inputs, movements)
	SignalBus.damage.connect(_on_damage_received)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _on_damage_received(origin_position) -> void:
	enemy_position = origin_position
	state_machine._on_damage_received()
