class_name Player
extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var player_health: int = 5
@export var push_force = 100
@export var grappling_collider : RayCast2D
@export var wall_collider : RayCast2D
@export var flippables : Node2D

var state: String
var should_coyote: bool = false
var can_jump: bool = false
var can_throw_grapple: bool = false
var last_direction: int = 1
var grappling_origin: Vector2 = Vector2(0,-25)
var grappling_normalised_vector: Vector2 = Vector2(-1,0).rotated(2*PI/3)
var anchor: Vector2 = Vector2.ZERO
var grapple_position: Vector2 = Vector2.ZERO
var grapple_throwing_iteration: int = 0

var enemy_position: Vector2
var is_hidden: bool = false
var is_ball_nearby: bool = false
var ball_body: Node2D
var cancel_shooting: bool = false

var grappling_time_elapsed: float = 0.0
var can_draw_grappling: bool = false
var is_jumping: bool = false
var target_position: Vector2 = Vector2.ZERO

var jump_count: int = 0
@export var max_jump_count: int = 1

@export var grapple_body : CharacterBody2D
@export var grapple_cooldown_timer : Timer
var grapple_count: int = 0
@export var max_grapple_count: int = 20
var grapple_cooldown_ongoing : bool = false

@export var kunai_body : CharacterBody2D
@export var kunai_cooldown_timer : Timer
var kunai_count: int = 0
@export var max_kunai_count: int = 20
var kunai_cooldown_ongoing : bool = false

func _ready() -> void:
	get_tree().call_group('UI', 'set_health')
	state_machine.init(self, inputs, movements)
	SignalBus.damage.connect(_on_damage_received)
	set_collision_mask_value(13, false)
	Global.player_body = self

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	#print(state)
	Global.kunai_idle_position = global_position + Vector2(0,-50)
	
	if not inputs.get_shooting_input():
		cancel_shooting = false
	
	# Flip player
	if last_direction != Global.direction and Global.direction != 0:
		flippables.scale.x = Global.direction
		
		last_direction = Global.direction
	
	state_machine.process_physics(delta)

func _on_damage_received(origin_position) -> void:
	enemy_position = origin_position
	state_machine._on_damage_received()


func _on_ball_detection_body_entered(body: Node2D) -> void:
	if body.outside_bin:
		is_ball_nearby = true
		ball_body = body
		print(is_ball_nearby)
		SignalBus.ball_in_range.emit(body, true)

func _on_ball_detection_body_exited(body: Node2D) -> void:
	is_ball_nearby = false
	ball_body = null
	SignalBus.ball_in_range.emit(body, false)


func _on_hidden_room_body_entered(body: Node2D) -> void:
	is_hidden = true
	Global.player_hidden = true

func _on_hidden_room_body_exited(body: Node2D) -> void:
	is_hidden = false
	Global.player_hidden = false

func _on_grapple_cool_down_timeout() -> void:
	Global.grapple_cooldown_ongoing = false
	grapple_cooldown_timer.stop()


func _on_kunai_cool_down_timeout() -> void:
	Global.kunai_cooldown_ongoing = false
	kunai_cooldown_timer.stop()
