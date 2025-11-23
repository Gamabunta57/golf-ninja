class_name Player
extends CharacterBody2D

#@onready var animations = $animations
@onready var state_machine = $state_machine
@onready var inputs: Node = $Inputs
@onready var movements: Node = $Movements

@export var player_health: int = 5
@export var push_force = 100
@export var grappling_collider : RayCast2D
@export var grappling_color : Color = Color(1, 1, 1)
@export var max_grappling_time : float = 0.1

var should_coyote: bool = false
var can_jump: bool = true
var direction: int = 1
var last_direction: int = 1
var can_grapple: bool = false
var anchor: Vector2 = Vector2.ZERO

var enemy_position: Vector2
var is_hidden: bool = false
var is_ball_nearby: bool = false
var ball_body: Node2D
var cancel_shooting: bool = false

var grappling_time_elapsed: float = 0.0
var can_draw_grappling: bool = false
var is_jumping: bool = false

func _ready() -> void:
	get_tree().call_group('UI', 'set_health')
	state_machine.init(self, inputs, movements)
	SignalBus.damage.connect(_on_damage_received)
	set_collision_mask_value(13, false)
	Global.player_body = self

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	
	if not inputs.get_shooting_input():
		cancel_shooting = false
	
	# Flip player
	if last_direction != direction and direction != 0:
		scale.x =  -1 * scale.x
		last_direction = direction
	
	# Grippling
	if inputs.get_jump_input() and grappling_collider.is_colliding():
		var anchor_normal : Vector2 = grappling_collider.get_collision_normal()
		
		if anchor_normal.x < 1 and anchor_normal.y > 0:
			can_draw_grappling = true
			grappling_time_elapsed += delta
			if grappling_time_elapsed < max_grappling_time:
				anchor = grappling_collider.get_collision_point()
			else:
				can_grapple = true
		queue_redraw()
			
	else:
		grappling_time_elapsed = 0.0
		can_draw_grappling = false
		can_grapple = false
		anchor = Vector2.ZERO
		queue_redraw()
	
	if inputs.get_jump_input():
		can_jump = false
	
	if inputs.get_jump_release():
		can_jump = true
	
	if can_jump and can_draw_grappling:
		can_jump = false
	
	if not can_jump and not can_draw_grappling:
		can_jump = true
	
	state_machine.process_physics(delta)

func _on_damage_received(origin_position) -> void:
	enemy_position = origin_position
	state_machine._on_damage_received()

#func rigid_body_collision() -> void:
	#for i in get_slide_collision_count():
		#var c = get_slide_collision(i)
		#if c.get_collider() is RigidBody2D:
			#c.get_collider().apply_central_impulse(-c.get_normal() * push_force)



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

func _draw() -> void:
	if inputs.get_jump_input() and grappling_collider.is_colliding() and can_draw_grappling and not is_jumping:
		draw_circle(to_local(anchor),3,grappling_color,true)
		#draw_circle(Vector2.ZERO,100,Color(1,1,0),true)
		draw_line(Vector2.ZERO+Vector2(0,-25), to_local(anchor), grappling_color, 1)
