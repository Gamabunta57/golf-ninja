class_name ConduitLink
extends RefCounted

## A wall conduit: transports the ball downward from one floor to a strictly
## lower floor (see GDD §4.1 / §6.3 — conduits are downward-only).

var origin_floor: int
var origin_position: Vector2i
var destination_floor: int   # invariant: always > origin_floor
var destination_position: Vector2i


func _init(
	p_origin_floor: int = 0,
	p_origin_position: Vector2i = Vector2i.ZERO,
	p_destination_floor: int = 0,
	p_destination_position: Vector2i = Vector2i.ZERO
) -> void:
	origin_floor = p_origin_floor
	origin_position = p_origin_position
	destination_floor = p_destination_floor
	destination_position = p_destination_position


func drop_distance() -> int:
	return destination_floor - origin_floor
