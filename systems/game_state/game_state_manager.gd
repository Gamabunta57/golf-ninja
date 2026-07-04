class_name GameStateManager
extends RefCounted

## Single source of truth for run outcome (plan §7.3 #10, Phase 11). Godot-
## agnostic. Owns player health/shot accounting and resolves win/loss from
## events fed in by the scene layer — no scene script decides win/loss itself;
## they react to game_won / game_lost instead.
##
##   win  : the ball reaches the final floor's hole
##   loss : player health hits 0 (out of shots), or a guard touches the player

signal shot_taken(new_health: int)
signal game_won
signal game_lost(reason: String)

const REASON_CAUGHT := "caught"
const REASON_OUT_OF_SHOTS := "out_of_shots"

var player_state: PlayerState
var shots_fired: int = 0
var _over: bool = false
var _result: String = ""  # "", "won", or a loss reason


## Begins a run with a fresh player state.
func start(state: PlayerState) -> void:
	player_state = state
	shots_fired = 0
	_over = false
	_result = ""


func is_over() -> bool:
	return _over


func has_won() -> bool:
	return _result == "won"


func result() -> String:
	return _result


## The player took a shot: spend 1 health, and lose if that empties the budget.
func register_player_shot() -> void:
	if _over or player_state == null:
		return
	player_state.spend_health(1)
	shots_fired += 1
	shot_taken.emit(player_state.health)
	if player_state.is_out_of_health():
		_lose(REASON_OUT_OF_SHOTS)


func on_ball_reached_final_hole() -> void:
	if _over:
		return
	_over = true
	_result = "won"
	game_won.emit()


func on_player_caught() -> void:
	if _over:
		return
	_lose(REASON_CAUGHT)


func _lose(reason: String) -> void:
	_over = true
	_result = reason
	game_lost.emit(reason)
