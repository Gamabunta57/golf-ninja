class_name ElevatorSystem
extends RefCounted

## Player-only floor transitions (plan §7.3 #9). Pure logic over BuildingData:
## given the player's current floor and an elevator coordinate, it reports which
## floors that elevator can take the player to. Guards never use this.

## Floors this elevator can move the player to from `current_floor` (empty if the
## coordinate has no elevator, or the elevator doesn't service this floor).
func destinations(building: BuildingData, current_floor: int, coord: Vector2i) -> Array[int]:
	var link: ElevatorLink = building.get_elevator(coord)
	if link == null or not link.services_floor(current_floor):
		return []
	return link.destinations_from(current_floor)


## True if `coord` holds an elevator servicing `current_floor`.
func can_use(building: BuildingData, current_floor: int, coord: Vector2i) -> bool:
	return not destinations(building, current_floor, coord).is_empty()


## The next serviced floor after `current_floor` in ascending, wrapping order —
## a minimal chooser so repeated interactions visit every serviced floor.
## Returns -1 when the elevator can't be used from here.
func next_destination(building: BuildingData, current_floor: int, coord: Vector2i) -> int:
	var link: ElevatorLink = building.get_elevator(coord)
	if link == null or not link.services_floor(current_floor):
		return -1
	var sorted: Array[int] = link.serviced_floors.duplicate()
	sorted.sort()
	# First serviced floor strictly greater than current, else wrap to the first.
	for f: int in sorted:
		if f > current_floor:
			return f
	for f: int in sorted:
		if f != current_floor:
			return f
	return -1
