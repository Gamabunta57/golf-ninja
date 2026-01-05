extends CharacterBody2D

@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var player: CharacterBody2D
@export var sprite: Sprite2D

var state: String
var kunai_origin_offset: Vector2 = Vector2(0,-50)
var kunai_angle: Vector2 = Vector2(-1,0).rotated(2*PI/3)
var kunai_anchored: bool = false
var anchor_position: Vector2 = Vector2.ZERO
var kunai_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	state_machine.init(self, inputs, movements)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	#print(state)
	state_machine.process_physics(delta)
	queue_redraw()
	

func _process(delta: float) -> void:
	state_machine.process_frame(delta)
