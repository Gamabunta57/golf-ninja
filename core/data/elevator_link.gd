class_name ElevatorLink
extends RefCounted

## Player-only floor transition. Its grid position is identical on every floor
## it services (GDD §6.3 guarantee #4), though it need not appear on all floors.

var grid_position: Vector2i
var serviced_floors: Array[int] = []


func _init(p_grid_position: Vector2i = Vector2i.ZERO, p_serviced_floors: Array[int] = []) -> void:
	grid_position = p_grid_position
	serviced_floors = p_serviced_floors.duplicate()


func services_floor(floor_index: int) -> bool:
	return serviced_floors.has(floor_index)


## Floors reachable from `floor_index` via this elevator (all serviced floors
## except the one the player is already on).
func destinations_from(floor_index: int) -> Array[int]:
	var out: Array[int] = []
	for f in serviced_floors:
		if f != floor_index:
			out.append(f)
	return out
