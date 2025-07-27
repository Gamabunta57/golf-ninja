class_name Player
extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var player_health: int = 5
@export var game_over: PackedScene

var last_attacker: Node2D

func _ready() -> void:
	health()
	state_machine.init(self, inputs, movements)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	state_machine.on_area_entered(area)

func health():
	get_tree().call_group('UI', 'set_health', player_health)
	if player_health <= 0:
		get_tree().change_scene_to_packed(game_over)
