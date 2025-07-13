class_name PlayerKeyboardInput
extends PlayerInput

var _shouldJump: bool = false
var _direction: float = 0.0
var _tryGrabBall: bool = false

func physics_process(delta: float) -> void:
	_shouldJump = Input.is_action_just_pressed("jump")
	_tryGrabBall = Input.is_action_just_pressed("controll_ball")
	_direction = Input.get_axis("left", "right")
	pass

func shouldJump() -> bool:
	return _shouldJump

func getHorizontalDirection() -> float:
	return _direction

func tryGrabABall() -> bool:
	return _tryGrabBall
