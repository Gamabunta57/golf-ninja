class_name Player
extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var player_health: int = 5
@export var push_force = 100

var direction: int = 1
var base_scale: Vector2 = Vector2.ONE

var enemy_position: Vector2
var is_back: bool = false
var is_ball_nearby: bool = false
var ball_body: Node2D

func _ready() -> void:
	get_tree().call_group('UI', 'set_health')
	state_machine.init(self, inputs, movements)
	SignalBus.damage.connect(_on_damage_received)
	set_collision_mask_value(13, false)
	base_scale = scale

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)
	rigid_body_collision()

func _on_damage_received(origin_position) -> void:
	enemy_position = origin_position
	state_machine._on_damage_received()

func rigid_body_collision() -> void:
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func _on_door_collision_body_entered(body: Node2D) -> void:
	if is_back and inputs.get_y_input() < 0.5:
		is_back = false
		set_collision_mask_value(13, false)
		z_index = 1
		Global.player_hidden = false
		
	if not is_back and inputs.get_y_input() >= 0.5:
		is_back = true
		set_collision_mask_value(13, true)
		z_index = 0
		Global.player_hidden = true


func _on_ball_detection_body_entered(body: Node2D) -> void:
	if body.outside_bin:
		is_ball_nearby = true
		ball_body = body
		SignalBus.ball_in_range.emit(body, true)

func _on_ball_detection_body_exited(body: Node2D) -> void:
	is_ball_nearby = false
	ball_body = null
	SignalBus.ball_in_range.emit(body, false)
	
