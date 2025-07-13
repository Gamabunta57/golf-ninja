class_name Player
extends CharacterBody2D

@export var horizontalSpeedStopThreshold = 5
@export var horizontalSpeed = 300
@export var maxHorizontalSpeed = 500
@export var horizontalDeceleration = 400
@export var gravity = 500
@export var jumpForce = 200

var playerInput: PlayerInput
var canGrabBall: bool = false
var currentBallTarget: Ball = null

func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body is not Ball || currentBallTarget != null):
		return

	if (body.canBeShoot):
		currentBallTarget = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if (body is Ball && currentBallTarget == body):
		currentBallTarget = null
