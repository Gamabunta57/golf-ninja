extends Node2D

## Game root (evolving through the phases). Phase 4 rendered floors passively;
## Phase 5 adds a controllable player that walks the current floor and rides
## elevators between floors. Detection/ball/guards arrive in later phases.
##
## Controls:
##   WASD / arrows / left stick -> move
##   E / Space / gamepad A      -> interact (ride an elevator you stand on)
##   R                          -> regenerate with a new seed
##   Enter                      -> regenerate with the config's fixed seed

@export var config: GenerationConfig

var _building: BuildingData
var _player_state: PlayerState
var _renderer: FloorRenderer
var _player: Player
var _camera: Camera2D
var _hud: Label
var _elevators: ElevatorSystem = ElevatorSystem.new()
var _seed_counter: int = 0


func _ready() -> void:
	if config == null:
		config = GenerationConfig.new()

	_renderer = FloorRenderer.new()
	add_child(_renderer)

	_player = Player.new()
	add_child(_player)
	_player.interacted.connect(_on_player_interacted)

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

	var result: Dictionary = GenerationValidator.new().check_all(_building, config)
	if not result["valid"]:
		push_warning("Generated building FAILED validation: %s" % str(result["errors"]))

	_player_state = PlayerState.new(config.player_health)
	_player_state.current_floor = _building.player_start_floor
	_player_state.grid_position = _building.player_start_cell

	var start_floor: FloorData = _building.get_floor(_building.player_start_floor)
	_player.setup(start_floor, _building.player_start_cell)
	_show_floor(_building.player_start_floor)


func _show_floor(index: int) -> void:
	if _building == null:
		return
	_player_state.current_floor = index
	var fd: FloorData = _building.get_floor(index)

	var start_cell: Vector2i = Vector2i(-1, -1)
	if index == _building.player_start_floor:
		start_cell = _building.player_start_cell
	_renderer.set_floor_data(fd, start_cell)

	# Fit the camera to the whole floor and centre it.
	var size_px: Vector2 = _renderer.pixel_size()
	_camera.position = size_px * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var zoom_factor: float = minf(vp.x / size_px.x, vp.y / size_px.y) * 0.85
	_camera.zoom = Vector2(zoom_factor, zoom_factor)


func _on_player_interacted(cell: Vector2i) -> void:
	var dest: int = _elevators.next_destination(_building, _player_state.current_floor, cell)
	if dest < 0:
		return
	var dest_floor: FloorData = _building.get_floor(dest)
	_player.move_to_floor(dest_floor, cell)
	_player_state.current_floor = dest
	_show_floor(dest)


func _process(_delta: float) -> void:
	_update_hud()


func _update_hud() -> void:
	if _building == null:
		return
	var f: int = _player_state.current_floor
	var tag: String = ""
	if f == 0:
		tag = "  [TOP]"
	elif f == _building.final_floor_index():
		tag = "  [FINAL HOLE]"

	var hint: String = ""
	var cell: Vector2i = _player.current_cell()
	if _elevators.can_use(_building, f, cell):
		var dest: int = _elevators.next_destination(_building, f, cell)
		hint = "   [E] ride to floor %d" % dest

	_hud.text = "seed %d   HP %d/%d   floor %d/%d%s%s" % [
		_building.seed_used, _player_state.health, _player_state.max_health,
		f, _building.final_floor_index(), tag, hint,
	]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_seed_counter += 1
			_regenerate(_seed_counter, false)
		KEY_ENTER, KEY_KP_ENTER:
			_regenerate(config.seed, false)
