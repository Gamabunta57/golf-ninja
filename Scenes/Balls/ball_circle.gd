extends RigidBody2D

@onready var counter: RichTextLabel = $Tooltip/Panel/RichTextLabel
@onready var tooltip: Node2D = $Tooltip

var shoot_vector: Vector2 = Vector2.ZERO
var limited_shoot_vector: Vector2 = Vector2.ZERO
var final_vector: Vector2 = Vector2.ZERO

var points: PackedVector2Array

var ball_body: RigidBody2D
var player_position: Vector2 = Vector2.ZERO
var outside_bin: bool = true

var strike_count: int = 0

@export var default_delta: Vector2 = Vector2(20, -20)
@export var max_force: float = 50
@export var strength: float = 8
@export var preview_max_points: int = 64
@export var trajectory_color: Color = Color(1, 1, 1)    # Base color
@export var alpha_increment: float = 0.05

func _ready() -> void:
	SignalBus.shooting.connect(_set_vector_and_body)
	SignalBus.enters_bin.connect(_enters_bin)
	SignalBus.exits_bin.connect(_exits_bin)
	update_counter_display()
	tooltip.hide()


func _set_vector_and_body(vector: Vector2, body: RigidBody2D, player: Vector2) -> void:
	ball_body = body
	player_position = player
	if ball_body == self:
		set_default_orientation()
		shoot_vector = vector + default_delta
		queue_redraw()

func set_default_orientation() -> void:
	if global_position.x > player_position.x:
		default_delta.x = abs(default_delta.x)
	else:
		default_delta.x = -abs(default_delta.x)

func _enters_bin(body: RigidBody2D) -> void:
	if body == self:
		outside_bin = false

func _exits_bin(body: RigidBody2D) -> void:
	if body == self:
		outside_bin = true

func _physics_process(delta: float) -> void:
	if ball_body == self and outside_bin:
		if Global.player_shooting:
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			limited_shoot_vector = shoot_vector.limit_length(max_force)
			final_vector = limited_shoot_vector * strength
			points = preview_trajectory(final_vector, preview_max_points)
			tooltip.show()
			
		if Global.shooting_action:
			Global.shooting_action = false
			strike_count += 1
			update_counter_display()
			apply_impulse(final_vector)
			shoot_vector = Vector2.ZERO
			queue_redraw()
			tooltip.hide()

func _draw() -> void:
	if Global.player_shooting and points.size() > 1:
		var count: int = points.size() - 1
		for i in range(count):
			# Calculate alpha from end to start
			var alpha: float = clamp((count - i) * alpha_increment, 0.0, 1.0)
			var color_with_alpha: Color = trajectory_color
			color_with_alpha.a = alpha
			draw_line(to_local(points[i]), to_local(points[i + 1]), color_with_alpha, 1)

func update_counter_display() -> void:
	counter.text = str("Strikes: ", strike_count)

func _process(delta: float) -> void:
	tooltip.global_rotation = 0.0

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

	for i in range(max_points):
		# Semi-implicit Euler
		v += a * dt
		v = v / (1.0 + damp * dt) 
		var motion: Vector2 = v * dt
		var new_pos: Vector2 = pos + motion

		# Inside preview_trajectory loop...
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
