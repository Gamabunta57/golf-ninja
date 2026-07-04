class_name HidingSystem
extends RefCounted

## Validates concealment (plan §7.3 #7, Phase 9). A locker (or an elevator) can
## only be used to hide if the player is NOT currently observed at that moment —
## hiding must happen BEFORE detection, not as an instant escape from a camera
## or a guard already looking at you (GDD §3.3).
##
## Godot-agnostic: it composes the shared DetectionResolver's LOS helpers.
## Guard views are passed as plain dicts { origin, facing, angle, range } so this
## system never depends on the Guard scene class.

## True if `cell` on `floor_data` is currently unobserved by any non-jammed
## camera and outside every guard's field of view — i.e. hiding there succeeds.
func can_conceal(detection: DetectionResolver, floor_data: FloorData, cell: Vector2i, now_ms: int, guard_views: Array) -> bool:
	if detection.camera_sees_cell(floor_data, cell, now_ms):
		return false
	for view: Dictionary in guard_views:
		if detection.cell_in_guard_fov(view["origin"], view["facing"], view["angle"], view["range"], cell):
			return false
	return true


## True if `cell` holds a locker on this floor.
func has_locker(floor_data: FloorData, cell: Vector2i) -> bool:
	return floor_data.has_locker_at(cell)
