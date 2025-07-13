class_name BallInput
extends Node

var ball: Ball
var angle: float = 0.0
var strength: float = 10.0

func physics_process(delta: float) -> void:
	pass

func shouldShoot() -> bool:
	return false

func getDirectionWithStrength() -> Vector2:
	return Vector2.ZERO
