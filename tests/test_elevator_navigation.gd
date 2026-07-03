class_name TestElevatorNavigation
extends RefCounted

## Phase 5: verifies ElevatorSystem exposes valid transitions and that the
## player can, using only elevators, reach every floor from the start — the
## runtime counterpart to the generator's player-path guarantee.

const SEED_COUNT: int = 60


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_reaches_all_floors(failures)
	_test_next_destination_valid(failures)
	return failures


func _test_reaches_all_floors(failures: Array[String]) -> void:
	var elevators: ElevatorSystem = ElevatorSystem.new()
	var generator: MapGenerator = MapGenerator.new()
	for s in SEED_COUNT:
		var config: GenerationConfig = GenerationConfig.new()
		config.use_random_seed = false
		config.seed = s
		var building: BuildingData = generator.generate(config, config.make_prng())

		# BFS over floors using only ElevatorSystem.destinations().
		var reached: Dictionary = {building.player_start_floor: true}
		var queue: Array[int] = [building.player_start_floor]
		while not queue.is_empty():
			var f: int = queue.pop_back()
			for link: ElevatorLink in building.elevators_on_floor(f):
				for dest: int in elevators.destinations(building, f, link.grid_position):
					if not reached.has(dest):
						reached[dest] = true
						queue.append(dest)
		if reached.size() != building.floor_count():
			failures.append("seed %d: reached %d/%d floors via elevators" % [s, reached.size(), building.floor_count()])
			if failures.size() >= 5:
				return


func _test_next_destination_valid(failures: Array[String]) -> void:
	var elevators: ElevatorSystem = ElevatorSystem.new()
	var generator: MapGenerator = MapGenerator.new()
	var config: GenerationConfig = GenerationConfig.new()
	config.seed = 7
	var building: BuildingData = generator.generate(config, config.make_prng())
	for f in building.floor_count():
		for link: ElevatorLink in building.elevators_on_floor(f):
			var dest: int = elevators.next_destination(building, f, link.grid_position)
			if dest == f:
				failures.append("floor %d: next_destination returned current floor" % f)
				return
			if not link.services_floor(dest):
				failures.append("floor %d: next_destination %d not serviced by elevator" % [f, dest])
				return
			# A non-elevator cell must offer nothing.
			if elevators.can_use(building, f, Vector2i(0, 0)):
				failures.append("floor %d: reported elevator at a wall cell" % f)
				return
