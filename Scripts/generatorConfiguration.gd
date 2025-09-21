class_name GeneratorConfiguration extends Node

@export var mapSeed: int = -1
@export var useRandomSeed: bool = false
@export var mapSize: Vector2i = Vector2i.ONE * 32
@export var radius: float = 18.0

var isSeedInit = false

func getSeed() -> int:
	if useRandomSeed && !isSeedInit:
		mapSeed = randi()
		isSeedInit = true
	print_debug("Seed: ", mapSeed)
	return mapSeed
