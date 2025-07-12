class_name Ball
extends RigidBody2D

@export var angle: float = 0
@export var angleSpeed: float = 2
@export var force: float = 50
@export var forceModificationSpeed = 20
@export var forceMin: float = 10
@export var forceMax: float = 100
@export var colorShootable: Color = Color.AQUAMARINE
@export var colorNonShootable: Color = Color.DEEP_PINK
@onready var activeStateLine: Line2D = $Line2D

var canBeShoot: bool = true
var isControlled: bool = false

func _physics_process(delta: float) -> void:
	canBeShoot = linear_velocity.length_squared() < 4
	if (canBeShoot):
		activeStateLine.set_default_color(colorShootable)
	else:
		activeStateLine.set_default_color(colorNonShootable)

	if (canBeShoot && Input.is_action_just_pressed("shoot")):
		linear_velocity += getForceVector() * 20

	var direction: float = Input.get_axis("left", "right")
	if (direction != 0): 
		angle += angleSpeed * direction * delta

	var forceDirection: float = Input.get_axis("down", "up")
	if (forceDirection != 0):
		force += forceModificationSpeed * forceDirection * delta
		force = clamp(force, forceMin, forceMax)

func getForceVector() -> Vector2:
	return Vector2(cos(angle), sin(angle)) * force
