class_name DetectionResolver
extends RefCounted

## Drives the two-state alarm per floor (GDD §3.3, plan Phase 7). Godot-agnostic:
## it owns an AlarmState, exposes line-of-sight helpers, and runs the per-floor
## state machine, emitting a signal on each transition. Designed to be SHARED by
## the guard AI (Phase 8): the LOS helpers independently answer "is this cell in
## a camera zone / guard FOV", and guards feed their own player-sighting into
## update_floor while separately querying ball-sighting for their shoot behaviour.
##
##   INACTIVE --player seen--> ACTIVE
##   ACTIVE   --lost sight---> SEARCHING (freeze last known pos, start timer)
##   SEARCHING--re-seen------> ACTIVE
##   SEARCHING--timer 0------> INACTIVE

signal alarm_triggered(floor_index: int)
signal alarm_searching(floor_index: int, last_known_position: Vector2i)
signal alarm_cleared(floor_index: int)

var alarm: AlarmState = AlarmState.new()


## True if a non-jammed camera on this floor observes `cell`.
func camera_sees_cell(floor_data: FloorData, cell: Vector2i, now_ms: int) -> bool:
	for cam: CameraZoneData in floor_data.camera_zones:
		if cam.is_jammed(now_ms):
			continue
		if cam.observes(cell):
			return true
	return false


## True if `cell` lies within a guard's field of view: inside range and within
## the FOV half-angle of the guard's facing direction. Shared by Phase 8 for
## both "sees player" and "sees ball".
func cell_in_guard_fov(origin: Vector2i, facing: Vector2, fov_angle_degrees: float, fov_range_cells: int, cell: Vector2i) -> bool:
	if origin == cell:
		return true
	var to_cell: Vector2 = Vector2(cell - origin)
	if to_cell.length() > float(fov_range_cells):
		return false
	if facing.length_squared() < 0.0001:
		return true
	var half: float = deg_to_rad(fov_angle_degrees) * 0.5
	return absf(facing.normalized().angle_to(to_cell.normalized())) <= half


## Advances one floor's alarm state for this frame.
## `seen` = is the player currently observed on this floor (by any camera/guard);
## the caller composes it from the LOS helpers. `player_cell` is the observed
## position (recorded as last-known while ACTIVE). Emits the matching transition
## signal. Safe to call every frame for every floor.
func update_floor(floor_index: int, seen: bool, player_cell: Vector2i, search_duration: float, delta: float) -> void:
	var current: AlarmState.State = alarm.get_state(floor_index)
	if seen:
		var was_active: bool = current == AlarmState.State.ACTIVE
		alarm.set_active(floor_index, player_cell)
		if not was_active:
			alarm_triggered.emit(floor_index)
		return

	match current:
		AlarmState.State.ACTIVE:
			var last: Vector2i = alarm.get_last_known_position(floor_index)
			alarm.set_searching(floor_index, last, search_duration)
			alarm_searching.emit(floor_index, last)
		AlarmState.State.SEARCHING:
			if alarm.tick_search(floor_index, delta):
				alarm.set_inactive(floor_index)
				alarm_cleared.emit(floor_index)
		_:
			pass
