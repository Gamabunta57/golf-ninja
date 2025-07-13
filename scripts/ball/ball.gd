class_name Ball
extends RigidBody2D

@export var strengthMin: float = 10
@export var strengthMax: float = 100
@export var colorShootable: Color = Color.AQUAMARINE
@export var colorNonShootable: Color = Color.DEEP_PINK

var ballInput: BallInput

var canBeShoot: bool = true
var isControlled: bool = false
var isShot: bool = false
