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
var _detection: DetectionResolver = DetectionResolver.new()
var _cameras: Array[SecurityCamera] = []
var _guards: Array[Guard] = []

var _seed_counter: int = 0
var _shots_taken: int = 0
var _won: bool = false
var _out_of_shots: bool = false
var _caught: bool = false


func _ready() -> void:
	if config == null:
		config = GenerationConfig.new()

	_renderer = FloorRenderer.new()
	_renderer.z_index = 0
	add_child(_renderer)

	_ball = Ball.new()
	_ball.z_index = 3
	add_child(_ball)
	_ball.stopped.connect(_on_ball_stopped)
	_ball.reached_floor.connect(_on_ball_reached_floor)
	_ball.reached_final_hole.connect(_on_ball_reached_final_hole)

	_player = Player.new()
	_player.z_index = 4
	add_child(_player)

	_aim_ui = ShotAimUI.new()
	_aim_ui.z_index = 5
	add_child(_aim_ui)

	_detection.alarm_triggered.connect(_on_alarm_triggered)
	_detection.alarm_searching.connect(_on_alarm_searching)
	_detection.alarm_cleared.connect(_on_alarm_cleared)

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
	_caught = false
	_aim.cancel()
	_aim_ui.hide_aim()
	_detection.alarm = AlarmState.new()

	_ball.setup(_building, config)
	_player.setup(_building.get_floor(_building.player_start_floor), _building.player_start_cell)
	_show_floor(_building.player_start_floor)


func _show_floor(index: int) -> void:
	if _building == null:
		return
	_player_state.current_floor = index
	var fd: FloorData = _building.get_floor(index)
	_renderer.set_floor_data(fd, _start_marker_for(index))
	_spawn_cameras(fd, index)
	_spawn_guards(fd)

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


func _spawn_cameras(fd: FloorData, index: int) -> void:
	_clear_cameras()
	for cam: CameraZoneData in fd.camera_zones:
		var node: SecurityCamera = SecurityCamera.new()
		node.z_index = 1
		node.setup(cam, index, _detection)
		add_child(node)
		_cameras.append(node)


func _clear_cameras() -> void:
	for cam in _cameras:
		cam.queue_free()
	_cameras.clear()


func _spawn_guards(fd: FloorData) -> void:
	_clear_guards()
	var gid: int = 0
	for gp: GuardPatrolData in fd.guard_patrols:
		var g: Guard = Guard.new()
		g.z_index = 3
		g.setup(gid, gp, fd, _detection, config.guard_health)
		g.defeated.connect(_on_guard_defeated)
		g.shot_ball.connect(_on_guard_shot_ball)
		g.caught_player.connect(_on_player_caught)
		add_child(g)
		_guards.append(g)
		gid += 1


func _clear_guards() -> void:
	for g in _guards:
		g.queue_free()
	_guards.clear()


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

	_run_detection(delta)
	if not _run_over():
		for g in _guards:
			g.act(delta, _detection.alarm, _player, _ball)
	_update_ball_visibility()


## Runs the alarm state machine for every floor each frame. The player can only
## be seen on the floor they occupy; other floors receive seen=false so any
## ACTIVE alarm decays through SEARCHING to INACTIVE, and SEARCHING timers keep
## ticking after the player rides away (elevators break line of sight).
func _run_detection(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var player_cell: Vector2i = _player.current_cell()
	var pf: int = _player_state.current_floor
	for f in _building.floor_count():
		var seen: bool = false
		if f == pf:
			seen = _detection.camera_sees_cell(_building.get_floor(f), player_cell, now)
			if not seen:
				for g in _guards:
					if g.sees_player(player_cell):
						seen = true
						break
		_detection.update_floor(f, seen, player_cell, config.alarm_search_duration_sec, delta)


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
	return _won or _out_of_shots or _caught


# --- ball signal handlers ---------------------------------------------------

func _on_ball_stopped() -> void:
	_update_ball_visibility()


func _on_ball_reached_floor(_floor_index: int) -> void:
	_update_ball_visibility()


func _on_ball_reached_final_hole() -> void:
	_won = true
	_cancel_aim()


# --- alarm signal handlers (guards hook into these in Phase 8) ---------------

func _on_alarm_triggered(_floor_index: int) -> void:
	pass


func _on_alarm_searching(_floor_index: int, _last_known_position: Vector2i) -> void:
	pass


func _on_alarm_cleared(_floor_index: int) -> void:
	pass


# --- guard signal handlers --------------------------------------------------

func _on_guard_defeated(guard_id: int) -> void:
	for i in range(_guards.size() - 1, -1, -1):
		if _guards[i].id == guard_id:
			_guards[i].queue_free()
			_guards.remove_at(i)


func _on_guard_shot_ball(_guard_id: int, _hp_remaining: int) -> void:
	pass  # HUD/animation feedback hook


func _on_player_caught() -> void:
	if not _run_over():
		_caught = true
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
	elif _caught:
		status = "\n>>> CAUGHT BY A GUARD (R to play again)"
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

	_hud.text = "seed %d   HP %d/%d   shots %d   %s\nplayer floor %d/%d   ball floor %d   guards %d%s" % [
		_building.seed_used, _player_state.health, _player_state.max_health, _shots_taken, _alarm_text(pf),
		pf, _building.final_floor_index(), bf, _guards.size(), status,
	]


## Alarm status string for the player's current floor.
func _alarm_text(floor_index: int) -> String:
	match _detection.alarm.get_state(floor_index):
		AlarmState.State.ACTIVE:
			return "[!! ALARM: SPOTTED !!]"
		AlarmState.State.SEARCHING:
			return "[alarm: SEARCHING %.1fs]" % _detection.alarm.get_search_timer(floor_index)
		_:
			return "[alarm: clear]"


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_seed_counter += 1
			_regenerate(_seed_counter, false)
		KEY_ENTER, KEY_KP_ENTER:
			_regenerate(config.seed, false)
