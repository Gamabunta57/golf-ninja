class_name TestDetectionAlarm
extends RefCounted

## Phase 7: the two-state alarm transitions correctly and emits the right
## signals; jammed cameras stop detecting; the guard-FOV helper is sane. Pure
## logic, so fully headless.

const FLOOR := 0
const DUR := 8.0


## Records the transition signals for assertions.
class Recorder:
	var triggered: int = 0
	var searching: int = 0
	var cleared: int = 0
	var last_search_pos: Vector2i = Vector2i(-99, -99)
	func on_triggered(_f: int) -> void: triggered += 1
	func on_searching(_f: int, pos: Vector2i) -> void:
		searching += 1
		last_search_pos = pos
	func on_cleared(_f: int) -> void: cleared += 1


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_full_cycle(failures)
	_test_research_resets(failures)
	_test_camera_jam(failures)
	_test_fov_helper(failures)
	return failures


func _make_resolver(rec: Recorder) -> DetectionResolver:
	var r: DetectionResolver = DetectionResolver.new()
	r.alarm_triggered.connect(rec.on_triggered)
	r.alarm_searching.connect(rec.on_searching)
	r.alarm_cleared.connect(rec.on_cleared)
	return r


func _camera_floor() -> FloorData:
	var fd: FloorData = FloorData.new(0, 10, 10)
	var cam: CameraZoneData = CameraZoneData.new(Vector2i(4, 5), [Vector2i(5, 5)] as Array[Vector2i])
	fd.camera_zones.append(cam)
	return fd


func _test_full_cycle(failures: Array[String]) -> void:
	var rec: Recorder = Recorder.new()
	var r: DetectionResolver = _make_resolver(rec)

	# Enter sight -> ACTIVE (triggered once, even across repeated frames).
	r.update_floor(FLOOR, true, Vector2i(5, 5), DUR, 0.1)
	r.update_floor(FLOOR, true, Vector2i(5, 5), DUR, 0.1)
	if not r.alarm.is_active(FLOOR) or rec.triggered != 1:
		failures.append("full_cycle: expected ACTIVE with 1 trigger, got state=%d triggered=%d" % [r.alarm.get_state(FLOOR), rec.triggered])
		return

	# Lose sight -> SEARCHING, freezing the last observed cell (not the new one).
	r.update_floor(FLOOR, false, Vector2i(9, 9), DUR, 0.1)
	if not r.alarm.is_searching(FLOOR) or rec.searching != 1:
		failures.append("full_cycle: expected SEARCHING after losing sight")
		return
	if rec.last_search_pos != Vector2i(5, 5):
		failures.append("full_cycle: searching froze wrong pos %s (want (5,5))" % rec.last_search_pos)
		return

	# Timer runs down -> INACTIVE.
	for _i in 90:
		r.update_floor(FLOOR, false, Vector2i(9, 9), DUR, 0.1)
	if r.alarm.get_state(FLOOR) != AlarmState.State.INACTIVE or rec.cleared != 1:
		failures.append("full_cycle: expected INACTIVE after timer, state=%d cleared=%d" % [r.alarm.get_state(FLOOR), rec.cleared])


func _test_research_resets(failures: Array[String]) -> void:
	var rec: Recorder = Recorder.new()
	var r: DetectionResolver = _make_resolver(rec)
	r.update_floor(FLOOR, true, Vector2i(5, 5), DUR, 0.1)      # ACTIVE
	r.update_floor(FLOOR, false, Vector2i(5, 5), DUR, 0.1)     # SEARCHING
	for _i in 20:
		r.update_floor(FLOOR, false, Vector2i(5, 5), DUR, 0.1) # partway through
	r.update_floor(FLOOR, true, Vector2i(6, 6), DUR, 0.1)      # re-spotted -> ACTIVE
	if not r.alarm.is_active(FLOOR):
		failures.append("research: re-spotting during SEARCHING did not return to ACTIVE")
		return
	if rec.triggered != 2:
		failures.append("research: expected 2 triggers (initial + re-spot), got %d" % rec.triggered)


func _test_camera_jam(failures: Array[String]) -> void:
	var r: DetectionResolver = DetectionResolver.new()
	var fd: FloorData = _camera_floor()
	fd.camera_zones[0].jammed_until_ms = 1000
	if r.camera_sees_cell(fd, Vector2i(5, 5), 500):
		failures.append("jam: jammed camera should not see the player")
	if not r.camera_sees_cell(fd, Vector2i(5, 5), 1500):
		failures.append("jam: camera should see again after jam expires")
	if r.camera_sees_cell(fd, Vector2i(0, 0), 1500):
		failures.append("jam: camera reported a cell outside its zone")


func _test_fov_helper(failures: Array[String]) -> void:
	var r: DetectionResolver = DetectionResolver.new()
	var origin := Vector2i(5, 5)
	var facing := Vector2(1, 0)  # east, 90-degree cone, range 4
	if not r.cell_in_guard_fov(origin, facing, 90.0, 4, Vector2i(7, 5)):
		failures.append("fov: cell directly ahead within range should be seen")
	if r.cell_in_guard_fov(origin, facing, 90.0, 4, Vector2i(1, 5)):
		failures.append("fov: cell behind the guard should not be seen")
	if r.cell_in_guard_fov(origin, facing, 90.0, 4, Vector2i(9, 9)):
		failures.append("fov: cell beyond range should not be seen")
