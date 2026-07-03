class_name PlayerIntent
extends RefCounted

## Abstract, device-independent snapshot of what the player wants to do this
## frame (GDD §7.1). The input layer produces these; systems/scenes consume them
## — nothing downstream should read Godot's Input directly. Fields are added as
## later phases need them (aim/confirm/cancel/hide); Phase 5 needs movement and
## a generic "interact" edge (used to ride elevators).

## Desired movement direction, each axis in [-1, 1]. Not normalised beyond the
## device's own clamping so analog sticks keep their magnitude.
var move: Vector2 = Vector2.ZERO

## True only on the frame interact was pressed (edge, not held).
var interact_pressed: bool = false


func has_movement() -> bool:
	return move.length_squared() > 0.0001
