extends RigidBody2D

@onready var distance: RichTextLabel = %Distance
@onready var par: RichTextLabel = %Par
@onready var value: RichTextLabel = %Value
@onready var score: RichTextLabel = %Score

@onready var tooltip: Node2D = %Tooltip

var rng = RandomNumberGenerator.new()

var shoot_vector: Vector2 = Vector2.ZERO
var limited_shoot_vector: Vector2 = Vector2.ZERO
var final_vector: Vector2 = Vector2.ZERO
var current_line_width: float = 1.0

var points: PackedVector2Array

var ball_body: RigidBody2D
var player_position: Vector2 = Vector2.ZERO
var outside_bin: bool = true
var bin_distance: float = 0.0
var show_tooltip: bool = false

var last_velocity: float = 0.0

var strike_count: int = 0
var par_value: int = 0
var money: int = 0

var ball_radius: float = 1.0

@export var ball_color: Color = Color(0, 0, 0)
@export var collision_shape: CollisionShape2D
@export var ground_check: RayCast2D
@export var max_ball_speed := 900.0
@export var max_force: float = 100
@export var strength: float = 8
@export var max_preview_distance: float = 500.0 
@export var preview_max_points: int = 64
@export var trajectory_color: Color = Color(1, 1, 1)    # Base color
@export var alpha_increment: float = 0.05
@export var par_distance: float = 300
@export var par_cost: float = 10
@export var collison_velocity_threshold: float = 100
@export var min_line_width: float = 1.0
@export var max_line_width: float = 5.0



func _ready() -> void:
	SignalBus.shooting.connect(_set_vector_and_body)
	SignalBus.enters_bin.connect(_enters_bin)
	SignalBus.exits_bin.connect(_exits_bin)
	SignalBus.ball_in_range.connect(_display_tooltip)
	tooltip.hide()
	call_deferred("post_ready_setup")
	rng.randomize()
	ball_radius = rng.randf_range(8.0, 20.0)
	mass = ball_radius * 0.1
	update_ball_size()

func post_ready_setup() -> void:
	update_bin_distance()
	calculate_initial_par()
	update_cost()
	
func update_ball_size() -> void:
	collision_shape.shape = collision_shape.shape.duplicate()
	collision_shape.shape.radius = ball_radius

	if ground_check:
		ground_check.target_position = Vector2(0, ball_radius + 5.0)
	
	queue_redraw()

func _set_vector_and_body(vector: Vector2, body: RigidBody2D, player: Vector2) -> void:
	ball_body = body
	player_position = player
	if ball_body == self:
		shoot_vector = vector
		queue_redraw()


func _enters_bin(body: RigidBody2D) -> void:
	if body == self:
		outside_bin = false
		SignalBus.update_UI_money_count.emit(money)

func _exits_bin(body: RigidBody2D) -> void:
	if body == self:
		outside_bin = true
		SignalBus.update_UI_money_count.emit(-money)

func _physics_process(delta: float) -> void:
	if linear_velocity.length() > max_ball_speed:
		linear_velocity = linear_velocity.normalized() * max_ball_speed
	
	#print(int(linear_velocity.length()))
	# collides with enemies if airborn only
	if ground_check.is_colliding():
		set_collision_mask_value(7, false)
	else:
		set_collision_mask_value(7, true)
	
	if ball_body == self and outside_bin:
		last_velocity = linear_velocity.length()
		
		if Global.player_shooting:
			update_cost()
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			limited_shoot_vector = shoot_vector.limit_length(max_force)
			final_vector = limited_shoot_vector * strength
			var strength_weight = max(limited_shoot_vector.length() - 20, 0) / max_force
			current_line_width = lerp(min_line_width, max_line_width, strength_weight)
			points = preview_trajectory(final_vector, preview_max_points)
			emit_last_position(ball_body)

			
		if Global.shooting_action:
			Global.shooting_action = false
			strike_count += 1
			apply_impulse(final_vector)
			shoot_vector = Vector2.ZERO
			queue_redraw()
			SignalBus.ball_sound_emission.emit(global_position)
			

func _draw() -> void:
	# Draw the ball body
	draw_circle(Vector2.ZERO, ball_radius, ball_color)
	
	# --- Existing Trajectory Drawing ---
	if Global.player_shooting and points.size() > 1:
		var count: int = points.size() - 1
		for i in range(count):
			var alpha: float = clamp((count - i) * alpha_increment, 0.0, 1.0)
			var color_with_alpha: Color = trajectory_color
			color_with_alpha.a = alpha
			draw_line(to_local(points[i]), to_local(points[i + 1]), color_with_alpha, current_line_width)


func update_bin_distance() -> void:
	bin_distance = global_position.distance_to(Global.bin_position)
	distance.text = str("Distance: ", int(bin_distance))

func calculate_initial_par() -> void:
	par_value = int(ceil(bin_distance/par_distance))
	par.text = str("Par: ", par_value)

func update_cost() -> void:
	var score: int = max(0,(par_value - strike_count))
	money = max(score * par_cost, 1)
	value.text = str("Money: ", money, "$")

func _display_tooltip(body, nearby) -> void:
	if nearby and body == self:
		update_bin_distance()
		tooltip.show()
	else:
		tooltip.hide()

# --- Trajectory Simulation ---
func preview_trajectory(impulse: Vector2, max_points: int, dt: float = -1.0) -> PackedVector2Array:
	if dt <= 0.0:
		var ticks_per_second: int = ProjectSettings.get_setting("physics/2d/physics_ticks_per_second", 60)
		dt = 1.0 / ticks_per_second
	
	var points: PackedVector2Array = PackedVector2Array()

	var pos: Vector2 = global_position
	var v: Vector2 = linear_velocity + impulse / get_mass()
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	# Gravity
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var gravity_vec: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	var a: Vector2 = gravity_vec * gravity * gravity_scale

	# Linear damping
	var default_damp: float = ProjectSettings.get_setting("physics/2d/default_linear_damp")
	var damp: float = default_damp
	if linear_damp_mode == PhysicsServer2D.BODY_DAMP_MODE_REPLACE:
		damp = linear_damp
	else:
		damp += linear_damp

	points.push_back(pos)

	var traveled: float = 0.0

	for i in range(max_points):
		# Semi-implicit Euler
		v += a * dt
		v = v / (1.0 + damp * dt) 
		var motion: Vector2 = v * dt
		var new_pos: Vector2 = pos + motion

		traveled += motion.length()
		if traveled >= max_preview_distance:
			# clamp to max distance
			var dir: Vector2 = motion.normalized()
			var overshoot: float = traveled - max_preview_distance
			new_pos -= dir * overshoot
			points.push_back(new_pos)
			break

		# Ray collision check
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(pos, new_pos)
		query.exclude = [self]
		query.collision_mask = (1 << 1) | (1 << 2)   # check layer 2 and 3
		var result: Dictionary = space.intersect_ray(query)

		if result:
			var rid: RID = result.rid
			var layers: int = PhysicsServer2D.body_get_collision_layer(rid)
			var stop: bool = false

			if layers & (1 << 1):  # Layer 2 always stops
				stop = true
			elif layers & (1 << 2) and new_pos.y - pos.y > 0:  # Layer 3 stops only when moving down
				stop = true

			if stop:
				points.push_back(result.position)
				break
			else:
				pos = new_pos
				points.push_back(new_pos)
		else:
			pos = new_pos
			points.push_back(new_pos)

	return points

func emit_last_position(body: RigidBody2D) -> void:
	var last_position: Vector2 = points[points.size() - 1]
	SignalBus.last_trajectory_point.emit(last_position, body)

func _on_body_entered(body: Node) -> void:
	if last_velocity > collison_velocity_threshold:
		SignalBus.ball_sound_emission.emit(global_position)
