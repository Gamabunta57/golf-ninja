class_name BallState
extends RefCounted

## Mutable ball state. Position/velocity are in continuous (sub-cell) space so
## the physics resolver can model rolling and bounces; grid lookups round to
## the nearest cell. `is_in_transit` is true while dropping through a hole or
## travelling a conduit, during which normal rolling physics is suspended.

var current_floor: int = 0
var grid_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_in_transit: bool = false


func _init(p_current_floor: int = 0, p_grid_position: Vector2 = Vector2.ZERO) -> void:
	current_floor = p_current_floor
	grid_position = p_grid_position


func cell() -> Vector2i:
	return Vector2i(roundi(grid_position.x), roundi(grid_position.y))


func is_moving() -> bool:
	return not is_in_transit and velocity.length_squared() > 0.0001
