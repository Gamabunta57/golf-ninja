class_name BallStateShootable
extends State

@export var ball: Ball
@export var activeStateLine: Line2D
@export var stateShot: BallStateShot

var ballInput: BallInput

func enter() -> void:
	activeStateLine.set_default_color(ball.colorShootable)
	ball.canBeShoot = true
	ballInput = ball.ballInput

func process_physics(_delta: float) -> void:
	if (ball.isShot):
		ball.isShot = false
		change_state(stateShot)
