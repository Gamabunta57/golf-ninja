class_name SecurityCamera
extends Node2D

## Visual for one static camera (plan Phase 7). Detection itself lives in the
## shared DetectionResolver; this node only reflects live state: it draws the
## observed zone tinted by whether the camera is currently jammed (ball nearby),
## contributing to an active alarm on its floor, or idle.

const COL_IDLE_ZONE: Color = Color(0.7, 0.35, 0.9, 0.14)
const COL_ACTIVE_ZONE: Color = Color(0.95, 0.2, 0.2, 0.30)
const COL_JAMMED_ZONE: Color = Color(0.5, 0.5, 0.5, 0.12)
const COL_IDLE: Color = Color(0.7, 0.35, 0.9)
const COL_ACTIVE: Color = Color(0.95, 0.2, 0.2)
const COL_JAMMED: Color = Color(0.55, 0.55, 0.55)

var data: CameraZoneData
var floor_index: int
var _detection: DetectionResolver


func setup(camera_data: CameraZoneData, on_floor: int, detection: DetectionResolver) -> void:
	data = camera_data
	floor_index = on_floor
	_detection = detection


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var jammed: bool = data.is_jammed(Time.get_ticks_msec())
	var floor_active: bool = _detection != null and _detection.alarm.is_active(floor_index)

	var zone_col: Color = COL_IDLE_ZONE
	var dot_col: Color = COL_IDLE
	if jammed:
		zone_col = COL_JAMMED_ZONE
		dot_col = COL_JAMMED
	elif floor_active:
		zone_col = COL_ACTIVE_ZONE
		dot_col = COL_ACTIVE

	var cs: int = FloorRenderer.CELL_SIZE
	for cell: Vector2i in data.observed_cells:
		draw_rect(Rect2(Vector2(cell.x * cs, cell.y * cs), Vector2(cs, cs)), zone_col, true)
	var center: Vector2 = Vector2((data.position.x + 0.5) * cs, (data.position.y + 0.5) * cs)
	draw_circle(center, cs * 0.22, dot_col)
