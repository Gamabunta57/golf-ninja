class_name Player
extends CharacterBody2D

## Player-controlled infiltrator (plan Phase 5). Movement is driven by the
## abstract PlayerIntent and constrained to walkable cells of the current
## FloorData — walls are data, not physics bodies, so movement is resolved by
## sampling the walkable grid rather than move_and_slide. Floor changes are
## handled by the root via the ElevatorSystem when `interacted` fires.

signal interacted(cell: Vector2i)

const SPEED: float = 150.0
const RADIUS: float = 10.0
const COL_BODY: Color = Color(0.3, 0.9, 0.45)
const COL_OUTLINE: Color = Color(0.05, 0.2, 0.1)

var floor_data: FloorData
var input_source: PlayerInput


func _ready() -> void:
	if input_source == null:
		input_source = PlayerInput.new()


## Places the player on `floor_data` at the centre of `start_cell`.
func setup(new_floor: FloorData, start_cell: Vector2i) -> void:
	floor_data = new_floor
	global_position = _cell_center(start_cell)
	queue_redraw()


## Swaps the active floor (used after an elevator ride) and repositions.
func move_to_floor(new_floor: FloorData, cell: Vector2i) -> void:
	floor_data = new_floor
	global_position = _cell_center(cell)


func current_cell() -> Vector2i:
	return _world_to_cell(global_position)


func _physics_process(delta: float) -> void:
	if floor_data == null or input_source == null:
		return
	var intent: PlayerIntent = input_source.poll()
	var step: Vector2 = intent.move * SPEED * delta
	var pos: Vector2 = global_position

	# Resolve each axis independently so sliding along walls feels natural.
	var try_x: Vector2 = pos + Vector2(step.x, 0.0)
	if _is_free(try_x):
		pos.x = try_x.x
	var try_y: Vector2 = Vector2(pos.x, pos.y) + Vector2(0.0, step.y)
	if _is_free(try_y):
		pos.y = try_y.y
	global_position = pos

	if intent.interact_pressed:
		interacted.emit(current_cell())


## True if a small box around `world_pos` lies entirely on walkable cells.
func _is_free(world_pos: Vector2) -> bool:
	if floor_data == null:
		return false
	for off in [Vector2(-RADIUS, -RADIUS), Vector2(RADIUS, -RADIUS), Vector2(-RADIUS, RADIUS), Vector2(RADIUS, RADIUS)]:
		if not floor_data.is_walkable(_world_to_cell(world_pos + off)):
			return false
	return true


func _world_to_cell(p: Vector2) -> Vector2i:
	var cs: int = FloorRenderer.CELL_SIZE
	return Vector2i(floori(p.x / cs), floori(p.y / cs))


func _cell_center(cell: Vector2i) -> Vector2:
	var cs: int = FloorRenderer.CELL_SIZE
	return Vector2((cell.x + 0.5) * cs, (cell.y + 0.5) * cs)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 1.0, COL_OUTLINE)
	draw_circle(Vector2.ZERO, RADIUS, COL_BODY)
