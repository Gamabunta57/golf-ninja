class_name TestGuardAi
extends RefCounted

## Phase 8: the guard FSM transitions correctly across alarm states and HP is
## only spent by shooting the ball. (Perception/movement live in the node and
## are exercised by play-testing; the decision core is pure and tested here.)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_transitions(failures)
	_test_hp(failures)
	return failures


func _test_transitions(failures: Array[String]) -> void:
	var sm: GuardStateMachine = GuardStateMachine.new(3)
	if sm.state != GuardStateMachine.State.PATROL:
		failures.append("transitions: initial state should be PATROL")
		return

	# Spotted -> CHASE.
	sm.update_state(AlarmState.State.ACTIVE, false)
	if sm.state != GuardStateMachine.State.CHASE:
		failures.append("transitions: ACTIVE should give CHASE")
		return

	# Lost sight -> SEARCH.
	sm.update_state(AlarmState.State.SEARCHING, false)
	if sm.state != GuardStateMachine.State.SEARCH:
		failures.append("transitions: SEARCHING should give SEARCH")
		return

	# Re-spotted -> CHASE.
	sm.update_state(AlarmState.State.ACTIVE, false)
	if sm.state != GuardStateMachine.State.CHASE:
		failures.append("transitions: re-spot during SEARCH should give CHASE")
		return

	# Alarm cleared while chasing -> RETURN_TO_PATROL, and stays until arrival.
	sm.update_state(AlarmState.State.SEARCHING, false)
	sm.update_state(AlarmState.State.INACTIVE, false)
	if sm.state != GuardStateMachine.State.RETURN_TO_PATROL:
		failures.append("transitions: INACTIVE after search should give RETURN_TO_PATROL")
		return
	sm.update_state(AlarmState.State.INACTIVE, false)
	if sm.state != GuardStateMachine.State.RETURN_TO_PATROL:
		failures.append("transitions: should stay RETURN until patrol reached")
		return
	sm.update_state(AlarmState.State.INACTIVE, true)
	if sm.state != GuardStateMachine.State.PATROL:
		failures.append("transitions: reaching patrol while INACTIVE should give PATROL")
		return

	# Patrolling with a clear alarm stays on patrol.
	sm.update_state(AlarmState.State.INACTIVE, false)
	if sm.state != GuardStateMachine.State.PATROL:
		failures.append("transitions: PATROL should persist while INACTIVE")


func _test_hp(failures: Array[String]) -> void:
	var sm: GuardStateMachine = GuardStateMachine.new(2)
	if not sm.is_alive() or sm.hp != 2:
		failures.append("hp: should start alive with configured HP")
		return
	sm.take_ball_shot()
	sm.take_ball_shot()
	if sm.is_alive() or sm.hp != 0:
		failures.append("hp: two shots should drop a 2-HP guard to 0 and dead")
		return
	sm.take_ball_shot()
	if sm.hp != 0:
		failures.append("hp: HP must not go negative")
