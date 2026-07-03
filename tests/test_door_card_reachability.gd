class_name TestDoorCardReachability
extends RefCounted

## Phase 3 acceptance for guarantee #3, plus negative tests that PROVE the
## validator actually rejects broken levels (a validator that always passes is
## worthless). Covers: heavy-door generation stays valid; a circular card
## lockout is detected; an elevator-less unreachable floor is detected.

const SEED_COUNT: int = 80


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_heavy_doors_valid(failures)
	_test_detects_circular_lockout(failures)
	_test_detects_unreachable_floor(failures)
	return failures


func _test_heavy_doors_valid(failures: Array[String]) -> void:
	var validator: GenerationValidator = GenerationValidator.new()
	var generator: MapGenerator = MapGenerator.new()
	var total_doors: int = 0
	var total_cards: int = 0
	for s in SEED_COUNT:
		var config: GenerationConfig = GenerationConfig.new()
		config.use_random_seed = false
		config.seed = s
		config.locked_doors_per_floor_range = Vector2i(2, 2)
		config.max_keycard_access_level = 2
		var building: BuildingData = generator.generate(config, config.make_prng())
		var result: Dictionary = validator.check_all(building, config)
		if not result["valid"]:
			failures.append("heavy_doors seed %d invalid: %s" % [s, str(result["errors"])])
			if failures.size() >= 5:
				return
		for fd: FloorData in building.floors:
			total_doors += fd.doors.size()
			total_cards += fd.keycards.size()
	# Guard against a vacuous pass: the run must actually exercise doors/cards.
	if total_doors == 0:
		failures.append("heavy_doors: no doors generated across %d seeds" % SEED_COUNT)
	if total_cards == 0:
		failures.append("heavy_doors: no keycards generated across %d seeds" % SEED_COUNT)


## Circular lockout: a keycard sits behind the very door it would open, on a
## single corridor floor. The validator must flag card_access.
func _test_detects_circular_lockout(failures: Array[String]) -> void:
	var building: BuildingData = BuildingData.new()
	# 6x3 grid; carve a single walkable corridor row (x=1..4, y=1).
	var fd: FloorData = FloorData.new(0, 6, 3)
	for y in fd.height:
		for x in fd.width:
			fd.set_walkable(Vector2i(x, y), false)
	for x in range(1, 5):
		fd.set_walkable(Vector2i(x, 1), true)
	fd.hole_position = Vector2i(4, 1)
	fd.doors.append(DoorData.new(Vector2i(2, 1), 1))          # locked door mid-corridor
	fd.keycards.append(KeycardData.new(Vector2i(3, 1), 1, 0))  # its key is BEHIND it
	building.floors.append(fd)
	building.player_start_floor = 0
	building.player_start_cell = Vector2i(1, 1)

	var config: GenerationConfig = GenerationConfig.new()
	config.floor_count = 1
	var result: Dictionary = GenerationValidator.new().check_all(building, config)
	if result["valid"]:
		failures.append("negative: circular card lockout was NOT detected")
	elif not _has_error_prefix(result["errors"], "card_access"):
		failures.append("negative: lockout detected but wrong error: %s" % str(result["errors"]))


## Unreachable floor: two floors, no elevator between them. The player can never
## reach floor 1 even though the ball drops there. Validator must flag player_path.
func _test_detects_unreachable_floor(failures: Array[String]) -> void:
	var building: BuildingData = BuildingData.new()
	for f in 2:
		var fd: FloorData = FloorData.new(f, 4, 3)
		fd.hole_position = Vector2i(1, 1)
		building.floors.append(fd)
	building.player_start_floor = 0
	building.player_start_cell = Vector2i(1, 1)
	# Deliberately no elevator_network entries.

	var config: GenerationConfig = GenerationConfig.new()
	config.floor_count = 2
	var result: Dictionary = GenerationValidator.new().check_all(building, config)
	if result["valid"]:
		failures.append("negative: unreachable floor was NOT detected")
	elif not _has_error_prefix(result["errors"], "player_path"):
		failures.append("negative: unreachable detected but wrong error: %s" % str(result["errors"]))


func _has_error_prefix(errors: Array, prefix: String) -> bool:
	for e: String in errors:
		if e.begins_with(prefix):
			return true
	return false
