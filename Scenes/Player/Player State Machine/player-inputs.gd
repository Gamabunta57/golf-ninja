@icon("res://Icons/gamepad.png")
extends Node

func get_x_input() -> float:
	return Input.get_axis("left", "right")

func get_y_input() -> float:
	return Input.get_axis("down", "up")

func get_jump_input() -> bool:
	return Input.is_action_pressed('jump')

func get_jump_input_just_pressed() -> bool:
	return Input.is_action_just_pressed('jump')

func get_jump_just_release() -> bool:
	return Input.is_action_just_released('jump')

func get_shooting_input() -> bool:
	return Input.is_action_pressed("shooting")
	
func get_shooting_just_pressed() -> bool:
	return Input.is_action_just_pressed("shooting")
