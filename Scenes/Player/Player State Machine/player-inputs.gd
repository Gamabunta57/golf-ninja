@icon("res://Icons/gamepad.png")
extends Node

func get_x_input() -> float:
	return Input.get_axis("left", "right")

func get_y_input() -> float:
	return Input.get_axis("down", "up")

func get_jump_input() -> bool:
	return Input.is_action_just_pressed('jump')
