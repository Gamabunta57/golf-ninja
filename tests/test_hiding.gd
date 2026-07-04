class_name TestHiding
extends RefCounted

## Phase 9: concealment is only allowed when the player is currently unobserved
## (hiding must precede detection). Jammed cameras don't block hiding; a guard
## looking at the locker does. Also checks the generator actually places lockers
## on walkable cells.

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_camera_blocks(failures)
	_test_guard_fov_blocks(failures)
	_test_generated_lockers(failures)
	return failures


func _floor_with_camera() -> FloorData:
	var fd: FloorData = FloorData.new(0, 10, 10)
	fd.camera_zones.append(CameraZoneData.new(Vector2i(4, 5), [Vector2i(5, 5)] as Array[Vector2i]))
	fd.locker_positions.append(Vector2i(5, 5))
	fd.locker_positions.append(Vector2i(2, 2))
	return fd


func _test_camera_blocks(failures: Array[String]) -> void:
	var h: HidingSystem = HidingSystem.new()
	var d: DetectionResolver = DetectionResolver.new()
	var fd: FloorData = _floor_with_camera()

	# Inside the camera zone -> cannot hide.
	if h.can_conceal(d, fd, Vector2i(5, 5), 0, []):
		failures.append("camera: should not conceal inside an active camera zone")
	# Elsewhere -> can hide.
	if not h.can_conceal(d, fd, Vector2i(2, 2), 0, []):
		failures.append("camera: should conceal outside all camera zones")
	# Jammed camera -> hiding allowed even inside the zone.
	fd.camera_zones[0].jammed_until_ms = 5000
	if not h.can_conceal(d, fd, Vector2i(5, 5), 1000, []):
		failures.append("camera: jammed camera should not block hiding")
	# has_locker sanity.
	if not h.has_locker(fd, Vector2i(5, 5)) or h.has_locker(fd, Vector2i(9, 9)):
		failures.append("camera: has_locker mismatch")


func _test_guard_fov_blocks(failures: Array[String]) -> void:
	var h: HidingSystem = HidingSystem.new()
	var d: DetectionResolver = DetectionResolver.new()
	var fd: FloorData = FloorData.new(0, 10, 10)
	fd.locker_positions.append(Vector2i(6, 5))

	# Guard at (5,5) facing east sees (6,5) -> cannot hide there.
	var looking: Array = [{"origin": Vector2i(5, 5), "facing": Vector2(1, 0), "angle": 90.0, "range": 4}]
	if h.can_conceal(d, fd, Vector2i(6, 5), 0, looking):
		failures.append("guard: should not conceal inside a guard FOV")
	# Guard facing away (west) -> can hide.
	var away: Array = [{"origin": Vector2i(5, 5), "facing": Vector2(-1, 0), "angle": 90.0, "range": 4}]
	if not h.can_conceal(d, fd, Vector2i(6, 5), 0, away):
		failures.append("guard: should conceal when outside the guard FOV")


func _test_generated_lockers(failures: Array[String]) -> void:
	var generator: MapGenerator = MapGenerator.new()
	var found_any: bool = false
	for s in 20:
		var config: GenerationConfig = GenerationConfig.new()
		config.seed = s
		var building: BuildingData = generator.generate(config, config.make_prng())
		for fd: FloorData in building.floors:
			for cell: Vector2i in fd.locker_positions:
				found_any = true
				if not fd.is_walkable(cell):
					failures.append("seed %d floor %d: locker on non-walkable cell %s" % [s, fd.floor_index, cell])
					return
	if not found_any:
		failures.append("lockers: generator produced no lockers across 20 seeds")
