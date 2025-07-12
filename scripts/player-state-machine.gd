class_name PlayerWithStateMachine
extends Player

var shouldJump: bool = false
var xDirectionUpdate: float = 0.0

func _physics_process(delta: float):
	if (!is_zero_approx(xDirectionUpdate)):
		velocity.x += xDirectionUpdate * delta * horizontalSpeed
	elif (velocity.x > horizontalSpeedStopThreshold):
		velocity.x -= horizontalDeceleration * delta
	elif (velocity.x < -horizontalSpeedStopThreshold):
		velocity.x += horizontalDeceleration * delta
	else:
		velocity.x = 0.0

	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)

	if (is_on_floor()):
		velocity.y = 0
		if (shouldJump):
			shouldJump = false
			velocity.y -= jumpForce;
	elif velocity.y < 0:
		velocity.y += gravity * delta	
	else:
		velocity.y += gravity * 3 * delta

	if (currentBallTarget != null):
		canGrabBall = currentBallTarget.canBeShoot

	move_and_slide()
