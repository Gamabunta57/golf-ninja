extends Line2D

@export var ball: Ball
@export var forceColor: Gradient

func _process(delta: float) -> void:
	visible = ball.canBeShoot
	if (!visible): return

	set_point_position(1, getForceVector())
	position = ball.position
	
	var forcePercentage: float = inverse_lerp(ball.forceMin, ball.forceMax, ball.force)
	set_default_color(forceColor.sample(forcePercentage))

func getForceVector() -> Vector2:
	return Vector2(cos(ball.angle), sin(ball.angle)) * ball.force 
