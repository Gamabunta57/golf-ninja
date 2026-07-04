extends SceneTree

## Headless test runner. Run with:
##   godot --headless --path <project> --script res://tests/run_tests.gd
## Exits with code 0 if all suites pass, 1 otherwise, so it is CI-friendly.

func _initialize() -> void:
	var suites: Array = [
		{"name": "PRNG determinism", "instance": TestPrngDeterminism.new()},
		{"name": "Map generation guarantees", "instance": TestMapGenerationGuarantees.new()},
		{"name": "Door/card reachability", "instance": TestDoorCardReachability.new()},
		{"name": "Elevator navigation", "instance": TestElevatorNavigation.new()},
		{"name": "Ball physics", "instance": TestBallPhysics.new()},
		{"name": "Detection & alarm", "instance": TestDetectionAlarm.new()},
		{"name": "Guard AI", "instance": TestGuardAi.new()},
		{"name": "Hiding", "instance": TestHiding.new()},
		{"name": "Door & keycard", "instance": TestDoorKeycard.new()},
	]

	var total_failures: int = 0
	print("\n=== Golf Ninja core/systems tests ===")
	for suite in suites:
		var failures: Array = suite["instance"].run()
		if failures.is_empty():
			print("  [PASS] %s" % suite["name"])
		else:
			total_failures += failures.size()
			print("  [FAIL] %s (%d failure(s)):" % [suite["name"], failures.size()])
			for f: String in failures:
				print("         - %s" % f)

	print("=====================================")
	if total_failures == 0:
		print("ALL TESTS PASSED\n")
		quit(0)
	else:
		print("%d FAILURE(S)\n" % total_failures)
		quit(1)
