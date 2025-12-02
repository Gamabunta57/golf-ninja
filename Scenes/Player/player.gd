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
@export var rope_collider : RayCast2D
@export var grapple_body : CharacterBody2D


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
	if last_direction != Global.direction and Global.direction != 0:
		scale.x =  -1 * scale.x
		rope_collider.scale.x = scale.x
		
		last_direction = Global.direction
		
	# Grappling or jump
	
	# 1. Reset logic (Button release or Grounded)
	if inputs.get_jump_release():
		Global.can_grapple = false
		can_jump = false
		is_jumping = false
	
	# 2. Main Logic
	if inputs.get_jump_input():
		var is_grounded = is_on_floor()
		
		# Check for Grapple Target
		var has_target = grappling_collider.is_colliding()
		var normal = grappling_collider.get_collision_normal()
		# Check if target is a ceiling/overhang (y > 0) and not a vertical wall
		var is_valid_target = has_target and (normal.y > 0 and normal.x < 1)
		
		# Check for Obstacles (Walls or Steep Slopes)
		var wall_blocked = is_grounded and wall_collider.is_colliding()
		var steep_slope = is_grounded and get_floor_angle() > 1
		var facing_slope = steep_slope and sign(Global.direction) == sign(get_floor_normal().x)
		
		# --- C. DECISION TREE ---
		
		# 1. Forced Jump: Wall in front or facing steep slope -> Jump
		if wall_blocked or facing_slope:
			Global.can_grapple = false
			can_jump = true
			
		# 2. Grapple Opportunity: Valid target found -> Grapple
		elif is_valid_target and not is_jumping:
			Global.can_grapple = true
			can_jump = false
			
		# 3. Standard Jump: Grounded but no valid target -> Jump
		elif is_grounded:
			is_jumping = false
			Global.can_grapple = false
			can_jump = true
			
		# 4. Fallback: Air/Invalid -> Do nothing
		else:
			Global.can_grapple = false
			can_jump = false
	
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
