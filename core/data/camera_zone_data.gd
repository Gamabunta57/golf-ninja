class_name CameraZoneData
extends RefCounted

## A static security camera and its precomputed observed cells. When the ball
## comes within jam radius the camera is disabled until `jammed_until_ms`.

var position: Vector2i
var observed_cells: Array[Vector2i] = []
var jammed_until_ms: int = 0


func _init(p_position: Vector2i = Vector2i.ZERO, p_observed_cells: Array[Vector2i] = []) -> void:
	position = p_position
	observed_cells = p_observed_cells.duplicate()


func is_jammed(now_ms: int) -> bool:
	return now_ms < jammed_until_ms


## True if `cell` is within this camera's observed zone. Callers should also
## check is_jammed() before treating an observation as a detection.
func observes(cell: Vector2i) -> bool:
	return observed_cells.has(cell)
