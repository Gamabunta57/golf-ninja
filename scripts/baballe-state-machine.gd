class_name BallWithStateMachine
extends Ball

var isShot: bool = false
var angleUpdateDirection: float = 0.0
var forceUpdateDirection: float = 0.0

func _physics_process(delta: float) -> void:
	canBeShoot = linear_velocity.length_squared() < 4
	if (canBeShoot):
		activeStateLine.set_default_color(colorShootable)
	else:
		activeStateLine.set_default_color(colorNonShootable)

	if (canBeShoot && isShot):
		isShot = false
		linear_velocity += getForceVector() * 20

	if (angleUpdateDirection != 0): 
		angle += angleSpeed * angleUpdateDirection * delta

	if (forceUpdateDirection != 0):
		force += forceModificationSpeed * forceUpdateDirection * delta
		force = clamp(force, forceMin, forceMax)

func getForceVector() -> Vector2:
	return Vector2(cos(angle), sin(angle)) * force
