class_name KeycardPickup
extends Node2D

## A keycard pickup on its cell (plan Phase 10). Auto-collected on walk-over by
## the root via DoorKeycardSystem; this node is freed once collected.

const COL_CARD: Color = Color(0.95, 0.85, 0.2)
const COL_TRIM: Color = Color(0.4, 0.35, 0.05)

var data: KeycardData
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func setup(card: KeycardData) -> void:
	data = card
	var cs: int = FloorRenderer.CELL_SIZE
	position = Vector2((data.position.x + 0.5) * cs, (data.position.y + 0.5) * cs)
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var r: float = FloorRenderer.CELL_SIZE * 0.28
	var pts: PackedVector2Array = [Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)]
	draw_colored_polygon(pts, COL_CARD)
	draw_polyline(pts + PackedVector2Array([pts[0]]), COL_TRIM, 1.5)
	if _font != null:
		draw_string(_font, Vector2(-3, 4), "%d" % data.access_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_TRIM)
