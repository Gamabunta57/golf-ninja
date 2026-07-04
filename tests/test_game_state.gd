class_name TestGameState
extends RefCounted

## Phase 11: GameStateManager resolves win/loss once and only once, spends health
## per shot, and reports the correct loss reason.

class Recorder:
	var won: int = 0
	var lost: int = 0
	var reason: String = ""
	var shots: Array[int] = []
	func on_won() -> void: won += 1
	func on_lost(r: String) -> void:
		lost += 1
		reason = r
	func on_shot(h: int) -> void: shots.append(h)


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_win(failures)
	_test_out_of_shots(failures)
	_test_caught(failures)
	_test_resolves_once(failures)
	return failures


func _make(hp: int, rec: Recorder) -> GameStateManager:
	var m: GameStateManager = GameStateManager.new()
	m.game_won.connect(rec.on_won)
	m.game_lost.connect(rec.on_lost)
	m.shot_taken.connect(rec.on_shot)
	m.start(PlayerState.new(hp))
	return m


func _test_win(failures: Array[String]) -> void:
	var rec: Recorder = Recorder.new()
	var m: GameStateManager = _make(10, rec)
	m.on_ball_reached_final_hole()
	if rec.won != 1 or not m.has_won() or not m.is_over():
		failures.append("win: reaching final hole should win exactly once")


func _test_out_of_shots(failures: Array[String]) -> void:
	var rec: Recorder = Recorder.new()
	var m: GameStateManager = _make(3, rec)
	m.register_player_shot()
	m.register_player_shot()
	if m.is_over():
		failures.append("out_of_shots: should not be over after 2 of 3 shots")
		return
	m.register_player_shot()  # third shot empties the budget
	if not m.is_over() or rec.lost != 1 or rec.reason != GameStateManager.REASON_OUT_OF_SHOTS:
		failures.append("out_of_shots: third shot should lose with out_of_shots reason")
		return
	if rec.shots != ([2, 1, 0] as Array[int]):
		failures.append("out_of_shots: shot_taken should report 2,1,0; got %s" % str(rec.shots))
	if m.shots_fired != 3:
		failures.append("out_of_shots: shots_fired should be 3")


func _test_caught(failures: Array[String]) -> void:
	var rec: Recorder = Recorder.new()
	var m: GameStateManager = _make(10, rec)
	m.on_player_caught()
	if not m.is_over() or rec.lost != 1 or rec.reason != GameStateManager.REASON_CAUGHT:
		failures.append("caught: should lose with caught reason")


func _test_resolves_once(failures: Array[String]) -> void:
	var rec: Recorder = Recorder.new()
	var m: GameStateManager = _make(10, rec)
	m.on_ball_reached_final_hole()  # win
	m.on_player_caught()            # ignored — already over
	m.register_player_shot()        # ignored
	if rec.won != 1 or rec.lost != 0:
		failures.append("resolves_once: post-win events must be ignored (won=%d lost=%d)" % [rec.won, rec.lost])
	if not rec.shots.is_empty():
		failures.append("resolves_once: no shot should register after the game is over")
