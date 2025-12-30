extends CharacterBody2D

@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var clearance: RayCast2D

var state: String
var kunai_origin_offset: Vector2 = Vector2(0,-50)
var kunai_angle: Vector2 = Vector2(-1,0).rotated(2*PI/3)
var kunai_anchored: bool = false
var anchor_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	state_machine.init(self)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	#print(state)
	state_machine.process_physics(delta)
	
	if clearance.is_colliding() and not kunai_anchored:
		var collision_point = clearance.get_collision_point()
		var distance = collision_point.y - global_position.y
		Global.kunai_position = global_position - Vector2(0, distance)
		print("clearence")
	else:
		Global.kunai_position = global_position

func _process(delta: float) -> void:
	state_machine.process_frame(delta)
