class_name Locker
extends Node2D

## A hiding spot (plan Phase 9). Purely presentational: the concealment rules
## live in HidingSystem and the root. Draws a locker on its cell and changes
## appearance while the player is hidden inside it.

const COL_BODY: Color = Color(0.35, 0.3, 0.22)
const COL_BODY_OCCUPIED: Color = Color(0.3, 0.55, 0.85)
const COL_TRIM: Color = Color(0.7, 0.62, 0.4)

var cell: Vector2i
var occupied: bool = false


func setup(locker_cell: Vector2i) -> void:
	cell = locker_cell
	var cs: int = FloorRenderer.CELL_SIZE
	position = Vector2(cell.x * cs, cell.y * cs)
	queue_redraw()


func set_occupied(value: bool) -> void:
	if occupied != value:
		occupied = value
		queue_redraw()


func _draw() -> void:
	var cs: int = FloorRenderer.CELL_SIZE
	var rect: Rect2 = Rect2(Vector2(3, 3), Vector2(cs - 6, cs - 6))
	draw_rect(rect, COL_BODY_OCCUPIED if occupied else COL_BODY, true)
	draw_rect(rect, COL_TRIM, false, 2.0)
	# Handle/latch line down the middle.
	draw_line(Vector2(cs * 0.5, 5), Vector2(cs * 0.5, cs - 5), COL_TRIM, 1.5)
