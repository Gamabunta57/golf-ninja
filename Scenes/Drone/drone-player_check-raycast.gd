extends RayCast2D

@onready var parent = get_parent() 
var target: Vector2 = Vector2.ZERO

func _ready() -> void:
	SignalBus.ball_sound_emission.connect(_on_ball_sound_emission)

func _process(delta: float) -> void:
	target_position = to_local(target - Vector2(0.0, 25.0))

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		parent.current_target = body
		target = body.global_position
	
	elif body.is_in_group("Ball") and parent.current_target == null:
		parent.current_target = body
		target = body.global_position

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if parent.current_target == body:
		# Save last known position before forgetting target
		parent.last_known_position = body.global_position - Vector2(0.0, 25.0)
		parent.has_last_known_position = true
		parent.current_target = null

func _on_ball_sound_emission(pos: Vector2) -> void:
	var hearing_radius: float = 500.0  # tweak this
	if parent.global_position.distance_to(pos) <= hearing_radius:
		# Only react if close enough and not tracking the player
		if not (parent.current_target and parent.current_target.is_in_group("Player")):
			parent.last_known_position = pos - Vector2(0.0, 25.0)
			parent.has_last_known_position = true
			parent.current_target = null
