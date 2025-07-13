class_name PlayerInput
extends Node

func physics_process(delta: float) -> void:
	pass

func shouldJump() -> bool:
	return false

func getHorizontalDirection() -> float:
	return 0.0

func tryGrabABall() -> bool:
	return false
