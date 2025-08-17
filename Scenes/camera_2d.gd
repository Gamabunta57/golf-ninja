extends Camera2D

@export var target : CharacterBody2D
@export var smooth: bool = true
@export_range(1, 10) var intensity: int = 5
#@export var zoomValue : int = 2
@export var camera_shake_timer: Timer

@export var camera_shake_intensity: int = 1
@export var shake_frequency_timer: Timer
var current_shake_offset: int = 0

var camera_shaking: bool = false

func _ready() -> void:
	SignalBus.damage.connect(start_camera_shake)

func _physics_process(delta: float) -> void:
	var weight: float
	#set_zoom(Vector2(zoomValue, zoomValue))
	
	if target != null:
		var camera_position : Vector2
		
		if smooth:
			camera_position = position.lerp(target.global_position, delta * intensity)
		else:
			camera_position = target.global_position.round()

		if camera_shaking:
			camera_position.x += current_shake_offset
			camera_position.y -= current_shake_offset
		
		global_position = camera_position

func start_camera_shake(origin_position) -> void:
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
