class_name FloorRenderer
extends Node2D

## Renders a single FloorData for visual inspection (plan Phase 4). Pure render
## boundary: it only READS core data and draws it — no gameplay logic, no
## mutation of the data it is given.
##
## ASSUMPTION (v1): this is a debug/data-inspection renderer drawn with _draw()
## rather than a painted TileMapLayer. Godot 4.7 deprecates TileMap and a tiled
## renderer needs an authored TileSet atlas; that (and real art) is deferred to
## a later art pass. The interface — set_floor_data() reading FloorData — stays
## the same, so swapping in a TileMapLayer later is localised to this file.

const CELL_SIZE: int = 32

# Palette (debug).
const COL_FLOOR: Color = Color(0.16, 0.17, 0.20)
const COL_WALL: Color = Color(0.07, 0.07, 0.09)
const COL_GRID: Color = Color(1, 1, 1, 0.04)
const COL_HOLE: Color = Color(0.0, 0.0, 0.0)
const COL_HOLE_RING: Color = Color(0.9, 0.9, 0.95)
const COL_CONDUIT: Color = Color(0.95, 0.55, 0.15)
const COL_ELEVATOR: Color = Color(0.25, 0.55, 0.95)
const COL_DOOR: Color = Color(0.85, 0.2, 0.25)
const COL_KEYCARD: Color = Color(0.95, 0.85, 0.2)
const COL_GUARD: Color = Color(0.95, 0.35, 0.35)
const COL_GUARD_PATH: Color = Color(0.95, 0.35, 0.35, 0.5)
const COL_PLAYER_START: Color = Color(0.3, 0.9, 0.4)
const COL_TEXT: Color = Color(1, 1, 1, 0.9)

var _floor: FloorData
var _player_start_cell: Vector2i = Vector2i(-1, -1)  # drawn only if on this floor
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


## Assigns the floor to render (and optionally the player-start cell to mark).
func set_floor_data(floor_data: FloorData, player_start_cell: Vector2i = Vector2i(-1, -1)) -> void:
	_floor = floor_data
	_player_start_cell = player_start_cell
	queue_redraw()


func pixel_size() -> Vector2:
	if _floor == null:
		return Vector2.ZERO
	return Vector2(_floor.width * CELL_SIZE, _floor.height * CELL_SIZE)


func _draw() -> void:
	if _floor == null:
		return
	_draw_grid()
	# Camera zones are drawn by live SecurityCamera nodes (Phase 7), not here.
	_draw_holes_and_conduits()
	_draw_elevators()
	_draw_doors()
	_draw_keycards()
	_draw_guards()
	_draw_player_start()


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)


func _draw_grid() -> void:
	for y in _floor.height:
		for x in _floor.width:
			var cell: Vector2i = Vector2i(x, y)
			var col: Color = COL_FLOOR if _floor.is_walkable(cell) else COL_WALL
			draw_rect(_cell_rect(cell), col, true)
	# Light grid overlay.
	var w_px: int = _floor.width * CELL_SIZE
	var h_px: int = _floor.height * CELL_SIZE
	for x in range(_floor.width + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, h_px), COL_GRID)
	for y in range(_floor.height + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(w_px, y * CELL_SIZE), COL_GRID)


func _draw_holes_and_conduits() -> void:
	# The floor hole (drops one floor down).
	var c: Vector2 = _cell_center(_floor.hole_position)
	draw_circle(c, CELL_SIZE * 0.34, COL_HOLE)
	draw_arc(c, CELL_SIZE * 0.34, 0, TAU, 24, COL_HOLE_RING, 2.0)
	# Conduit origins, labelled with their destination floor.
	for conduit: ConduitLink in _floor.conduits:
		var rect: Rect2 = _cell_rect(conduit.origin_position).grow(-6)
		draw_rect(rect, COL_CONDUIT, true)
		_label(conduit.origin_position, "->%d" % conduit.destination_floor)


func _draw_elevators() -> void:
	for pos: Vector2i in _floor.elevator_positions:
		var rect: Rect2 = _cell_rect(pos).grow(-5)
		draw_rect(rect, COL_ELEVATOR, true)
		draw_rect(rect, Color.WHITE, false, 2.0)
		_label(pos, "E")


func _draw_doors() -> void:
	for door: DoorData in _floor.doors:
		draw_rect(_cell_rect(door.position).grow(-8), COL_DOOR, true)
		_label(door.position, "L%d" % door.required_access_level)


func _draw_keycards() -> void:
	for card: KeycardData in _floor.keycards:
		var ctr: Vector2 = _cell_center(card.position)
		var r: float = CELL_SIZE * 0.28
		var pts: PackedVector2Array = [
			ctr + Vector2(0, -r), ctr + Vector2(r, 0), ctr + Vector2(0, r), ctr + Vector2(-r, 0)
		]
		draw_colored_polygon(pts, COL_KEYCARD)
		_label(card.position, "%d" % card.access_level)


func _draw_guards() -> void:
	for guard: GuardPatrolData in _floor.guard_patrols:
		# Patrol path.
		for i in range(guard.patrol_path.size() - 1):
			draw_line(_cell_center(guard.patrol_path[i]), _cell_center(guard.patrol_path[i + 1]), COL_GUARD_PATH, 2.0)
		# Spawn marker.
		draw_circle(_cell_center(guard.spawn_cell()), CELL_SIZE * 0.24, COL_GUARD)


func _draw_player_start() -> void:
	if _player_start_cell.x < 0:
		return
	draw_rect(_cell_rect(_player_start_cell).grow(-4), COL_PLAYER_START, false, 3.0)
	_label(_player_start_cell, "P")


func _label(cell: Vector2i, text: String) -> void:
	if _font == null:
		return
	var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 3, cell.y * CELL_SIZE + 13)
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_TEXT)
