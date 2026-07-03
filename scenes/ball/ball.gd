class_name Ball
extends Node2D

## The toxic golf ball (plan Phase 6). Owns a BallState and steps it through the
## BallPhysicsResolver each physics frame while at rest-or-rolling on its current
## floor. On a hole/conduit it plays a fixed-duration transit, then arrives at
## rest on the destination floor. Reaching the final floor's hole wins.
##
## Position is kept in CELL space by BallState; the node's pixel position is
## grid_position * CELL_SIZE (matching FloorRenderer's cell layout).

signal stopped
signal reached_floor(floor_index: int)
signal reached_final_hole

const TRANSIT_DURATION: float = 0.6  # fixed per-transition time (v1; not distance-scaled)
const RADIUS: float = 8.0
const COL_BODY: Color = Color(0.55, 0.95, 0.4)
const COL_OUTLINE: Color = Color(0.1, 0.25, 0.05)

var state: BallState
var building: BuildingData
var jam_radius_cells: float = 2.0
var jam_duration_ms: int = 3000

var _resolver: BallPhysicsResolver = BallPhysicsResolver.new()
var _transit_timer: float = 0.0
var _pending_floor: int = -1
var _pending_cell: Vector2i = Vector2i.ZERO


func setup(new_building: BuildingData, config: GenerationConfig = null) -> void:
	building = new_building
	if config != null:
		jam_radius_cells = float(config.ball_jam_radius_cells)
		jam_duration_ms = int(config.camera_jam_duration_sec * 1000.0)
	state = BallState.new(building.ball_start_floor, _cell_center_cs(building.ball_start_cell))
	_sync_position()


func current_cell() -> Vector2i:
	return state.cell()


func is_at_rest() -> bool:
	return state != null and not state.is_in_transit and not state.is_moving()


func shoot(direction: Vector2, power: float) -> void:
	if state == null or state.is_in_transit:
		return
	_resolver.apply_shot(state, direction, power)


func _physics_process(delta: float) -> void:
	if state == null or building == null:
		return
	if state.is_in_transit:
		_tick_transit(delta)
		return

	var fd: FloorData = building.get_floor(state.current_floor)
	if fd == null:
		return

	_resolver.apply_camera_jam(state, fd, jam_radius_cells, Time.get_ticks_msec(), jam_duration_ms)

	var was_moving: bool = state.is_moving()
	var result: Dictionary = _resolver.step(state, fd, delta)
	_sync_position()

	match result["event"]:
		BallPhysicsResolver.EVENT_HOLE:
			_on_hole()
		BallPhysicsResolver.EVENT_CONDUIT:
			_begin_transit(result["conduit"].destination_floor, result["conduit"].destination_position)
		BallPhysicsResolver.EVENT_STOPPED:
			if was_moving:
				stopped.emit()


func _on_hole() -> void:
	if state.current_floor >= building.final_floor_index():
		reached_final_hole.emit()
		return
	# A floor hole drops straight down one floor, landing at the same coordinate.
	var dest_floor: int = state.current_floor + 1
	var dest_cell: Vector2i = _nearest_walkable(building.get_floor(dest_floor), state.cell())
	_begin_transit(dest_floor, dest_cell)


func _begin_transit(dest_floor: int, dest_cell: Vector2i) -> void:
	state.is_in_transit = true
	state.velocity = Vector2.ZERO
	_transit_timer = TRANSIT_DURATION
	_pending_floor = dest_floor
	_pending_cell = dest_cell


func _tick_transit(delta: float) -> void:
	_transit_timer -= delta
	if _transit_timer > 0.0:
		return
	state.current_floor = _pending_floor
	state.grid_position = _cell_center_cs(_pending_cell)
	state.velocity = Vector2.ZERO
	state.is_in_transit = false
	_sync_position()
	reached_floor.emit(state.current_floor)
	stopped.emit()


## Nearest walkable cell to `cell` on `fd` (spiral-ish scan), falling back to the
## cell itself. Used when a hole lands the ball on a non-walkable coordinate.
func _nearest_walkable(fd: FloorData, cell: Vector2i) -> Vector2i:
	if fd.is_walkable(cell):
		return cell
	for radius in range(1, maxi(fd.width, fd.height)):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var c: Vector2i = cell + Vector2i(dx, dy)
				if fd.is_walkable(c):
					return c
	return cell


func _cell_center_cs(cell: Vector2i) -> Vector2:
	return Vector2(cell.x + 0.5, cell.y + 0.5)


func _sync_position() -> void:
	position = state.grid_position * float(FloorRenderer.CELL_SIZE)
	queue_redraw()


func _draw() -> void:
	if state != null and state.is_in_transit:
		return
	draw_circle(Vector2.ZERO, RADIUS + 1.0, COL_OUTLINE)
	draw_circle(Vector2.ZERO, RADIUS, COL_BODY)
