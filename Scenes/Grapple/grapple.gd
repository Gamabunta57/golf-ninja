extends CharacterBody2D

@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements
@export var player: CharacterBody2D

var state: String
var grapple_origin_offest: Vector2 = Vector2(0,-25)
var grapple_angle: Vector2 = Vector2(-1,0).rotated(2*PI/3)
var anchor_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	state_machine.init(self)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	Global.grapple_body = self
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)
