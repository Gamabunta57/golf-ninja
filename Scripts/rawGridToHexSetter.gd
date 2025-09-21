class_name RawGridToHexSetter extends Node

@export var tileMap: TileMapLayer
@export var config: GeneratorConfiguration

var mapOffset = 0

func updateTileMap(grid: Array[int]) -> void:
	var width = config.mapSize.x
	var height = config.mapSize.y
	var xOffest = mapOffset * config.mapSize.x
	for y:int in height:
		for x: int in width:
			var cellValue = grid[coordToIndex(x, y)]
			tileMap.set_cell(Vector2i(x + xOffest, y), 1, Vector2i(cellValue, 0))
	
func coordToIndex(x: int, y: int) -> int:
	return y * config.mapSize.x + x

func _on_map_raw_data_map_generated(grid: Array[int]) -> void:
	updateTileMap(grid)

	if (mapOffset == 0):
		mapOffset += 1
