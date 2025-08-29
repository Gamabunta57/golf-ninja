extends Node2D

@onready var ball_circle: RigidBody2D = $".."

func _process(delta: float) -> void:
	global_rotation = 0.0
	global_position = ball_circle.global_position + Vector2(0,6)
