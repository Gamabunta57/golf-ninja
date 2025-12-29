class_name ForegroundGridSetter extends Node

@export var tileMap: TileMapLayer
@export var config: GeneratorConfiguration
@export var atlasId: int = 0

@export var slashCell: int = 0
@export var groundCell: int = 1
@export var backslashCell: int = 2
@export var navigationCell: int = 3

@export var tilemapCoef = Vector2i(3, 4)
@export var tilemapOffset = Vector2i(0, 1)
@export var hexOffset = Vector2i(1, 1)

const TOP_RIGHT_CONNECTED = HexMapHealer.TILE_IS_CONNECTED_TOP_RIGHT
const BOTTOM_RIGHT_CONNECTED = HexMapHealer.TILE_IS_CONNECTED_BOTTOM_RIGHT
const BOTTOM_CONNECTED = HexMapHealer.TILE_IS_CONNECTED_BOTTOM

func updateTileMap(map: Array[int]) -> void:
	var width = config.mapSize.x
	var height = config.mapSize.y
	var position: Vector2i
	for y:int in height:
		position.y = y
		for x: int in width:
			position.x = x
			var cellValue = map[backgroundCoordToMapIndex(x, y)]
			var isEmptyCell = cellValue == 0
			if isEmptyCell:
				continue;

			var allInnerCells = getAllInnerCellFromBackgroundCoord(x, y)
			var leftSurroundingBackgroundCellValues = getLeftSurroundingCellValues(map, x, y)

			var topLeftCellValue = leftSurroundingBackgroundCellValues[0]
			var bottomLeftCellValue = leftSurroundingBackgroundCellValues[1]
			var bottomCellValue = leftSurroundingBackgroundCellValues[2]
			var bottomRightCellValue = leftSurroundingBackgroundCellValues[3]
			var topRightCellValue = leftSurroundingBackgroundCellValues[4]
			var topCellValue = leftSurroundingBackgroundCellValues[5]

			var centerCoord = backgroundCoordToForegroundCoord(x, y)

			if (cellValue == 3):
				tileMap.set_cell(allInnerCells[0], atlasId, Vector2i(navigationCell, 0))
				tileMap.set_cell(allInnerCells[1], atlasId, Vector2i(navigationCell, 0))
				tileMap.set_cell(allInnerCells[2], atlasId, Vector2i(navigationCell, 0))
				tileMap.set_cell(allInnerCells[3], atlasId, Vector2i(navigationCell, 0))
				tileMap.set_cell(allInnerCells[4], atlasId, Vector2i(navigationCell, 0))
				tileMap.set_cell(allInnerCells[5], atlasId, Vector2i(navigationCell, 0))
				tileMap.set_cell(allInnerCells[6], atlasId, Vector2i(navigationCell, 0))

				var coord = centerCoord + Vector2i(-1, -1)
				if topLeftCellValue == 0:
					tileMap.set_cell(coord, atlasId, Vector2i(slashCell, 0))
				elif topLeftCellValue == 3:
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))

				coord = centerCoord + Vector2i(-1, 1)
				if bottomLeftCellValue == 0:
					tileMap.set_cell(coord, atlasId, Vector2i(backslashCell, 0))
				elif bottomLeftCellValue == 3:
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))

				coord = centerCoord + Vector2i(0, 2)
				if bottomCellValue == 0:
					tileMap.set_cell(coord, atlasId, Vector2i(groundCell, 0))
				elif bottomCellValue == 3:
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))

				coord = centerCoord + Vector2i(2, 1)
				if bottomRightCellValue == 0:
					tileMap.set_cell(coord, atlasId, Vector2i(slashCell, 0))
				elif bottomRightCellValue == 3:
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))

				coord = centerCoord + Vector2i(2, -1)
				if topRightCellValue == 0:
					tileMap.set_cell(coord, atlasId, Vector2i(backslashCell, 0))
				elif topRightCellValue == 3:
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))

				coord = centerCoord + Vector2i(0, -2)
				if topCellValue == 0:
					tileMap.set_cell(coord, atlasId, Vector2i(groundCell, 0))
				elif topCellValue == 3:
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))

				if topLeftCellValue == 3 && bottomLeftCellValue == 3:
					coord = centerCoord + Vector2i(-2, 0)
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))
		
				if bottomLeftCellValue == 3 && bottomCellValue == 3:
					coord = centerCoord + Vector2i(-1, 2)
					tileMap.set_cell(coord, atlasId, Vector2i(navigationCell, 0))
				continue


			#tileMap.set_cell(allInnerCells[0], atlasId, Vector2i(groundCell, 0))
			#tileMap.set_cell(allInnerCells[1], atlasId, Vector2i(backslashCell, 0))
			#tileMap.set_cell(allInnerCells[2], atlasId, Vector2i(groundCell, 0))
			#tileMap.set_cell(allInnerCells[3], atlasId, Vector2i(slashCell, 0))
			#tileMap.set_cell(allInnerCells[4], atlasId, Vector2i(backslashCell, 0))
			#tileMap.set_cell(allInnerCells[5], atlasId, Vector2i(groundCell, 0))
			#tileMap.set_cell(allInnerCells[6], atlasId, Vector2i(slashCell, 0))

			#tileMap.set_cell(allInnerCells[8], atlasId, Vector2i(groundCell, 1))
			#tileMap.set_cell(allInnerCells[10], atlasId, Vector2i(groundCell, 0))
			#tileMap.set_cell(allInnerCells[12], atlasId, Vector2i(groundCell, 0))

			if topLeftCellValue & 0x0f != 2:
				var coord = centerCoord + Vector2i(-1, -1)
				tileMap.set_cell(coord, atlasId, Vector2i(slashCell, 0))

			if bottomLeftCellValue & 0x0f != 2:
				var coord = centerCoord + Vector2i(-1, 1)
				tileMap.set_cell(coord, atlasId, Vector2i(backslashCell, 0))

			if bottomCellValue & 0x0f != 2:
				var coord = centerCoord + Vector2i(0, 2)
				tileMap.set_cell(coord, atlasId, Vector2i(groundCell, 0))

			if cellValue & TOP_RIGHT_CONNECTED == TOP_RIGHT_CONNECTED:
				tileMap.set_cell(allInnerCells[9], atlasId, Vector2i(navigationCell, 0))
			else:
				tileMap.set_cell(allInnerCells[9], atlasId, Vector2i(backslashCell, 0))
			

			if cellValue & BOTTOM_RIGHT_CONNECTED == BOTTOM_RIGHT_CONNECTED:
				tileMap.set_cell(allInnerCells[11], atlasId, Vector2i(navigationCell, 0))
			else:
				tileMap.set_cell(allInnerCells[11], atlasId, Vector2i(slashCell, 0))

			if cellValue & BOTTOM_CONNECTED == BOTTOM_CONNECTED:
				tileMap.set_cell(allInnerCells[13], atlasId, Vector2i(navigationCell, 0))
			else:
				tileMap.set_cell(allInnerCells[7], atlasId, Vector2i(groundCell, 0))



func backgroundCoordToMapIndex(x: int, y: int) -> int:
	return y * config.mapSize.x + x

func backgroundCoordToForegroundCoord(x, y) -> Vector2i:
	var vOffset = x & 1
	return (Vector2i(x, y) * tilemapCoef) + tilemapOffset + (hexOffset * vOffset)

func getLeftSurroundingCellValues(map: Array[int], x: int, y: int) -> Array[int]:
	var cellValues: Array[int]
	cellValues.resize(6)

	var yOffset = HexMapHealer.getYHexOffset(x & 1 == 0, HexMapHealer.HexDirection.TOP_LEFT)
	var currentPoint = Vector2i(x, y)

	var topLeftCoord = currentPoint + HexMapHealer.hexDirVector[HexMapHealer.HexDirection.TOP_LEFT] + yOffset
	if (topLeftCoord.x > -1 && topLeftCoord.y > -1):
		cellValues[0] = map[backgroundCoordToMapIndex(topLeftCoord.x ,topLeftCoord.y)]
	else:
		cellValues[0] = 0
	
	var bottomLeftCoord = currentPoint + HexMapHealer.hexDirVector[HexMapHealer.HexDirection.BOTTOM_LEFT] + yOffset
	if (bottomLeftCoord.x > -1 && bottomLeftCoord.y < config.mapSize.y):
		cellValues[1] = map[backgroundCoordToMapIndex(bottomLeftCoord.x, bottomLeftCoord.y)]
	else:
		cellValues[1] = 0
	
	var bottomCoord = currentPoint + HexMapHealer.hexDirVector[HexMapHealer.HexDirection.BOTTOM]
	if (bottomCoord.y < config.mapSize.y):
		cellValues[2] = map[backgroundCoordToMapIndex(bottomCoord.x, bottomCoord.y)]
	else:
		cellValues[2] = 0

	var bottomRightCoord = currentPoint + HexMapHealer.hexDirVector[HexMapHealer.HexDirection.BOTTOM_RIGHT] + yOffset
	if (bottomRightCoord.x < config.mapSize.x && bottomRightCoord.y < config.mapSize.y):
		cellValues[3] = map[backgroundCoordToMapIndex(bottomRightCoord.x ,bottomRightCoord.y)]
	else:
		cellValues[3] = 0
	
	var topRightCoord = currentPoint + HexMapHealer.hexDirVector[HexMapHealer.HexDirection.TOP_RIGHT] + yOffset
	if (topRightCoord.y > -1 && topRightCoord.x < config.mapSize.x):
		cellValues[4] = map[backgroundCoordToMapIndex(topRightCoord.x, topRightCoord.y)]
	else:
		cellValues[4] = 0

	var topCoord = currentPoint + HexMapHealer.hexDirVector[HexMapHealer.HexDirection.TOP]
	if (topCoord.y > -1):
		cellValues[5] = map[backgroundCoordToMapIndex(topCoord.x, topCoord.y)]
	else:
		cellValues[5] = 0
	
	return cellValues 

func getAllInnerCellFromBackgroundCoord(x: int, y: int) -> Array[Vector2i]:
	var centerCoord = backgroundCoordToForegroundCoord(x, y)

	var _cellBuffer: Array[Vector2i]
	_cellBuffer.resize(14)

	_cellBuffer[0] = centerCoord # center
	# inner cells
	_cellBuffer[1] = centerCoord + Vector2i(0, -1) # top left
	_cellBuffer[2] = centerCoord + Vector2i(-1, 0) # left
	_cellBuffer[3] = centerCoord + Vector2i(0, 1) # bottom left
	_cellBuffer[4] = centerCoord + Vector2i(1, 1) # bottom right
	_cellBuffer[5] = centerCoord + Vector2i(1, 0) # right
	_cellBuffer[6] = centerCoord + Vector2i(1, -1) # top right

	#half surrounding cells
	_cellBuffer[7] = centerCoord + Vector2i(0, -2) # top (13:00)
	_cellBuffer[8] = centerCoord + Vector2i(1, -2) # top right (1:00)
	_cellBuffer[9] = centerCoord + Vector2i(2, -1) # top right (2:00)
	_cellBuffer[10] = centerCoord + Vector2i(2, 0) # right (3:00)
	_cellBuffer[11] = centerCoord + Vector2i(2, 1) # bottom right (4:00)
	_cellBuffer[12] = centerCoord + Vector2i(1, 2) # bottom right (5:00)
	_cellBuffer[13] = centerCoord + Vector2i(0, 2) # bottom (6:00)

	return _cellBuffer

func digPath(map: Array[int]) -> void:
	var mapData = tileMap.tile_map_data	
	var currentCell = HexMapHealer.findFirstNonEmptyCell(map, config.mapSize.x)
	var centerCoord = backgroundCoordToForegroundCoord(currentCell.x, currentCell.y)

	var _cellBuffer: Array[Vector2i]
	_cellBuffer.resize(7)

	_cellBuffer[0] = centerCoord # center
	# inner cells
	_cellBuffer[1] = centerCoord + Vector2i(0, -1) # top left
	_cellBuffer[2] = centerCoord + Vector2i(-1, 0) # left
	_cellBuffer[3] = centerCoord + Vector2i(0, 1) # bottom left
	_cellBuffer[4] = centerCoord + Vector2i(1, 1) # bottom right
	_cellBuffer[5] = centerCoord + Vector2i(1, 0) # right
	_cellBuffer[6] = centerCoord + Vector2i(1, -1) # top right


	

func _on_map_raw_data_map_generated(map: Array[int]) -> void:
	updateTileMap(map)
	digPath(map)
