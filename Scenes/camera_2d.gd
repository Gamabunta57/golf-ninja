extends Camera2D

@export var player: CharacterBody2D
@export var smooth: bool = true
@export_range(1, 10) var intensity: int = 2
@export var camera_offset: Vector2 = Vector2(0, -100)
var target_position: Vector2 = Vector2.ZERO

@export var shake_intensity: int = 1

var end_of_trajectory: Vector2

var shake: bool = false
var current_shake_strength: float = 20.0

func _ready() -> void:
	global_position = player.global_position + camera_offset
	target_position = global_position
	
func _physics_process(delta: float) -> void:
	# 1. Check the Global Enum
	shake = false
	
	match Global.camera_mode:
		Global.CameraMode.PLAYER:
			target_position = player.global_position + camera_offset
		
		Global.CameraMode.PREVIEW:
			target_position = Global.current_preview_position
		
		Global.CameraMode.BALL:
			target_position = Global.current_ball_position
		
		Global.CameraMode.KUNAI:
			target_position = Global.kunai_position
		
		Global.CameraMode.HURT:
			target_position = player.global_position + camera_offset
			shake = true
		
	
	if smooth:
		global_position = global_position.lerp(target_position, delta * intensity)
	else:
		global_position = target_position
	
	if shake:
		var shake_offset = Vector2(
			randf_range(-current_shake_strength, current_shake_strength),
			randf_range(-current_shake_strength, current_shake_strength)
		)
		global_position += shake_offset
