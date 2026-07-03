extends Node2D

## Phase 4 debug harness: generates a BuildingData from a GenerationConfig and
## lets a developer step through the floors visually. No player character or
## gameplay systems yet — this exists purely to inspect generator output.
##
## Controls:
##   ] / Down / Page Down  -> next floor (deeper)
##   [ / Up  / Page Up     -> previous floor
##   R                     -> regenerate with a new seed
##   Enter                 -> regenerate with the config's fixed seed

@export var config: GenerationConfig

var _building: BuildingData
var _current_floor: int = 0
var _renderer: FloorRenderer
var _camera: Camera2D
var _hud: Label
var _seed_counter: int = 0


func _ready() -> void:
	if config == null:
		config = GenerationConfig.new()

	_renderer = FloorRenderer.new()
	add_child(_renderer)

	_camera = Camera2D.new()
	_camera.enabled = true
	add_child(_camera)

	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	_hud.add_theme_font_size_override("font_size", 14)
	layer.add_child(_hud)

	_regenerate(config.seed, config.use_random_seed)


func _regenerate(seed_value: int, random: bool) -> void:
	config.seed = seed_value
	config.use_random_seed = random
	Prng.configure(config, seed_value)

	var generator: MapGenerator = MapGenerator.new()
	_building = generator.generate(config, Prng.service)
	Game.set_building(_building)

	var validator: GenerationValidator = GenerationValidator.new()
	var result: Dictionary = validator.check_all(_building, config)
	if not result["valid"]:
		push_warning("Generated building FAILED validation: %s" % str(result["errors"]))

	_current_floor = 0
	_show_floor(0, result)


func _show_floor(index: int, validation: Dictionary = {}) -> void:
	if _building == null or _building.floor_count() == 0:
		return
	_current_floor = clampi(index, 0, _building.floor_count() - 1)
	var fd: FloorData = _building.get_floor(_current_floor)

	var start_cell: Vector2i = Vector2i(-1, -1)
	if _current_floor == _building.player_start_floor:
		start_cell = _building.player_start_cell
	_renderer.set_floor_data(fd, start_cell)

	# Centre the camera on the floor and fit it to the viewport.
	var size_px: Vector2 = _renderer.pixel_size()
	_camera.position = size_px * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var margin: float = 0.85
	var zoom_factor: float = minf(vp.x / size_px.x, vp.y / size_px.y) * margin
	_camera.zoom = Vector2(zoom_factor, zoom_factor)

	_update_hud(validation)


func _update_hud(validation: Dictionary) -> void:
	var valid_txt: String = "valid" if validation.get("valid", true) else "INVALID: %s" % str(validation.get("errors", []))
	var fd: FloorData = _building.get_floor(_current_floor)
	var lines: Array[String] = [
		"seed: %d   (%s)" % [_building.seed_used, valid_txt],
		"floor %d / %d%s" % [_current_floor, _building.floor_count() - 1, "  [TOP]" if _current_floor == 0 else ("  [FINAL HOLE]" if _current_floor == _building.final_floor_index() else "")],
		"hole %s | conduits %d | elevators %d | doors %d | keycards %d | cameras %d | guards %d" % [
			fd.hole_position, fd.conduits.size(), fd.elevator_positions.size(), fd.doors.size(), fd.keycards.size(), fd.camera_zones.size(), fd.guard_patrols.size()
		],
		"[ / ] step floors    R = new seed    Enter = reset seed",
	]
	_hud.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_BRACKETRIGHT, KEY_DOWN, KEY_PAGEDOWN:
			_show_floor(_current_floor + 1)
		KEY_BRACKETLEFT, KEY_UP, KEY_PAGEUP:
			_show_floor(_current_floor - 1)
		KEY_R:
			_seed_counter += 1
			_regenerate(_seed_counter, false)
		KEY_ENTER, KEY_KP_ENTER:
			_regenerate(config.seed, false)
