class_name RawGridToHexSetter extends Node

@export var tileMap: TileMapLayer
@export var config: GeneratorConfiguration
@export var atlasId: int = 1

func updateTileMap(grid: Array[int]) -> void:
	var width = config.mapSize.x
	var height = config.mapSize.y
	var position: Vector2i
	for y:int in height:
		position.y = y
		for x: int in width:
			position.x = x
			var tileRotation = 0
			var tileId = grid[coordToIndex(x, y)]
			if tileId == 5 || tileId == 7 || tileId == 9 || tileId == 8:
				tileId = 3
			elif tileId == 6 || tileId == 10:
				tileId = 3
				tileRotation = TileSetAtlasSource.TRANSFORM_FLIP_V
			elif tileId > 0:
				tileId -= 1
			tileMap.set_cell(position, atlasId, Vector2i(tileId, 0), tileRotation)
			tileMap.is_cell_flipped_v
	
func coordToIndex(x: int, y: int) -> int:
	return y * config.mapSize.x + x

func _on_map_raw_data_map_generated(grid: Array[int]) -> void:
	updateTileMap(grid)
