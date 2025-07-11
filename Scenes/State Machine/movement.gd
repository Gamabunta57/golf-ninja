extends Node

func get_x_movement() -> float:
	return Input.get_axis("left", "right")

func get_y_movement() -> float:
	return Input.get_axis("down", "up")

func get_jump() -> bool:
	return Input.is_action_just_pressed('jump')
