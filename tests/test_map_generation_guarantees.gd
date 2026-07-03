class_name TestMapGenerationGuarantees
extends RefCounted

## Phase 3 acceptance (the most important automated test in the project):
## generate across many seeds and assert GenerationValidator passes every time,
## plus structural sanity (one hole per floor, elevator counts, determinism).

const SEED_COUNT: int = 120


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_all_seeds_valid(failures)
	_test_structural_sanity(failures)
	_test_generation_deterministic(failures)
	return failures


func _default_config(seed_value: int) -> GenerationConfig:
	var config: GenerationConfig = GenerationConfig.new()
	config.use_random_seed = false
	config.seed = seed_value
	return config


func _test_all_seeds_valid(failures: Array[String]) -> void:
	var validator: GenerationValidator = GenerationValidator.new()
	var generator: MapGenerator = MapGenerator.new()
	for s in SEED_COUNT:
		var config: GenerationConfig = _default_config(s)
		var building: BuildingData = generator.generate(config, config.make_prng())
		var result: Dictionary = validator.check_all(building, config)
		if not result["valid"]:
			failures.append("seed %d invalid: %s" % [s, str(result["errors"])])
			if failures.size() >= 5:
				return


func _test_structural_sanity(failures: Array[String]) -> void:
	var generator: MapGenerator = MapGenerator.new()
	for s in range(0, 40):
		var config: GenerationConfig = _default_config(s)
		var building: BuildingData = generator.generate(config, config.make_prng())
		if building.floor_count() != config.floor_count:
			failures.append("seed %d: floor_count %d != %d" % [s, building.floor_count(), config.floor_count])
			return
		for fd: FloorData in building.floors:
			# Exactly one hole per floor (its position must be a valid cell).
			if not fd.in_bounds(fd.hole_position):
				failures.append("seed %d floor %d: hole out of bounds" % [s, fd.floor_index])
				return
			# Elevator count per floor within the configured [1,2] default.
			var elev: int = fd.elevator_positions.size()
			if elev < 1 or elev > 2:
				failures.append("seed %d floor %d: %d elevators (expected 1-2)" % [s, fd.floor_index, elev])
				return
			# Conduits only leave non-final floors and go strictly downward.
			for conduit: ConduitLink in fd.conduits:
				if conduit.destination_floor <= conduit.origin_floor:
					failures.append("seed %d floor %d: non-downward conduit" % [s, fd.floor_index])
					return


func _test_generation_deterministic(failures: Array[String]) -> void:
	var generator: MapGenerator = MapGenerator.new()
	for s in [3, 17, 99]:
		var c1: GenerationConfig = _default_config(s)
		var c2: GenerationConfig = _default_config(s)
		var b1: BuildingData = generator.generate(c1, c1.make_prng())
		var b2: BuildingData = generator.generate(c2, c2.make_prng())
		if _signature(b1) != _signature(b2):
			failures.append("seed %d: two generations differ (non-deterministic)" % s)
			return


## Compact structural signature for determinism comparison.
func _signature(b: BuildingData) -> String:
	var parts: Array[String] = ["start:%s@%d" % [b.player_start_cell, b.player_start_floor]]
	for fd: FloorData in b.floors:
		parts.append("F%d h%s e%s" % [fd.floor_index, fd.hole_position, str(fd.elevator_positions)])
		for c: ConduitLink in fd.conduits:
			parts.append("c%s->%d%s" % [c.origin_position, c.destination_floor, c.destination_position])
		for d: DoorData in fd.doors:
			parts.append("d%s:%d" % [d.position, d.required_access_level])
		for k: KeycardData in fd.keycards:
			parts.append("k%s:%d" % [k.position, k.access_level])
	return "|".join(parts)
