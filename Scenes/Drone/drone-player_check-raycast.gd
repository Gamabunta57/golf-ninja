extends RayCast2D

@onready var parent = get_parent()
@export var navigation_agent: NavigationAgent2D

var player_body: CharacterBody2D
var player_detected: bool
var player_last_position: Vector2 = Vector2.ZERO

var ball_position: Vector2 = Vector2.ZERO
const ball_hearing_radius: float = 500.0  # tweak
const target_offset: Vector2 = Vector2(0.0, 25.0)

func _ready() -> void:
	SignalBus.ball_sound_emission.connect(_on_ball_sound_emission)

func _physics_process(delta: float) -> void:
	
	if player_detected:
		target_position = to_local(Global.player_body.global_position - target_offset)
	else:
		target_position = Vector2.ZERO
		parent.player_visible = false
		
	force_raycast_update()

	if is_colliding():
		var collider = get_collider()
		if collider and collider.is_in_group("Player") and not Global.player_hidden:
			parent.should_chase_player = true
			parent.player_visible = true
			parent.should_chase_ball = false
		else:
			parent.player_visible = false
	
	print(str("should chase player: ",parent.should_chase_player,", should chase ball: ",parent.should_chase_ball,", player visible: ", parent.player_visible,", player detected: ", player_detected))

	if parent.should_chase_player and parent.player_visible:
		navigation_agent.target_position = Global.player_body.global_position - Vector2(0.0, 50.0)
	
	if parent.should_chase_ball:
		navigation_agent.target_position = ball_position - Vector2(0.0, 50.0)

func _on_detection_zone_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_detected = true

func _on_detection_zone_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_detected = false

func _on_ball_sound_emission(pos: Vector2) -> void:
	# Only drones close enough should hear the sound.
	if parent.global_position.distance_to(pos) > ball_hearing_radius:
		return
	
	# If currently chasing a visible player ignore the sound.
	if parent.player_visible:
		return
	
	# set target.
	print("ball emmited")
	parent.should_chase_player = false
	parent.should_chase_ball = true
	ball_position = pos
