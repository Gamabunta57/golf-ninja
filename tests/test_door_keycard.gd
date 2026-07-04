class_name TestDoorKeycard
extends RefCounted

## Phase 10: runtime door/keycard enforcement — locked doors block until a
## sufficient card is held, unlocked doors are free, collection is idempotent,
## and a lower-level card can't open a higher-level door.

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_locked_then_collect(failures)
	_test_unlocked_always_passable(failures)
	_test_insufficient_level(failures)
	_test_collect_idempotent(failures)
	return failures


func _test_locked_then_collect(failures: Array[String]) -> void:
	var sys: DoorKeycardSystem = DoorKeycardSystem.new()
	var ps: PlayerState = PlayerState.new(10)
	var door: DoorData = DoorData.new(Vector2i(3, 3), 2)

	if sys.player_can_pass(door, ps):
		failures.append("locked: should not pass a level-2 door with no card")
		return
	var card: KeycardData = KeycardData.new(Vector2i(1, 1), 2, 0)
	sys.try_collect(card, ps)
	if not sys.player_can_pass(door, ps):
		failures.append("locked: should pass after collecting a level-2 card")
		return
	if not sys.open_if_allowed(door, ps) or not door.is_open:
		failures.append("locked: door should open once the card is held")


func _test_unlocked_always_passable(failures: Array[String]) -> void:
	var sys: DoorKeycardSystem = DoorKeycardSystem.new()
	var ps: PlayerState = PlayerState.new(10)
	var door: DoorData = DoorData.new(Vector2i(3, 3), 0)
	if not sys.player_can_pass(door, ps):
		failures.append("unlocked: level-0 door should always be passable")
	if not sys.open_if_allowed(door, ps):
		failures.append("unlocked: level-0 door should open")


func _test_insufficient_level(failures: Array[String]) -> void:
	var sys: DoorKeycardSystem = DoorKeycardSystem.new()
	var ps: PlayerState = PlayerState.new(10)
	sys.try_collect(KeycardData.new(Vector2i.ZERO, 1, 0), ps)
	var door: DoorData = DoorData.new(Vector2i(3, 3), 2)
	if sys.player_can_pass(door, ps):
		failures.append("insufficient: level-1 card should not open a level-2 door")
	# But a higher card should (level 3 >= 2).
	sys.try_collect(KeycardData.new(Vector2i.ZERO, 3, 0), ps)
	if not sys.player_can_pass(door, ps):
		failures.append("insufficient: level-3 card should open a level-2 door")


func _test_collect_idempotent(failures: Array[String]) -> void:
	var sys: DoorKeycardSystem = DoorKeycardSystem.new()
	var ps: PlayerState = PlayerState.new(10)
	var card: KeycardData = KeycardData.new(Vector2i.ZERO, 1, 0)
	if not sys.try_collect(card, ps):
		failures.append("idempotent: first collect should succeed")
	if sys.try_collect(card, ps):
		failures.append("idempotent: second collect of same card should be a no-op")
	if ps.keycards_held.count(1) != 1:
		failures.append("idempotent: inventory should hold level 1 exactly once")
