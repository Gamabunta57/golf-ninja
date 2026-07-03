class_name BuildingData
extends RefCounted

## The full generated building: an ordered list of floors (index 0 = top,
## floor_count - 1 = bottom) plus the elevator network. This is the sole output
## of the MapGenerator and the sole input the renderers/systems read from.

var floors: Array[FloorData] = []
## grid_position:Vector2i -> ElevatorLink servicing that coordinate.
var elevator_network: Dictionary = {}
var seed_used: int = 0
var player_start_floor: int = 0
var player_start_cell: Vector2i = Vector2i.ZERO


func floor_count() -> int:
	return floors.size()


func top_floor_index() -> int:
	return 0


func final_floor_index() -> int:
	return floors.size() - 1


func get_floor(floor_index: int) -> FloorData:
	if floor_index < 0 or floor_index >= floors.size():
		return null
	return floors[floor_index]


## The elevator link servicing a coordinate, or null if none.
func get_elevator(grid_position: Vector2i) -> ElevatorLink:
	return elevator_network.get(grid_position, null)


## All elevator links present on a given floor.
func elevators_on_floor(floor_index: int) -> Array[ElevatorLink]:
	var out: Array[ElevatorLink] = []
	for link: ElevatorLink in elevator_network.values():
		if link.services_floor(floor_index):
			out.append(link)
	return out
