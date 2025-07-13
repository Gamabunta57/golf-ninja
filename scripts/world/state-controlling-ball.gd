class_name StateControllingBall
extends State

@export var statePlayer: StateControllingPlayer
@export var player: Player
@export var ballInput: BallInput
var ball: Ball

func enter() -> void:
	if (player.currentBallTarget == null):
		"""
		player.currentBallTarget can be null if the player slides and exit the area
		or if the ball itself moves outside the player
		"""
		change_state(statePlayer)
	else:
		ball = player.currentBallTarget
		ball.isControlled = true
		ball.ballInput = ballInput
		ballInput.ball = ball

func process_physics(delta: float) -> void:
	ballInput.physics_process(delta)
	if (ball.canBeShoot && ballInput.shouldShoot()):
		ball.linear_velocity += ballInput.getDirectionWithStrength() * 15
		ball.isShot = true
		change_state(statePlayer)

func exit() -> void:
	if (ball == null): return

	ball.isControlled = false
	ballInput.ball = null
	ball = null
