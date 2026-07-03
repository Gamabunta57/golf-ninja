class_name AlarmState
extends RefCounted

## Per-floor alarm bookkeeping (GDD §3.3, §7.2). The alarm is floor-local and
## has three states. The detection resolver owns the transitions; this class is
## the data + small query/mutation helpers so the transition logic reads cleanly.
##
##   INACTIVE  -> nothing detected
##   ACTIVE    -> player currently in a camera zone or guard FOV on this floor
##   SEARCHING -> player was seen but broke line of sight; guards search the last
##                known position until the timer expires or the player is re-seen

enum State { INACTIVE, ACTIVE, SEARCHING }

var state_by_floor: Dictionary = {}                # floor_index:int -> State
var last_known_position_by_floor: Dictionary = {}  # floor_index:int -> Vector2i
var search_timer_by_floor: Dictionary = {}         # floor_index:int -> float (seconds)
var alerted_guards_by_floor: Dictionary = {}       # floor_index:int -> Array[int] (guard ids)


func get_state(floor_index: int) -> State:
	return state_by_floor.get(floor_index, State.INACTIVE)


func is_active(floor_index: int) -> bool:
	return get_state(floor_index) == State.ACTIVE


func is_searching(floor_index: int) -> bool:
	return get_state(floor_index) == State.SEARCHING


func get_last_known_position(floor_index: int) -> Vector2i:
	return last_known_position_by_floor.get(floor_index, Vector2i.ZERO)


func get_search_timer(floor_index: int) -> float:
	return search_timer_by_floor.get(floor_index, 0.0)


func get_alerted_guards(floor_index: int) -> Array:
	return alerted_guards_by_floor.get(floor_index, [])


## Sets a floor to ACTIVE, recording the currently observed player position.
func set_active(floor_index: int, player_position: Vector2i) -> void:
	state_by_floor[floor_index] = State.ACTIVE
	last_known_position_by_floor[floor_index] = player_position
	search_timer_by_floor[floor_index] = 0.0


## Moves a floor from ACTIVE to SEARCHING, freezing the last known position and
## starting the countdown from `duration` seconds.
func set_searching(floor_index: int, last_position: Vector2i, duration: float) -> void:
	state_by_floor[floor_index] = State.SEARCHING
	last_known_position_by_floor[floor_index] = last_position
	search_timer_by_floor[floor_index] = duration


## Returns a floor to INACTIVE and clears its search bookkeeping.
func set_inactive(floor_index: int) -> void:
	state_by_floor[floor_index] = State.INACTIVE
	last_known_position_by_floor.erase(floor_index)
	search_timer_by_floor[floor_index] = 0.0
	alerted_guards_by_floor[floor_index] = []


## Decrements a floor's SEARCHING timer; returns true once it hits 0 (the caller
## is then responsible for the SEARCHING -> INACTIVE transition + signal).
func tick_search(floor_index: int, delta: float) -> bool:
	if get_state(floor_index) != State.SEARCHING:
		return false
	var remaining: float = get_search_timer(floor_index) - delta
	search_timer_by_floor[floor_index] = maxf(0.0, remaining)
	return remaining <= 0.0
