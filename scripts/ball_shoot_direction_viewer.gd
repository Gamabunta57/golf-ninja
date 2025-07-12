extends Line2D

@export var player: Player
@export var forceColor: Gradient

func _process(_delta: float) -> void:
	if (player.currentBallTarget == null): return

	var ball = player.currentBallTarget
	visible = ball.canBeShoot && ball.isControlled
	if (!visible): return

	set_point_position(1, getForceVector(ball))
	position = ball.position
	
	var forcePercentage: float = inverse_lerp(ball.forceMin, ball.forceMax, ball.force)
	set_default_color(forceColor.sample(forcePercentage))

func getForceVector(ball: Ball) -> Vector2:
	return Vector2(cos(ball.angle), sin(ball.angle)) * ball.force 
