extends Line2D

@export var player: Player
@export var forceColor: Gradient
@export var ballInput: BallInput

func _physics_process(_delta: float) -> void:
	if (player.currentBallTarget == null): return

	var ball = player.currentBallTarget
	visible = ball.canBeShoot && ball.isControlled
	if (!visible): return

	set_point_position(1, ballInput.getDirectionWithStrength())
	position = ball.position
	
	var forcePercentage: float = inverse_lerp(ball.strengthMin, ball.strengthMax, ballInput.strength)
	set_default_color(forceColor.sample(forcePercentage))
