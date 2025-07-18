extends Camera2D

@export var target : CharacterBody2D
@export var smooth: bool = true
@export_range(1, 10) var intensity: int = 5
@export var zoomValue : int = 2

func _physics_process(delta: float) -> void:
	var weight: float
	set_zoom(Vector2(zoomValue, zoomValue))
	
	if target != null:
		var camera_position : Vector2
		
		if smooth:
			camera_position = position.lerp(target.global_position, delta * intensity)
		else:
			camera_position = target.global_position#.round()
		#print(camera_position)
		
		global_position = camera_position
