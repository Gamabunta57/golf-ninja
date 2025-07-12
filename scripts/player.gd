class_name Player
extends CharacterBody2D

@export var horizontalSpeedStopThreshold = 5
@export var horizontalSpeed = 300
@export var maxHorizontalSpeed = 500
@export var horizontalDeceleration = 400
@export var gravity = 500
@export var jumpForce = 200

var canGrabBall: bool = false
var currentBallTarget: BallWithStateMachine = null

func _physics_process(delta: float):

	var direction = Input.get_axis("left", "right");
	if (abs(direction) > 0):
		velocity.x += direction * delta * horizontalSpeed
	elif (velocity.x > horizontalSpeedStopThreshold):
		velocity.x -= horizontalDeceleration * delta
	elif (velocity.x < -horizontalSpeedStopThreshold):
		velocity.x += horizontalDeceleration * delta
	else:
		velocity.x = 0

	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)

	if (is_on_floor()):
		velocity.y = 0
		if (Input.is_action_just_pressed("jump")):
			velocity.y -= jumpForce;
	elif velocity.y < 0:
		velocity.y += gravity * delta	
	else:
		velocity.y += gravity * 3 * delta

	if (currentBallTarget != null):
		canGrabBall = currentBallTarget.canBeShoot

	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body is not Ball || currentBallTarget != null):
		return

	if (body.canBeShoot):
		currentBallTarget = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if (body is Ball && currentBallTarget == body):
		currentBallTarget = null
