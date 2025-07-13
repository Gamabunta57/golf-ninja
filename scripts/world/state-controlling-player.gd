class_name StateControllingPlayer
extends State

@export var ballState: StateControllingBall
@export var player: Player
@export var playerInput: PlayerInput

func enter() -> void:
	player.playerInput = playerInput

func process_physics(delta: float) -> void:
	playerInput.physics_process(delta)

	if (player.canGrabBall && playerInput.tryGrabABall()):
		change_state(ballState)
