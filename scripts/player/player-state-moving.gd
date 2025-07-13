extends State

@onready var player: Player = $"../.." 

var playerInput: PlayerInput

func _ready() -> void:
	playerInput = player.playerInput

func process_physics(delta: float) -> void:
	var xDirectionUpdate = playerInput.getHorizontalDirection()
	if (!is_zero_approx(xDirectionUpdate)):
		player.velocity.x += xDirectionUpdate * delta * player.horizontalSpeed
	elif (player.velocity.x > player.horizontalSpeedStopThreshold):
		player.velocity.x -= player.horizontalDeceleration * delta
	elif (player.velocity.x < -player.horizontalSpeedStopThreshold):
		player.velocity.x += player.horizontalDeceleration * delta
	else:
		player.velocity.x = 0.0

	player.velocity.x = clamp(player.velocity.x, -player.maxHorizontalSpeed, player.maxHorizontalSpeed)

	if (player.is_on_floor()):
		player.velocity.y = 0
		if (playerInput.shouldJump()):
			player.velocity.y -= player.jumpForce;
	elif player.velocity.y < 0:
		player.velocity.y += player.gravity * delta	
	else:
		player.velocity.y += player.gravity * 3 * delta

	if (player.currentBallTarget != null):
		player.canGrabBall = player.currentBallTarget.canBeShoot

	player.move_and_slide()
