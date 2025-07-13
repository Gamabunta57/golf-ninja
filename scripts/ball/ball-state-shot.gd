class_name BallStateShot
extends State

@export var ball: Ball
@export var activeStateLine: Line2D
@export var stateShootable: BallStateShootable

func enter() -> void:
	activeStateLine.set_default_color(ball.colorNonShootable)
	ball.canBeShoot = false

func process_physics(_delta: float) -> void:
	var canBeShoot = ball.linear_velocity.length_squared() < 4
	if (canBeShoot): 
		change_state(stateShootable)
