class_name StateBallControlled
extends State

@export var player: CharacterBody2D
@export var ball: BallWithStateMachine 

func onEnter() -> void:
	player.set_process_input(false)
	ball.set_process_input(true)

func physics_process(delta: float) -> void:
	ball.canBeShoot = true
	ball.isShot = Input.is_action_just_pressed("shoot")
	ball.angleUpdateDirection = Input.get_axis("left", "right")
	ball.forceUpdateDirection = Input.get_axis("down", "up")
