class_name StatePlayerControlled
extends State

@export var ballState: StateBallControlled
@export var player: PlayerWithStateMachine

func physics_process(delta: float) -> void:
	player.shouldJump = Input.is_action_just_pressed("jump")
	player.xDirectionUpdate = Input.get_axis("left", "right")
	if (player.canGrabBall && Input.is_action_just_pressed("controll_ball")):
		self.stateMachine.changeState(ballState)
