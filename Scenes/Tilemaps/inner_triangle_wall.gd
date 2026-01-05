extends StaticBody2D

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D

var rng = RandomNumberGenerator.new()
var player_inside: bool = false

# Animation variables
var is_rotating: bool = false
var time_elapsed: float = 0.0
var start_angle: float = 0.0
var target_angle: float = 0.0

@export var rotation_curve: Curve
@export var rotation_duration: float = 1.0
@export var ball: PackedScene
@export var sentinel: PackedScene
@export var light_occluded: LightOccluder2D

var stop_rotation: bool = false

func _ready() -> void:
	set_physics_process(false)

func trigger_rotation() -> void:
	if is_rotating: return
	start_rotation_animation()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	
	if Global.is_clipping_world:
		stop_rotation = true
	
	if stop_rotation and not player_inside:
		stop_rotation = false
		
	if is_rotating:
		if stop_rotation:
			return
		process_rotation_animation(delta)
	else:
		set_physics_process(false)

func start_rotation_animation() -> void:
	is_rotating = true
	time_elapsed = 0.0
	start_angle = rotation_degrees
	target_angle = start_angle + 120 

func process_rotation_animation(delta: float) -> void:
	time_elapsed += delta
	
	# Calculate progress (0.0 to 1.0)
	var t = clamp(time_elapsed / rotation_duration, 0.0, 1.0)
	
	# Sample the curve at point 't'      xxxxxxxx x xxxx  
	# This assumes your Curve goes from Y=0 to Y=1 in the inspector
	var curve_value = rotation_curve.sample(t)
	
	# Lerp calculates the angle between start and target based on the curve
	rotation_degrees = lerp(start_angle, target_angle, curve_value)
	
	# End animation when time is up
	if time_elapsed >= rotation_duration:
		is_rotating = false
		rotation_degrees = target_angle
		check_for_cleanup()

func _on_player_detection_body_entered(body: Node2D) -> void:
	player_inside = true

func _on_player_detection_body_exited(body: Node2D) -> void:
	player_inside = false
	if not is_rotating:
		check_for_cleanup()
func check_for_cleanup():
	if not player_inside and not is_rotating:
		# Tell TileMap to place static tile
		Global.level_tilemap.swap_scene_for_tile(global_position, rotation_degrees)
		queue_free()
