class_name GuardStateMachine
extends RefCounted

## Pure decision core for a guard (plan §7.3 #6, Phase 8). Holds the guard's FSM
## state and HP; the Guard node handles perception, movement, and shooting and
## feeds the current floor alarm state in each frame. Kept Godot-free so the
## transition table is unit-testable.
##
##   PATROL --alarm ACTIVE--------> CHASE
##   CHASE  --alarm SEARCHING-----> SEARCH        (converge on last known pos)
##   SEARCH --alarm ACTIVE--------> CHASE         (player re-spotted)
##   any    --alarm INACTIVE------> RETURN_TO_PATROL --reached path--> PATROL
##
## The SHOOT_BALL behaviour (GDD §4.4) is an interrupt handled by the node, not a
## persistent FSM state: the guard pauses, fires, spends 1 HP, then resumes
## whatever state this machine is in.

enum State { PATROL, CHASE, SEARCH, RETURN_TO_PATROL }

var state: State = State.PATROL
var hp: int


func _init(p_hp: int = 3) -> void:
	hp = p_hp


func is_alive() -> bool:
	return hp > 0


## Spends 1 HP for firing the ball (the only way guards lose HP in v1).
func take_ball_shot() -> void:
	hp = maxi(0, hp - 1)


## Advances the FSM from the current floor alarm state. `reached_patrol` is true
## when the guard has arrived back on its patrol path (only consulted while
## returning). Returns the resulting state.
func update_state(alarm_state: AlarmState.State, reached_patrol: bool) -> State:
	match alarm_state:
		AlarmState.State.ACTIVE:
			state = State.CHASE
		AlarmState.State.SEARCHING:
			state = State.SEARCH
		AlarmState.State.INACTIVE:
			if state == State.CHASE or state == State.SEARCH:
				state = State.RETURN_TO_PATROL
			elif state == State.RETURN_TO_PATROL and reached_patrol:
				state = State.PATROL
	return state
