extends Node2D

## Game root (evolving through the phases). Phases 4–5 added floor rendering and
## a player that rides elevators; Phase 6 adds the ball, aiming, and shooting.
## The player follows the ball floor-to-floor via elevators and shoots it (1 HP
## per shot) until it drops through the final hole (win) or runs out of shots.
## Stealth/guards arrive in later phases.
##
## Controls:
##   WASD / arrows / left stick -> move (or adjust aim while aiming)
##   E / Space / gamepad A      -> interact: aim the nearby ball, or ride an
##                                 elevator, or (while aiming) confirm the shot
##   Esc / gamepad B            -> cancel aiming
##   R / Enter                  -> regenerate (new seed / fixed seed)

@export var config: GenerationConfig

const AIM_RANGE_PX: float = 1.6 * FloorRenderer.CELL_SIZE

var _building: BuildingData
var _player_state: PlayerState
var _renderer: FloorRenderer
var _player: Player
var _ball: Ball
var _aim_ui: ShotAimUI
var _camera: Camera2D
var _hud: Label
var _input: PlayerInput = PlayerInput.new()
var _elevators: ElevatorSystem = ElevatorSystem.new()
var _aim: ShotAimController = ShotAimController.new()

var _seed_counter: int = 0
var _shots_taken: int = 0
var _won: bool = false
var _out_of_shots: bool = false


func _ready() -> void:
	if config == null:
		config = GenerationConfig.new()

	_renderer = FloorRenderer.new()
	add_child(_renderer)

	_ball = Ball.new()
	add_child(_ball)
	_ball.stopped.connect(_on_ball_stopped)
	_ball.reached_floor.connect(_on_ball_reached_floor)
	_ball.reached_final_hole.connect(_on_ball_reached_final_hole)

	_player = Player.new()
	add_child(_player)

	_aim_ui = ShotAimUI.new()
	add_child(_aim_ui)

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

	_shots_taken = 0
	_won = false
	_out_of_shots = false
	_aim.cancel()
	_aim_ui.hide_aim()

	_ball.setup(_building, config)
	_player.setup(_building.get_floor(_building.player_start_floor), _building.player_start_cell)
	_show_floor(_building.player_start_floor)


func _show_floor(index: int) -> void:
	if _building == null:
		return
	_player_state.current_floor = index
	_renderer.set_floor_data(_building.get_floor(index), _start_marker_for(index))

	var size_px: Vector2 = _renderer.pixel_size()
	_camera.position = size_px * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var zoom_factor: float = minf(vp.x / size_px.x, vp.y / size_px.y) * 0.85
	_camera.zoom = Vector2(zoom_factor, zoom_factor)
	_update_ball_visibility()


func _start_marker_for(index: int) -> Vector2i:
	if index == _building.player_start_floor:
		return _building.player_start_cell
	return Vector2i(-1, -1)


func _physics_process(delta: float) -> void:
	if _building == null:
		return
	var intent: PlayerIntent = _input.poll()

	if _aim.active:
		_aim.update(intent.move, delta)
		_aim_ui.show_aim(_ball.global_position, _aim.angle, _aim.power)
		if intent.cancel_pressed:
			_cancel_aim()
		elif intent.interact_pressed and _aim.can_fire():
			_fire_shot()
	elif not _run_over():
		_player.move(intent.move, delta)
		if intent.interact_pressed:
			_handle_interact()

	_update_ball_visibility()


func _handle_interact() -> void:
	# Aiming a nearby, at-rest ball on this floor takes priority over elevators.
	if _can_aim():
		_begin_aim()
		return
	var cell: Vector2i = _player.current_cell()
	var dest: int = _elevators.next_destination(_building, _player_state.current_floor, cell)
	if dest >= 0:
		_player.move_to_floor(_building.get_floor(dest), cell)
		_show_floor(dest)


func _can_aim() -> bool:
	if _run_over():
		return false
	if _player_state.current_floor != _ball.state.current_floor:
		return false
	if not _ball.is_at_rest():
		return false
	return _player.global_position.distance_to(_ball.global_position) <= AIM_RANGE_PX


func _begin_aim() -> void:
	# Seed the aim toward this floor's hole as a convenience.
	var hole: Vector2i = _building.get_floor(_player_state.current_floor).hole_position
	var toward: Vector2 = (Vector2(hole) + Vector2(0.5, 0.5)) - _ball.state.grid_position
	_aim.begin(toward.angle() if toward.length_squared() > 0.001 else 0.0)
	_aim_ui.show_aim(_ball.global_position, _aim.angle, _aim.power)


func _cancel_aim() -> void:
	_aim.cancel()
	_aim_ui.hide_aim()


func _fire_shot() -> void:
	_ball.shoot(_aim.aim_direction(), _aim.power)
	_cancel_aim()
	_player_state.spend_health(1)
	_shots_taken += 1
	if _player_state.is_out_of_health():
		_out_of_shots = true


func _update_ball_visibility() -> void:
	if _ball.state == null:
		return
	_ball.visible = (_ball.state.current_floor == _player_state.current_floor) and not _ball.state.is_in_transit


func _run_over() -> bool:
	return _won or _out_of_shots


# --- ball signal handlers ---------------------------------------------------

func _on_ball_stopped() -> void:
	_update_ball_visibility()


func _on_ball_reached_floor(_floor_index: int) -> void:
	_update_ball_visibility()


func _on_ball_reached_final_hole() -> void:
	_won = true
	_cancel_aim()


# --- HUD --------------------------------------------------------------------

func _process(_delta: float) -> void:
	_update_hud()


func _update_hud() -> void:
	if _building == null:
		return
	var pf: int = _player_state.current_floor
	var bf: int = _ball.state.current_floor if _ball.state != null else 0

	var status: String = ""
	if _won:
		status = "\n>>> YOU WIN in %d shots! (R to play again)" % _shots_taken
	elif _out_of_shots:
		status = "\n>>> OUT OF SHOTS (R to play again)"
	elif _aim.active:
		status = "\n[E] fire   [Esc] cancel   (move to aim / adjust power)"
	elif _can_aim():
		status = "\n[E] aim the ball"
	elif _elevators.can_use(_building, pf, _player.current_cell()):
		status = "\n[E] ride to floor %d" % _elevators.next_destination(_building, pf, _player.current_cell())
	elif bf != pf:
		status = "\n(ball is on floor %d — find an elevator route down)" % bf

	_hud.text = "seed %d   HP %d/%d   shots %d\nplayer floor %d/%d   ball floor %d%s" % [
		_building.seed_used, _player_state.health, _player_state.max_health, _shots_taken,
		pf, _building.final_floor_index(), bf, status,
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
