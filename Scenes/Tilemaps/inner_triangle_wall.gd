extends StaticBody2D

var rng = RandomNumberGenerator.new()
var player_inside: bool = false

# Animation variables
var is_rotating: bool = false
var time_elapsed: float = 0.0
var start_angle: float = 0.0
var target_angle: float = 0.0

@export var rotation_curve: Curve
@export var rotation_duration: float = 1.0

var stop_rotation: bool = false

func _ready() -> void:
	rng.randomize()
	
	if rng.randi_range(1, 5) == 1:
		queue_free()
		return
	
	var angles = [0, 120, -120]
	var weights = PackedFloat32Array([4.0, 1.0, 1.0])
	
	var index = rng.rand_weighted(weights)
	rotation_degrees = angles[index]

func _physics_process(delta: float) -> void:
	#$Area2D.global_rotation = 0
	
	#if Input.is_action_just_pressed("shooting") and player_inside and not is_rotating and not Global.player_shooting:
		#start_rotation_animation()
	if Global.rotate_platform:
		if Global.kunai_anchor_object == self:
			start_rotation_animation()
			Global.rotate_platform = false # Reset the flag
	
	if Global.is_clipping_world:
		print("should stop")
		stop_rotation = true
	
	if stop_rotation and not player_inside:
		stop_rotation = false
		
	if is_rotating:
		if stop_rotation:
			return
		process_rotation_animation(delta)

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
		# Optional: Ensure it lands exactly on the target to avoid float drift
		rotation_degrees = target_angle

func _on_area_2d_body_entered(body: Node2D) -> void:
	player_inside = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	player_inside = false
