class_name FloorData
extends RefCounted

## Raw, Godot-scene-independent description of a single floor. Produced by the
## MapGenerator and consumed by both the systems layer and the renderers.
##
## `walkable_grid` is a row-major 2D grid: walkable_grid[y][x] is true when the
## cell at (x, y) can be occupied by the player/ball. Walls are false. Use the
## is_walkable()/set_walkable() helpers rather than indexing directly so bounds
## are checked consistently.

var floor_index: int = 0
var width: int = 0
var height: int = 0
var hole_position: Vector2i = Vector2i.ZERO
var conduits: Array[ConduitLink] = []
var elevator_positions: Array[Vector2i] = []
var doors: Array[DoorData] = []
var keycards: Array[KeycardData] = []
var camera_zones: Array[CameraZoneData] = []
var guard_patrols: Array[GuardPatrolData] = []
var walkable_grid: Array = []  # Array[Array] of bool, indexed [y][x]


func _init(p_floor_index: int = 0, p_width: int = 0, p_height: int = 0) -> void:
	floor_index = p_floor_index
	width = p_width
	height = p_height
	_init_grid()


## (Re)allocates walkable_grid to width x height, all cells walkable.
func _init_grid() -> void:
	walkable_grid = []
	for y in height:
		var row: Array = []
		row.resize(width)
		row.fill(true)
		walkable_grid.append(row)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_walkable(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	return bool(walkable_grid[cell.y][cell.x])


func set_walkable(cell: Vector2i, value: bool) -> void:
	if in_bounds(cell):
		walkable_grid[cell.y][cell.x] = value


func has_elevator_at(cell: Vector2i) -> bool:
	return elevator_positions.has(cell)


func get_door_at(cell: Vector2i) -> DoorData:
	for door in doors:
		if door.position == cell:
			return door
	return null


## True if this is the building's final floor (its hole ends the game).
## A floor is final when no conduit leaves it and it is the deepest floor;
## callers usually determine finality from BuildingData instead.
func is_final_hole(final_floor_index: int) -> bool:
	return floor_index == final_floor_index
