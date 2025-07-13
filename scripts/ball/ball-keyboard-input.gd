class_name BallKeyboardInput
extends BallInput

@export var angleSpeed: float = 2.0 
@export var strengthSpeed: float = 20.0

var _shouldShoot: bool = false

func physics_process(delta: float) -> void:
	if (ball == null): return

	var angleDirectionUpdate = Input.get_axis("left", "right");
	if (!is_zero_approx(angleDirectionUpdate)):
		angle += angleDirectionUpdate * angleSpeed  * delta

	var strengthUpdate = Input.get_axis("down", "up")
	if (!is_zero_approx(strengthUpdate)):
		strength += strengthUpdate * strengthSpeed * delta
		strength = clampf(strength, ball.strengthMin, ball.strengthMax)
	
	_shouldShoot = Input.is_action_just_pressed("shoot")

func shouldShoot() -> bool:
	return _shouldShoot

func getDirectionWithStrength() -> Vector2:
	return Vector2(cos(angle), sin(angle)) * strength
