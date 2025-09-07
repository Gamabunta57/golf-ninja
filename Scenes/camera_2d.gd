extends Camera2D

@export var player: CharacterBody2D
@export var smooth: bool = true
@export_range(1, 10) var intensity: int = 2
@export var camera_offset: Vector2 = Vector2(0,-100)
#@export var zoomValue : int = 2
@export var camera_shake_timer: Timer

@export var camera_shake_intensity: int = 1
@export var shake_frequency_timer: Timer

var current_shake_offset: int = 0
var target: Vector2 = Vector2.ZERO

var camera_shaking: bool = false
var camera_ball_lag: bool = false

var ball_body: RigidBody2D
var ball_body_pos: Vector2 = Vector2.ZERO
var ball_centric: bool = false

func _ready() -> void:
	SignalBus.damage.connect(_start_camera_shake)
	SignalBus.last_trajectory_point.connect(_end_of_trajectory)
	target = player.global_position + camera_offset
	global_position = target 

func _physics_process(delta: float) -> void:
	var weight: float
	
	if ball_body:
		ball_body_pos = ball_body.global_position
	#set_zoom(Vector2(zoomValue, zoomValue))
	
	if Global.player_centric:
		target = player.global_position + camera_offset
		ball_centric = false
	else: 
		var target_ball_diff: Vector2 = global_position - ball_body_pos

		if not Global.player_shooting and not ball_centric:
			var threshold : float = ball_body.linear_velocity.length() / 10
			if target_ball_diff.x < threshold and target_ball_diff.x > -threshold and target_ball_diff.y < threshold and target_ball_diff.y > -threshold :
				ball_centric = true
		
		
		if ball_centric:
			target = ball_body_pos
			
	#if Global.player_shooting:
		##trajectory_lag.start()
		#camera_ball_lag = true
	

	
	if target != null:
		var camera_position : Vector2
		
		if smooth:
			camera_position = global_position.lerp(target, delta * intensity)
		else:
			camera_position = target

		if camera_shaking:
			camera_position.x += current_shake_offset
			camera_position.y -= current_shake_offset
		
		global_position = camera_position

func _start_camera_shake(origin_position) -> void:
	camera_shake_timer.start()
	shake_frequency_timer.start()
	camera_shaking = true
	current_shake_offset = camera_shake_intensity

func _on_camera_shake_timer_timeout() -> void:
	camera_shaking = false
	current_shake_offset = 0
	shake_frequency_timer.stop()
	camera_shake_timer.stop()

func _on_shake_frequency_timeout() -> void:
	current_shake_offset = -current_shake_offset

func _end_of_trajectory(point, body) -> void:
	Global.player_centric = false
	target = point
	ball_body = body
