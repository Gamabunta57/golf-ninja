extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@onready var attack_area = $AttackArea2D
#var target: CharacterBody2D = null 
var direction: int = 1

func _ready() -> void:
	state_machine.init(self)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	state_machine.on_body_entered(body)

func _on_attack_area_2d_body_exited(body: Node2D) -> void:
	state_machine.on_body_exited(body)
