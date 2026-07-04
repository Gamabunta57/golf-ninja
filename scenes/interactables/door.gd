class_name Door
extends Node2D

## A door on its cell (plan Phase 10). Presentational: access rules live in
## DoorKeycardSystem. Reflects locked/open state and its required access level.

const COL_LOCKED: Color = Color(0.85, 0.2, 0.25)
const COL_OPEN: Color = Color(0.35, 0.65, 0.4, 0.5)
const COL_TRIM: Color = Color(0.1, 0.05, 0.05)

var data: DoorData
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func setup(door_data: DoorData) -> void:
	data = door_data
	var cs: int = FloorRenderer.CELL_SIZE
	position = Vector2(data.position.x * cs, data.position.y * cs)
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var cs: int = FloorRenderer.CELL_SIZE
	var rect: Rect2 = Rect2(Vector2(4, 4), Vector2(cs - 8, cs - 8))
	if data.is_open:
		draw_rect(rect, COL_OPEN, false, 2.0)
	else:
		draw_rect(rect, COL_LOCKED, true)
		draw_rect(rect, COL_TRIM, false, 2.0)
		if _font != null:
			draw_string(_font, Vector2(6, 15), "L%d" % data.required_access_level,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.9))
