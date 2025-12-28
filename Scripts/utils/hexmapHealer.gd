class_name HexMapHealer
#
# Coord reference is based on:
#	/‾\ /‾\
#	\_/‾\_/
#	/ \ / \
#	\_/‾\_/
#	  \_/
#
enum HexDirection {
	TOP, 
	TOP_RIGHT,
	BOTTOM_RIGHT, 
	BOTTOM,
	BOTTOM_LEFT, 
	TOP_LEFT, 
}

"""
List of all relative vectors to find adjacent tile base on [0, 0] tile coords
This array works like a Key/Value Map from int to Vector2i
The indices stored in the array coorespond to the enum values of HexDirection
"""
const hexDirVector: Array[Vector2i] = [
	Vector2i(0, -1), # TOP
	Vector2i(1, 0),  # TOP_RIGHT
	Vector2i(1, 1),  # BOTTOM_RIGHT
	Vector2i(0, 1),  # BOTTOM
	Vector2i(-1, 1), # BOTOTM_LEFT
	Vector2i(-1, 0), # TOP_LEFT
]

"""
List of all "next" Hex direction given an index
Indices of this array match the enum values of HexDirection
This array works like a Key/Value Map from int to int
The indices stored in the array coorespond to the enum values of HexDirection
"""
static var nextHexDirIndex: Array[int] = [
	1, # TOP -> TOP_RIGHT
	2, # TOP_RIGHT -> BOTTOM_RIGHT
	3, # BOTTOM_RIGHT -> BOTTOM
	4, # BOTTOM -> BOTTOM_LEFT 
	5, # BOTTOM_LEFT -> TOP_LEFT
	0, # TOP_LEFT -> TOP
]

"""
List of all "oppposite" Hex direction given an index
Indices of this array match the enum values of HexDirection
This array works like a Key/Value Map from int to int
The indices stored in the array coorespond to the enum values of HexDirection
"""
static var oppositeHexDirIndex: Array[int] = [
	3, # TOP -> BOTTOM
	4, # TOP_RIGHT -> BOTTOM_LEFT
	5, # BOTTOM_RIGHT -> TOP_LEFT
	0, # BOTTOM -> TOP 
	1, # BOTTOM_LEFT -> TOP_RIGHT
	2, # TOP_LEFT -> BOTTOM_RIGHT:
]

"""
Entry point of this map correction algorithm
It walks the contour of the map based on the first non empty cell found.
The walk is repeated if the count of cell walked on is too low (the goal is
to avoid too small maps if we encounter an isolated cell for instace).
The walks also fix the map by adding cells when necessary and the walks stop
only when no tiles has been added.
Then based on the walked map a flood algorithm is done to ensure that all 
other non-conntected "islands" are eliminated.
"""
static func healMap(map: Array[int], mapSize: Vector2i) -> Array[int]:
	var browsedCells: Array[Vector2i] = []
	var startPoint: Vector2i
	while browsedCells.size() < 15:
		for v in browsedCells:
			map[v.x] = 0
		startPoint = findFirstNonEmptyCell(map, mapSize.x)
		browsedCells = browseHexMapContour(map, startPoint, mapSize)

	var hasMapGotNewTiles: bool = false
	for v in browsedCells:
		if map[v.x] == 4:
			hasMapGotNewTiles = true
			break

	for v: Vector2i in browsedCells:
		var i = v.x
		var value = v.y
		map[i] = value

	while hasMapGotNewTiles:
		browsedCells = browseHexMapContour(map, startPoint, mapSize) 
		hasMapGotNewTiles = false
		for v in browsedCells:
			if map[v.x] == 4:
				hasMapGotNewTiles = true
				break

		for v: Vector2i in browsedCells:
			var i = v.x
			var value = v.y
			map[i] = value
	
	var floodStartPoint = indexToCoord(browsedCells[0].x, mapSize.x) 
	var fixedMap = removeUnlinkedCells(map, floodStartPoint, mapSize)
	setEntryAndExitTiles(fixedMap, mapSize)
	return fixedMap

"""
Browse the given map and returns the 2D coordinates of the first non empty cell
"""
static func findFirstNonEmptyCell(map: Array[int], mapWidth: int) -> Vector2i:
	for i in map.size():
		if (map[i] != 0):
			return indexToCoord(i, mapWidth)
	return -Vector2i.ONE

"""
Returns a 2D Vector for hex coordinates adjustments.
Based on the current hex reference, if X is on an odd coordinate, no adjustement is required
Same if the direction to adjust to is TOP or BOTTOM, no adjustement is necessary
In the other cases, an adjustement is required
"""
static func getYHexOffset(isXEven: bool, directionToCheck: HexDirection) -> Vector2i:
	if (!isXEven || directionToCheck == HexDirection.TOP || directionToCheck == HexDirection.BOTTOM):
		return Vector2i.ZERO
	return Vector2i.UP

static func setEntryAndExitTiles(map: Array[int], mapSize: Vector2i) -> void:
	var centerRowCoord = int((mapSize.y - 1) * .5)
	var entryCoord = Vector2i(0, centerRowCoord)
	var exitCoord = Vector2i(mapSize.x - 1 , centerRowCoord)

	for y in range(mapSize.y / 2):
		entryCoord = Vector2i(0, centerRowCoord + y)
		var mapIndex = coordToIndex(entryCoord, mapSize.x)
		if (map[mapIndex] == 0): 
			map[mapIndex] = 5
			break

		entryCoord = Vector2i(0, centerRowCoord - y)
		mapIndex = coordToIndex(entryCoord, mapSize.x)
		if (map[mapIndex] == 0):
			map[mapIndex] = 5
			break

	var tileNextToEntryCoord = entryCoord + getYHexOffset(true, HexDirection.TOP_RIGHT) + hexDirVector[HexDirection.TOP_RIGHT]
	var tileNextToEntryIndex = coordToIndex(tileNextToEntryCoord, mapSize.x)
	var tileNextToEntryValue = map[tileNextToEntryIndex]
	while tileNextToEntryValue == 0:
		var isXEven = tileNextToEntryCoord.x & 1 == 0
		var mapValue = 6
		if isXEven:
			mapValue = 7
		map[tileNextToEntryIndex] = mapValue
		var direction = HexDirection.BOTTOM_RIGHT
		if isXEven:
			direction = HexDirection.TOP_RIGHT
	
		tileNextToEntryCoord = tileNextToEntryCoord + getYHexOffset(isXEven, direction) + hexDirVector[direction]
		tileNextToEntryIndex = coordToIndex(tileNextToEntryCoord, mapSize.x)
		tileNextToEntryValue = map[tileNextToEntryIndex]

	for y in range(mapSize.y / 2):
		exitCoord = Vector2i(mapSize.x - 1, centerRowCoord + y)
		var mapIndex = coordToIndex(exitCoord, mapSize.x)
		if (map[mapIndex] == 0): 
			map[mapIndex] = 8
			break

		entryCoord = Vector2i(mapSize.x - 1, centerRowCoord - y)
		mapIndex = coordToIndex(exitCoord, mapSize.x)
		if (map[mapIndex] == 0):
			map[mapIndex] = 8
			break

	var isXEven = exitCoord.x & 1 == 0
	var direction = HexDirection.TOP_LEFT
	if isXEven:
		direction = HexDirection.BOTTOM_LEFT
	var tileNextToExitCoord = exitCoord + getYHexOffset(exitCoord.x & 1 == 0, direction) + hexDirVector[direction]
	var tileNextToExitIndex = coordToIndex(tileNextToExitCoord, mapSize.x)
	var tileNextToExitValue = map[tileNextToExitIndex]
	while tileNextToExitValue == 0:
		isXEven = tileNextToExitCoord.x & 1 == 0
		var mapValue = 9
		if isXEven:
			mapValue = 10
		map[tileNextToExitIndex] = mapValue
		direction = HexDirection.TOP_LEFT
		if isXEven:
			direction = HexDirection.BOTTOM_LEFT
	
		tileNextToExitCoord = tileNextToExitCoord + getYHexOffset(isXEven, direction) + hexDirVector[direction]
		tileNextToExitIndex = coordToIndex(tileNextToExitCoord, mapSize.x)
		tileNextToExitValue = map[tileNextToExitIndex]


"""
Performs a flood algorithm on the map using a Hex coordinate system in order to remove all non
connecter cells to the main map
"""
static func removeUnlinkedCells(map: Array[int], startPoint: Vector2i, mapSize: Vector2i) -> Array[int]:
	var newGrid: Array[int] = []
	newGrid.resize(map.size())
	newGrid.fill(0)

	var stack: Array[Vector2i] = []
	@warning_ignore("integer_division")
	stack.resize(map.size() / 2)

	stack[0] = startPoint
	var stackSize = 1;
	var startPointIndex = coordToIndex(startPoint, mapSize.x)
	newGrid[startPointIndex] = map[startPointIndex]

	while stackSize > 0:
		var currentPoint = stack[stackSize - 1]
		stackSize -= 1

		var coordUp = currentPoint + hexDirVector[HexDirection.TOP]
		if coordUp.y > -1:
			var indexUp = coordToIndex(coordUp, mapSize.x)	
			var pointUp = map[indexUp]
			if (pointUp != 0 and newGrid[indexUp] == 0):
				newGrid[indexUp] = pointUp
				stack[stackSize] = coordUp
				stackSize += 1

		var coordBottom = currentPoint + hexDirVector[HexDirection.BOTTOM]
		if coordBottom.y < mapSize.y:
			var indexDown = coordToIndex(coordBottom, mapSize.x)
			var pointDown = map[indexDown]
			if (pointDown != 0 and newGrid[indexDown] == 0):
				newGrid[indexDown] = pointDown
				stack[stackSize] = coordBottom
				stackSize += 1

		var isXEven = currentPoint.x & 1 == 0
		var yOffset = getYHexOffset(isXEven, HexDirection.TOP_LEFT)

		var coordTopLeft = currentPoint + hexDirVector[HexDirection.TOP_LEFT] + yOffset
		if coordTopLeft.x > -1 && coordTopLeft.y > -1:
			var indexTopLeft = coordToIndex(coordTopLeft, mapSize.x)
			var pointTopLeft = map[indexTopLeft]
			if (pointTopLeft and newGrid[indexTopLeft] == 0):
				newGrid[indexTopLeft] = pointTopLeft
				stack[stackSize] = 	currentPoint + hexDirVector[HexDirection.TOP_LEFT] + yOffset
				stackSize += 1

		var coordTopRight = currentPoint + hexDirVector[HexDirection.TOP_RIGHT] + yOffset
		if coordTopRight.x < mapSize.x && coordTopRight.y > -1:
			var indexTopRight = coordToIndex(currentPoint + hexDirVector[HexDirection.TOP_RIGHT] + yOffset, mapSize.x)
			var pointTopRight = map[indexTopRight]
			if (pointTopRight and newGrid[indexTopRight] == 0):
				newGrid[indexTopRight] = pointTopRight
				stack[stackSize] = 	currentPoint + hexDirVector[HexDirection.TOP_RIGHT] + yOffset
				stackSize += 1

		var coordBottomLeft = currentPoint + hexDirVector[HexDirection.BOTTOM_LEFT] + yOffset
		if coordBottomLeft.x > -1 && coordBottomLeft.y < mapSize.y:
			var indexBottomLeft = coordToIndex(coordBottomLeft, mapSize.x)
			var pointBottomLeft = map[indexBottomLeft]
			if (pointBottomLeft and newGrid[indexBottomLeft] == 0):
				newGrid[indexBottomLeft] = pointBottomLeft
				stack[stackSize] = 	currentPoint + hexDirVector[HexDirection.BOTTOM_LEFT] + yOffset
				stackSize += 1

		var coordBottomRight = currentPoint + hexDirVector[HexDirection.BOTTOM_RIGHT] + yOffset
		if coordBottomRight.x < mapSize.x && coordBottomRight.y < mapSize.y:
			var indexBottomRight = coordToIndex(coordBottomRight, mapSize.x)
			var pointBottomRight = map[indexBottomRight]
			if (pointBottomRight and newGrid[indexBottomRight] == 0):
				newGrid[indexBottomRight] = pointBottomRight
				stack[stackSize] = 	currentPoint + hexDirVector[HexDirection.BOTTOM_RIGHT] + yOffset
				stackSize += 1

	return newGrid

"""
Fix the map by walking the contour of the hex map.
It goes from the starting point and checks all adjacent tiles (clockwise order)
If a tile is found, it restart the same process of the found tiles and goes on until reaching 
again the starting point (the loop is finished).
While browsing the map if no adjacent tiles are found (excluding the tile it came from) a new
tile is added on the map. The new tile is placed next to tile the walker originated from.
Also if a tile is found but was already walked on, a nex tile is added next to the found tiles
Howecer, if there is no way to add a tile this way because it is already taken, the algorithm 
stops.
All the walked tiles are returned.
"""
static func browseHexMapContour(map: Array[int], startPoint: Vector2i, mapSize: Vector2i) -> Array[Vector2i]:
	var fromDirection: HexDirection = HexDirection.TOP_LEFT;
	var currentCell: Vector2i = startPoint
	var finished = false
	var nextCellCoord: Vector2i
	var cellToFixDirectionIndex: int
	var cellToFix: int

	var firstIndex = coordToIndex(startPoint, mapSize.x)
	var indicesToClean: Array[Vector2i]
	indicesToClean.push_back(Vector2i(firstIndex, map[firstIndex]))
	map[firstIndex] = 1

	while !finished:
		var isXEven = currentCell.x & 1 == 0
		var isNextCellFound = false
		for i in range(4):
			var nextHexDirectionIndex = fromDirection + 2 + i
			if (nextHexDirectionIndex > 5):
				nextHexDirectionIndex -= 6

			var nextHexDirection = hexDirVector[nextHexDirectionIndex]
			var yOffset = getYHexOffset(isXEven, nextHexDirectionIndex) 
			nextCellCoord = nextHexDirection + currentCell + yOffset
			if (nextCellCoord.x < 0 || nextCellCoord.x >= mapSize.x || nextCellCoord.y < 0 || nextCellCoord.y >= mapSize.y):
				continue

			var nextCellIndex = coordToIndex(nextCellCoord, mapSize.x)
			if (map[nextCellIndex] == 0):
				continue

			isNextCellFound = true
			finished = startPoint == nextCellCoord
			if finished:
				break

			if (map[nextCellIndex] == 2 || map[nextCellIndex] == 3): # it's an already browsed cell, we enlarge the path
				indicesToClean.push_back(Vector2i(nextCellIndex, map[nextCellIndex]))
				map[nextCellIndex] = 1
				fromDirection = oppositeHexDirIndex[nextHexDirectionIndex] as HexDirection
				currentCell = nextCellCoord
			else: 
				cellToFixDirectionIndex = nextHexDirectionIndex - 1
				if (cellToFixDirectionIndex < 0):
					cellToFixDirectionIndex += 6
	
				yOffset = getYHexOffset(isXEven, cellToFixDirectionIndex) 
				nextCellCoord = currentCell + hexDirVector[cellToFixDirectionIndex] + yOffset
				if (nextCellCoord.x < 0 || nextCellCoord.x >= mapSize.x || nextCellCoord.y < 0 || nextCellCoord.y >= mapSize.y):
					finished = true
					break
	
				cellToFix = coordToIndex(nextCellCoord, mapSize.x)
				if (map[cellToFix] == 4 || map[cellToFix] == 1):
					finished = true
					break
				indicesToClean.push_back(Vector2i(cellToFix, 2))
				map[cellToFix] = 4

				fromDirection = oppositeHexDirIndex[cellToFixDirectionIndex] as HexDirection
				currentCell = nextCellCoord

			break

		if (isNextCellFound || finished): 
			continue

		# get back to the firection we came from
		cellToFixDirectionIndex = fromDirection
		for i in range(5):
			cellToFixDirectionIndex -= 1
			if (cellToFixDirectionIndex < 0):
				cellToFixDirectionIndex += 6

			var yOffset = getYHexOffset(isXEven, cellToFixDirectionIndex) 
			nextCellCoord = hexDirVector[cellToFixDirectionIndex] + currentCell + yOffset
			if (nextCellCoord.x < 0 || nextCellCoord.x >= mapSize.x || nextCellCoord.y < 0 || nextCellCoord.y >= mapSize.y):
				continue

			break

		cellToFix = coordToIndex(nextCellCoord, mapSize.x)
		if (map[cellToFix] == 4 || map[cellToFix] == 1):
			finished = true
			continue
		
		indicesToClean.push_back(Vector2i(cellToFix, 2))
		map[cellToFix] = 4
		
		fromDirection = oppositeHexDirIndex[cellToFixDirectionIndex] as HexDirection
		currentCell = nextCellCoord
		finished = nextCellCoord == startPoint

	return indicesToClean

"""
Returns the index of a cell in the map Array given its 2D coordinates
It converts a 2D coordinates into a 1D array index based on a given map width
"""
static func coordToIndex(coord: Vector2i, mapWidth: int) -> int:
	return mapWidth * coord.y + coord.x

"""
Returns the coordinates of a cell given its index in the map and the size of the map.
It converts a 1D array index to its cooresponding 2D coordinates based on a given map width
"""
static func indexToCoord(index: int, mapWidth: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(index % mapWidth, index / mapWidth)
