class_name MapRawData extends Node

@export var showRadiusOnly: bool
@export var config: GeneratorConfiguration

const TILE_BLOCKED = 0x00
const TILE_NAVIGABLE = 0x01
const TILE_EMPTY = 0x02
const TILE_PATH = TILE_NAVIGABLE
const TILE_EMPTY_WALL = TILE_NAVIGABLE | TILE_EMPTY

var noiseGenerator: PerlinNoise

signal mapGenerated

func _ready() -> void:
	var startTime = Time.get_ticks_usec()
	self.noiseGenerator = PerlinNoise.new(config)
	generateMap()
	print_debug("all time (in usec): ", (Time.get_ticks_usec() - startTime))

func generateMap() -> void:
	var rawGrid: Array[int]
	var position: Vector2

	var index:int = 0;
	var r2:float = config.radius * config.radius
	var center: = Vector2(config.mapSize.x - 1, config.mapSize.y - 1)
	center *= .5

	rawGrid.resize(config.mapSize.x * config.mapSize.y);

	for y in config.mapSize.y:
		position.y = y
		for x in config.mapSize.x:
			position.x = x

			var d:float = (position - center).length_squared()
			var value:float = 1 - clamp(d / r2, 0.0, 1.0)
			if !showRadiusOnly:
				value *= self.noiseGenerator.get2DPlot(x ,y)
			rawGrid[index] = getTileIdFromValue(value)
			index += 1

	var startFixTime = Time.get_ticks_usec()
	#var correctedMap = HexMapHealer.healMap(rawGrid, config.mapSize)
	print_debug("fix time (in usec): ", (Time.get_ticks_usec() - startFixTime))
	mapGenerated.emit(rawGrid)

func getTileIdFromValue(value: float) -> int:
	if (value < .35):
		return TILE_BLOCKED
	elif (value < .48):
		return TILE_NAVIGABLE
	return TILE_EMPTY_WALL
