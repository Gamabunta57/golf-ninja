class_name GuardPatrolData
extends RefCounted

## Definition of a single guard's patrol and field of view. Guards are pinned to
## their own floor (GDD §4.4) and never use elevators.

var floor_index: int = 0
var patrol_path: Array[Vector2i] = []
var fov_angle_degrees: float = 90.0
var fov_range_cells: int = 4


func _init(
	p_floor_index: int = 0,
	p_patrol_path: Array[Vector2i] = [],
	p_fov_angle_degrees: float = 90.0,
	p_fov_range_cells: int = 4
) -> void:
	floor_index = p_floor_index
	patrol_path = p_patrol_path.duplicate()
	fov_angle_degrees = p_fov_angle_degrees
	fov_range_cells = p_fov_range_cells


## Spawn cell for the guard (first patrol waypoint, or origin if none set).
func spawn_cell() -> Vector2i:
	if patrol_path.is_empty():
		return Vector2i.ZERO
	return patrol_path[0]
