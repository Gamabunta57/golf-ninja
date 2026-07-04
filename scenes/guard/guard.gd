class_name Guard
extends CharacterBody2D

## A patrolling guard (plan Phase 8, GDD §4.4). Pinned to its own floor; never
## uses elevators. Perception and the shoot-ball interrupt reuse the shared
## DetectionResolver's FOV helper. The FSM (GuardStateMachine) decides
## patrol/chase/search/return from the floor alarm; this node handles moving,
## firing the ball at max power on sight (spending 1 HP), and catching the
## player while chasing.
##
## Movement is straight-line steering with wall-slide (v1 has no A* pathfinding;
## floors are mostly open — # ASSUMPTION documented in the plan).

signal defeated(guard_id: int)
signal shot_ball(guard_id: int, hp_remaining: int)
signal caught_player

const SPEED: float = 95.0
const RADIUS: float = 11.0
const CATCH_DIST: float = 0.7 * FloorRenderer.CELL_SIZE
const ARRIVE_DIST: float = 3.0
const SHOOT_COOLDOWN: float = 1.2
const SHOOT_PAUSE: float = 0.4
const SCAN_SPEED: float = 2.2  # rad/sec while searching the last known position

var id: int
var data: GuardPatrolData
var floor_index: int
var floor_data: FloorData

var _detection: DetectionResolver
var _sm: GuardStateMachine
var _facing: Vector2 = Vector2.RIGHT
var _patrol_index: int = 0
var _cooldown: float = 0.0
var _pause_timer: float = 0.0
var _dead: bool = false


func setup(guard_id: int, guard_data: GuardPatrolData, fd: FloorData, detection: DetectionResolver, guard_hp: int) -> void:
	id = guard_id
	data = guard_data
	floor_index = guard_data.floor_index
	floor_data = fd
	_detection = detection
	_sm = GuardStateMachine.new(guard_hp)
	global_position = _cell_center(guard_data.spawn_cell())
	if guard_data.patrol_path.size() > 1:
		_facing = (Vector2(guard_data.patrol_path[1] - guard_data.patrol_path[0])).normalized()


func current_cell() -> Vector2i:
	return _world_to_cell(global_position)


## Does this guard currently see `player_cell`? Fed into the alarm aggregation.
func sees_player(player_cell: Vector2i) -> bool:
	if _dead:
		return false
	return _detection.cell_in_guard_fov(current_cell(), _facing, data.fov_angle_degrees, data.fov_range_cells, player_cell)


## Runs one frame of behaviour after the alarm has been resolved for this frame.
func act(delta: float, alarm: AlarmState, player: Player, ball: Ball) -> void:
	if _dead:
		return
	_cooldown = maxf(0.0, _cooldown - delta)

	# SHOOT_BALL interrupt takes priority over all states (GDD §4.4).
	if _pause_timer > 0.0:
		_pause_timer -= delta
		queue_redraw()
		return
	if _try_shoot(ball):
		return

	var reached_patrol: bool = _near_any_patrol_waypoint()
	_sm.update_state(alarm.get_state(floor_index), reached_patrol)

	match _sm.state:
		GuardStateMachine.State.PATROL:
			_do_patrol(delta)
		GuardStateMachine.State.CHASE:
			_do_chase(delta, player)
		GuardStateMachine.State.SEARCH:
			_do_search(delta, alarm)
		GuardStateMachine.State.RETURN_TO_PATROL:
			_steer_toward(_nearest_patrol_waypoint(), delta)
	queue_redraw()


func hp() -> int:
	return _sm.hp if _sm != null else 0


## Current field-of-view as plain data (for HidingSystem, which stays Godot- and
## Guard-agnostic).
func fov_view() -> Dictionary:
	return {
		"origin": current_cell(),
		"facing": _facing,
		"angle": data.fov_angle_degrees,
		"range": data.fov_range_cells,
	}


# --- behaviours -------------------------------------------------------------

func _do_patrol(delta: float) -> void:
	if data.patrol_path.is_empty():
		return
	var target: Vector2i = data.patrol_path[_patrol_index]
	if _arrived_at(target):
		_patrol_index = (_patrol_index + 1) % data.patrol_path.size()
		target = data.patrol_path[_patrol_index]
	_steer_toward(target, delta)


func _do_chase(delta: float, player: Player) -> void:
	if player == null:
		return
	# Direct pursuit of the player's live position.
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 0.001:
		_facing = to_player.normalized()
	if to_player.length() <= CATCH_DIST:
		caught_player.emit()
		return
	_steer_world(player.global_position, delta)


func _do_search(delta: float, alarm: AlarmState) -> void:
	var last: Vector2i = alarm.get_last_known_position(floor_index)
	if _arrived_at(last):
		# Scan the immediate area by sweeping the field of view.
		_facing = _facing.rotated(SCAN_SPEED * delta)
	else:
		_steer_toward(last, delta)


func _try_shoot(ball: Ball) -> bool:
	if ball == null or ball.state == null:
		return false
	if ball.state.current_floor != floor_index or ball.state.is_in_transit:
		return false
	if _cooldown > 0.0:
		return false
	if not _detection.cell_in_guard_fov(current_cell(), _facing, data.fov_angle_degrees, data.fov_range_cells, ball.state.cell()):
		return false

	# Fire "as far as possible" away from the guard (no strategic aiming).
	var dir: Vector2 = ball.global_position - global_position
	if dir.length_squared() < 0.01:
		dir = _facing
	ball.shoot(dir.normalized(), 1.0)
	_sm.take_ball_shot()
	_cooldown = SHOOT_COOLDOWN
	_pause_timer = SHOOT_PAUSE
	shot_ball.emit(id, _sm.hp)
	if not _sm.is_alive():
		_dead = true
		defeated.emit(id)
	return true


# --- steering & helpers -----------------------------------------------------

func _steer_toward(cell: Vector2i, delta: float) -> void:
	_steer_world(_cell_center(cell), delta)


func _steer_world(target_world: Vector2, delta: float) -> void:
	var to: Vector2 = target_world - global_position
	if to.length() <= ARRIVE_DIST:
		return
	var dir: Vector2 = to.normalized()
	_facing = dir
	var step: Vector2 = dir * SPEED * delta
	var pos: Vector2 = global_position
	if _is_free(pos + Vector2(step.x, 0)):
		pos.x += step.x
	if _is_free(Vector2(pos.x, pos.y) + Vector2(0, step.y)):
		pos.y += step.y
	global_position = pos


func _arrived_at(cell: Vector2i) -> bool:
	return global_position.distance_to(_cell_center(cell)) <= ARRIVE_DIST


func _near_any_patrol_waypoint() -> bool:
	for wp: Vector2i in data.patrol_path:
		if _arrived_at(wp):
			return true
	return false


func _nearest_patrol_waypoint() -> Vector2i:
	var best: Vector2i = data.spawn_cell()
	var best_d: float = INF
	for wp: Vector2i in data.patrol_path:
		var d: float = global_position.distance_to(_cell_center(wp))
		if d < best_d:
			best_d = d
			best = wp
	return best


func _is_free(world_pos: Vector2) -> bool:
	if floor_data == null:
		return false
	for off in [Vector2(-RADIUS, -RADIUS), Vector2(RADIUS, -RADIUS), Vector2(-RADIUS, RADIUS), Vector2(RADIUS, RADIUS)]:
		if not floor_data.is_walkable(_world_to_cell(world_pos + off)):
			return false
	return true


func _world_to_cell(p: Vector2) -> Vector2i:
	var cs: int = FloorRenderer.CELL_SIZE
	return Vector2i(floori(p.x / cs), floori(p.y / cs))


func _cell_center(cell: Vector2i) -> Vector2:
	var cs: int = FloorRenderer.CELL_SIZE
	return Vector2((cell.x + 0.5) * cs, (cell.y + 0.5) * cs)


# --- drawing ----------------------------------------------------------------

func _draw() -> void:
	if _dead:
		return
	# Field-of-view cone.
	var reach: float = data.fov_range_cells * FloorRenderer.CELL_SIZE
	var half: float = deg_to_rad(data.fov_angle_degrees) * 0.5
	var a: float = _facing.angle()
	var pts: PackedVector2Array = [Vector2.ZERO]
	var steps: int = 10
	for i in range(steps + 1):
		var ang: float = a - half + (2.0 * half) * (float(i) / steps)
		pts.append(Vector2.from_angle(ang) * reach)
	var cone_col: Color = Color(0.95, 0.3, 0.3, 0.12)
	if _sm != null and _sm.state == GuardStateMachine.State.CHASE:
		cone_col = Color(1.0, 0.25, 0.2, 0.22)
	draw_colored_polygon(pts, cone_col)

	# Body + HP pips.
	draw_circle(Vector2.ZERO, RADIUS + 1.0, Color(0.25, 0.03, 0.03))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.9, 0.3, 0.3))
	for i in hp():
		draw_circle(Vector2(-RADIUS + 3 + i * 6.0, -RADIUS - 6.0), 2.5, Color(1, 1, 1, 0.9))
