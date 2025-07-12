class_name StateBallControlled
extends State

@export var playerState: StatePlayerControlled
@export var player: PlayerWithStateMachine
var ball: BallWithStateMachine

func onEnter() -> void:
	if (player.currentBallTarget == null):
		"""
		player.currentBallTarget can be null if the player slides and exit the area
		or if the ball itself moves outside the player
		"""
		stateMachine.changeState(playerState)
	else:
		ball = player.currentBallTarget
		ball.isControlled = true
	
func physics_process(_delta: float) -> void:
	ball.canBeShoot = true
	ball.isShot = Input.is_action_just_pressed("shoot")
	ball.angleUpdateDirection = Input.get_axis("left", "right")
	ball.forceUpdateDirection = Input.get_axis("down", "up")

	if (ball.isShot):
		self.stateMachine.changeState(playerState)

func onExit() -> void:
	if (ball != null):
		ball.isControlled = false
