class_name MapGenerator
extends RefCounted

## Produces a fully populated BuildingData from a GenerationConfig + PrngService,
## honouring the five completability guarantees in GDD §6.3. All randomness is
## drawn from named sub-streams of the supplied PRNG so subsystems stay
## deterministic and independent.
##
## Generation strategy (documented so the invariants are auditable):
##  * Ball path: every floor gets exactly one hole leading straight down one
##    floor, so the chain of holes alone connects the top floor to the final
##    hole — conduits are extra downward shortcuts on top of that.
##  * Player path: elevator shafts are laid out as an OVERLAPPING chain
##    (shaft k and shaft k+1 share one floor), which guarantees the floor
##    connectivity graph is a single connected component reachable from floor 0
##    while keeping each floor within 1–2 elevators.
##  * Doors/cards: locked doors gate small enclosed corner "vaults"; each door's
##    required keycard is placed in the open (never behind an equal/higher
##    door), so no locked door can ever block the route to its own key.
##    Vault carving is reverted if it would disconnect a floor's open region.
##
## ASSUMPTION (v1): the final floor has no outgoing conduits (they must go
## strictly down, which is impossible from the bottom), and vault interiors are
## left empty — doors are demonstrated/validated but hold no reward yet.

const INVALID_CELL: Vector2i = Vector2i(-1, -1)
const _NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func generate(config: GenerationConfig, prng: PrngService) -> BuildingData:
	var building: BuildingData = BuildingData.new()
	building.seed_used = prng.get_seed()

	var floor_count: int = maxi(1, config.floor_count)
	var w: int = config.floor_width()
	var h: int = config.floor_height()

	# 1. Allocate blank floors with optional border walls.
	for f in floor_count:
		var fd: FloorData = FloorData.new(f, w, h)
		if config.add_wall_border:
			_apply_border(fd)
		building.floors.append(fd)

	# Per-floor reservation sets keep structural cells from colliding.
	var reserved: Array[Dictionary] = []
	for f in floor_count:
		reserved.append({})

	# 2. Elevators first (structural), so holes/conduits can avoid their cells.
	_generate_elevators(building, config, prng.get_stream("elevators"), reserved)

	# 3. Player start on the top floor.
	var start_stream: PrngService = prng.get_stream("player_start")
	var start_cell: Vector2i = _pick_free_cell(building.floors[0], reserved[0], start_stream)
	if start_cell == INVALID_CELL:
		start_cell = Vector2i(1, 1)
	building.player_start_floor = 0
	building.player_start_cell = start_cell
	_reserve(reserved[0], start_cell)

	# Ball begins on the top floor at its own free cell.
	var ball_cell: Vector2i = _pick_free_cell(building.floors[0], reserved[0], start_stream)
	if ball_cell == INVALID_CELL:
		ball_cell = Vector2i(building.floors[0].width - 2, building.floors[0].height - 2)
	building.ball_start_floor = 0
	building.ball_start_cell = ball_cell
	_reserve(reserved[0], ball_cell)

	# 4. Exactly one hole per floor (drops straight to the floor below).
	var hole_stream: PrngService = prng.get_stream("holes")
	for f in floor_count:
		var cell: Vector2i = _pick_free_cell(building.floors[f], reserved[f], hole_stream)
		if cell == INVALID_CELL:
			cell = building.player_start_cell if f == 0 else Vector2i(1, 1)
		building.floors[f].hole_position = cell
		_reserve(reserved[f], cell)

	# 5. Conduits (downward-only shortcuts) on every non-final floor.
	_generate_conduits(building, config, prng.get_stream("conduits"), reserved)

	# 6. Doors + gated corner vaults, then the keycards that open them.
	_generate_doors_and_cards(building, config, prng.get_stream("access"), reserved)

	# 7. Stealth: cameras and guard patrols (no bearing on completability).
	_generate_cameras(building, config, prng.get_stream("cameras"), reserved)
	_generate_guards(building, config, prng.get_stream("guards"), reserved)

	return building


# --- floors -----------------------------------------------------------------

func _apply_border(fd: FloorData) -> void:
	for x in fd.width:
		fd.set_walkable(Vector2i(x, 0), false)
		fd.set_walkable(Vector2i(x, fd.height - 1), false)
	for y in fd.height:
		fd.set_walkable(Vector2i(0, y), false)
		fd.set_walkable(Vector2i(fd.width - 1, y), false)


# --- elevators --------------------------------------------------------------

func _generate_elevators(building: BuildingData, config: GenerationConfig, prng: PrngService, reserved: Array[Dictionary]) -> void:
	var n: int = building.floor_count()
	if n < 2:
		return

	# Overlapping chain of contiguous floor runs guarantees full connectivity.
	var runs: Array = []
	var span_min: int = 2
	var span_max: int = 3
	var start: int = 0
	while start < n - 1:
		var remaining: int = (n - 1) - start
		var span: int = prng.randi_range(span_min, span_max)
		span = mini(span, remaining + 1)
		var end: int = start + span - 1
		runs.append(range(start, end + 1))
		if end >= n - 1:
			break
		start = end  # overlap by one floor -> connectivity

	var used_coords: Dictionary = {}
	for run in runs:
		var serviced: Array[int] = []
		for f: int in run:
			serviced.append(f)
		var coord: Vector2i = _pick_elevator_coord(building, serviced, used_coords, prng)
		if coord == INVALID_CELL:
			continue
		used_coords[coord] = true
		var link: ElevatorLink = ElevatorLink.new(coord, serviced)
		building.elevator_network[coord] = link
		for f: int in serviced:
			building.floors[f].elevator_positions.append(coord)
			_reserve(reserved[f], coord)


## Picks an interior cell that is walkable on every serviced floor and unused by
## another shaft.
func _pick_elevator_coord(building: BuildingData, serviced: Array[int], used: Dictionary, prng: PrngService) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var fd0: FloorData = building.floors[serviced[0]]
	for y in range(1, fd0.height - 1):
		for x in range(1, fd0.width - 1):
			var c: Vector2i = Vector2i(x, y)
			if used.has(c):
				continue
			var ok: bool = true
			for f: int in serviced:
				if not building.floors[f].is_walkable(c):
					ok = false
					break
			if ok:
				candidates.append(c)
	if candidates.is_empty():
		return INVALID_CELL
	return candidates[prng.pick_index(candidates.size())]


# --- conduits ---------------------------------------------------------------

func _generate_conduits(building: BuildingData, config: GenerationConfig, prng: PrngService, reserved: Array[Dictionary]) -> void:
	var n: int = building.floor_count()
	var lo: int = maxi(0, config.conduits_per_floor_range.x)
	var hi: int = maxi(lo, config.conduits_per_floor_range.y)
	for f in range(0, n - 1):
		var count: int = prng.randi_range(lo, hi)
		var max_reach: int = mini(config.max_conduit_drop_distance, (n - 1) - f)
		for _i in count:
			if max_reach < 1:
				break
			var drop: int = prng.randi_range(1, max_reach)
			var dest_floor: int = f + drop
			var origin_cell: Vector2i = _pick_free_cell(building.floors[f], reserved[f], prng)
			var dest_cell: Vector2i = _pick_free_cell(building.floors[dest_floor], reserved[dest_floor], prng)
			if origin_cell == INVALID_CELL or dest_cell == INVALID_CELL:
				continue
			_reserve(reserved[f], origin_cell)
			_reserve(reserved[dest_floor], dest_cell)
			var conduit: ConduitLink = ConduitLink.new(f, origin_cell, dest_floor, dest_cell)
			building.floors[f].conduits.append(conduit)


# --- doors & keycards -------------------------------------------------------

func _generate_doors_and_cards(building: BuildingData, config: GenerationConfig, prng: PrngService, reserved: Array[Dictionary]) -> void:
	var lo: int = maxi(0, config.locked_doors_per_floor_range.x)
	var hi: int = maxi(lo, config.locked_doors_per_floor_range.y)
	var max_level: int = maxi(1, config.max_keycard_access_level)

	for f in building.floor_count():
		var fd: FloorData = building.floors[f]
		var count: int = prng.randi_range(lo, hi)
		for _i in count:
			var level: int = prng.randi_range(1, max_level)
			var door_cell: Vector2i = _try_carve_vault(fd, reserved[f], prng)
			if door_cell == INVALID_CELL:
				continue
			var door: DoorData = DoorData.new(door_cell, level)
			fd.doors.append(door)
			# Place the matching keycard in the OPEN region so the door can never
			# block the route to its own key (guarantee #3). Prefer the same
			# floor; fall back to the top floor if this one is full.
			if not _place_keycard(building, f, level, reserved, prng):
				_place_keycard(building, 0, level, reserved, prng)


## Attempts to carve an enclosed 1-cell vault into a floor corner, returning the
## door cell that gates it (or INVALID_CELL if none could be carved safely).
## Reverts any wall it added if doing so would disconnect the floor.
func _try_carve_vault(fd: FloorData, reserved_floor: Dictionary, prng: PrngService) -> Vector2i:
	var w: int = fd.width
	var h: int = fd.height
	# Interior corner cells (assuming a one-cell border) and, for each, the two
	# interior neighbours that must become {wall, door}.
	var corners: Array = [
		{"inner": Vector2i(1, 1), "a": Vector2i(2, 1), "b": Vector2i(1, 2)},
		{"inner": Vector2i(w - 2, 1), "a": Vector2i(w - 3, 1), "b": Vector2i(w - 2, 2)},
		{"inner": Vector2i(1, h - 2), "a": Vector2i(2, h - 2), "b": Vector2i(1, h - 3)},
		{"inner": Vector2i(w - 2, h - 2), "a": Vector2i(w - 3, h - 2), "b": Vector2i(w - 2, h - 3)},
	]
	_shuffle_array(corners, prng)

	for corner in corners:
		var inner: Vector2i = corner["inner"]
		var na: Vector2i = corner["a"]
		var nb: Vector2i = corner["b"]
		if not (_carveable(fd, reserved_floor, inner) and _carveable(fd, reserved_floor, na) and _carveable(fd, reserved_floor, nb)):
			continue
		# Randomly decide which neighbour is the wall vs. the door.
		var wall_cell: Vector2i = na
		var door_cell: Vector2i = nb
		if prng.chance(0.5):
			wall_cell = nb
			door_cell = na
		# Tentatively wall it and confirm the floor stays connected.
		fd.set_walkable(wall_cell, false)
		if _floor_open_connected(fd):
			_reserve(reserved_floor, inner)
			_reserve(reserved_floor, door_cell)
			_reserve(reserved_floor, wall_cell)
			return door_cell
		# Revert and try another corner.
		fd.set_walkable(wall_cell, true)
	return INVALID_CELL


func _carveable(fd: FloorData, reserved_floor: Dictionary, cell: Vector2i) -> bool:
	return fd.is_walkable(cell) and not reserved_floor.has(cell)


func _place_keycard(building: BuildingData, floor_index: int, level: int, reserved: Array[Dictionary], prng: PrngService) -> bool:
	var fd: FloorData = building.floors[floor_index]
	var cell: Vector2i = _pick_free_cell(fd, reserved[floor_index], prng)
	if cell == INVALID_CELL:
		return false
	_reserve(reserved[floor_index], cell)
	fd.keycards.append(KeycardData.new(cell, level, floor_index))
	return true


# --- cameras ----------------------------------------------------------------

func _generate_cameras(building: BuildingData, config: GenerationConfig, prng: PrngService, reserved: Array[Dictionary]) -> void:
	var lo: int = maxi(0, config.cameras_per_floor_range.x)
	var hi: int = maxi(lo, config.cameras_per_floor_range.y)
	for f in building.floor_count():
		var fd: FloorData = building.floors[f]
		var base: int = prng.randi_range(lo, hi)
		var count: int = maxi(0, roundi(base * config.camera_density_at(f)))
		for _i in count:
			var cell: Vector2i = _pick_free_cell(fd, reserved[f], prng)
			if cell == INVALID_CELL:
				break
			_reserve(reserved[f], cell)
			var zone: CameraZoneData = CameraZoneData.new(cell, _make_cone(fd, cell, config.camera_fov_range_cells, prng))
			fd.camera_zones.append(zone)


## Builds a simple directional cone of walkable cells in one cardinal direction.
func _make_cone(fd: FloorData, origin: Vector2i, reach: int, prng: PrngService) -> Array[Vector2i]:
	var dir: Vector2i = _NEIGHBORS[prng.pick_index(_NEIGHBORS.size())]
	var perp: Vector2i = Vector2i(-dir.y, dir.x)
	var cells: Array[Vector2i] = []
	for d in range(1, reach + 1):
		var spread: int = int(floor(d / 2.0))
		for s in range(-spread, spread + 1):
			var c: Vector2i = origin + dir * d + perp * s
			if fd.is_walkable(c):
				cells.append(c)
	return cells


# --- guards -----------------------------------------------------------------

func _generate_guards(building: BuildingData, config: GenerationConfig, prng: PrngService, reserved: Array[Dictionary]) -> void:
	var lo: int = maxi(0, config.guards_per_floor_range.x)
	var hi: int = maxi(lo, config.guards_per_floor_range.y)
	for f in building.floor_count():
		var fd: FloorData = building.floors[f]
		var base: int = prng.randi_range(lo, hi)
		var count: int = maxi(0, roundi(base * config.guard_density_at(f)))
		for _i in count:
			var path: Array[Vector2i] = _make_patrol_path(fd, reserved[f], prng)
			if path.is_empty():
				break
			var guard: GuardPatrolData = GuardPatrolData.new(f, path, config.guard_fov_angle_degrees, config.guard_fov_range_cells)
			fd.guard_patrols.append(guard)


## Builds a short patrol loop of walkable waypoints near a random start cell.
func _make_patrol_path(fd: FloorData, reserved_floor: Dictionary, prng: PrngService) -> Array[Vector2i]:
	var start: Vector2i = _pick_free_cell(fd, reserved_floor, prng)
	if start == INVALID_CELL:
		return []
	_reserve(reserved_floor, start)
	var path: Array[Vector2i] = [start]
	var waypoint_count: int = prng.randi_range(1, 3)
	var current: Vector2i = start
	for _i in waypoint_count:
		var candidates: Array[Vector2i] = []
		for step in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
			var c: Vector2i = current + step
			if fd.is_walkable(c) and not path.has(c):
				candidates.append(c)
		if candidates.is_empty():
			break
		current = candidates[prng.pick_index(candidates.size())]
		path.append(current)
	return path


# --- shared helpers ---------------------------------------------------------

func _reserve(reserved_floor: Dictionary, cell: Vector2i) -> void:
	reserved_floor[cell] = true


## Picks a random interior walkable cell not already reserved (INVALID if none).
func _pick_free_cell(fd: FloorData, reserved_floor: Dictionary, prng: PrngService) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in range(1, fd.height - 1):
		for x in range(1, fd.width - 1):
			var c: Vector2i = Vector2i(x, y)
			if fd.is_walkable(c) and not reserved_floor.has(c):
				candidates.append(c)
	if candidates.is_empty():
		return INVALID_CELL
	return candidates[prng.pick_index(candidates.size())]


## True if the floor's entire walkable region is a single connected component
## (doors treated as passable). Used to protect connectivity during carving.
func _floor_open_connected(fd: FloorData) -> bool:
	var start: Vector2i = INVALID_CELL
	var total: int = 0
	for y in fd.height:
		for x in fd.width:
			var c: Vector2i = Vector2i(x, y)
			if fd.is_walkable(c):
				total += 1
				if start == INVALID_CELL:
					start = c
	if total == 0:
		return true
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_back()
		for step in _NEIGHBORS:
			var nc: Vector2i = cur + step
			if fd.is_walkable(nc) and not seen.has(nc):
				seen[nc] = true
				queue.append(nc)
	return seen.size() == total


func _shuffle_array(array: Array, prng: PrngService) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = prng.randi_range(0, i)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp
