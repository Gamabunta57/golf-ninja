class_name StateBallControlled
extends State

@export var playerState: StatePlayerControlled
@export var ball: BallWithStateMachine 

func onEnter() -> void:
	ball.isControlled = true
	
func physics_process(delta: float) -> void:
	ball.canBeShoot = true
	ball.isShot = Input.is_action_just_pressed("shoot")
	ball.angleUpdateDirection = Input.get_axis("left", "right")
	ball.forceUpdateDirection = Input.get_axis("down", "up")

	if (ball.isShot):
		self.stateMachine.changeState(playerState)

func onExit() -> void:
	ball.isControlled = false
