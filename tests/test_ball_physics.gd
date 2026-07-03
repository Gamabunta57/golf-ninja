class_name TestBallPhysics
extends RefCounted

## Phase 6: the ball physics resolver is deterministic, never tunnels through
## walls, always terminates in a hole/conduit/stop, and reliably detects a hole
## it rolls over. (Godot-agnostic logic, so fully headless-testable.)

const DELTA: float = 1.0 / 60.0
const MAX_FRAMES: int = 2000


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_max_shot_speed(failures)
	_test_deterministic(failures)
	_test_no_tunnel_and_terminates(failures)
	_test_hole_capture(failures)
	return failures


func _test_max_shot_speed(failures: Array[String]) -> void:
	var resolver: BallPhysicsResolver = BallPhysicsResolver.new()
	var ball: BallState = BallState.new(0, Vector2(2.5, 1.5))
	resolver.apply_max_shot(ball, Vector2(1, 0))
	if not is_equal_approx(ball.velocity.length(), BallPhysicsResolver.MAX_LAUNCH_SPEED):
		failures.append("apply_max_shot: speed %f != MAX %f" % [ball.velocity.length(), BallPhysicsResolver.MAX_LAUNCH_SPEED])


func _test_deterministic(failures: Array[String]) -> void:
	var fd: FloorData = _clear_floor(12, 12)
	fd.hole_position = Vector2i(-1, -1)  # unreachable, so it just rolls & stops
	var a: BallState = BallState.new(0, Vector2(3.5, 3.5))
	var b: BallState = BallState.new(0, Vector2(3.5, 3.5))
	var ra: BallPhysicsResolver = BallPhysicsResolver.new()
	var rb: BallPhysicsResolver = BallPhysicsResolver.new()
	ra.apply_shot(a, Vector2(0.7, 0.3), 0.9)
	rb.apply_shot(b, Vector2(0.7, 0.3), 0.9)
	for i in MAX_FRAMES:
		ra.step(a, fd, DELTA)
		rb.step(b, fd, DELTA)
		if a.grid_position != b.grid_position or a.velocity != b.velocity:
			failures.append("determinism: trajectories diverged at frame %d" % i)
			return
		if not a.is_moving():
			break


func _test_no_tunnel_and_terminates(failures: Array[String]) -> void:
	var generator: MapGenerator = MapGenerator.new()
	var resolver: BallPhysicsResolver = BallPhysicsResolver.new()
	for s in 30:
		var config: GenerationConfig = GenerationConfig.new()
		config.seed = s
		var building: BuildingData = generator.generate(config, config.make_prng())
		var fd: FloorData = building.get_floor(0)
		var dir_stream: PrngService = config.make_prng().get_stream("test_dir_%d" % s)
		var ball: BallState = BallState.new(0, Vector2(building.ball_start_cell) + Vector2(0.5, 0.5))
		resolver.apply_shot(ball, Vector2(dir_stream.randf_range(-1, 1), dir_stream.randf_range(-1, 1)), 1.0)

		var terminated: bool = false
		for _f in MAX_FRAMES:
			var result: Dictionary = resolver.step(ball, fd, DELTA)
			# Ball must never occupy a wall cell.
			if not fd.is_walkable(ball.cell()):
				failures.append("seed %d: ball tunnelled into wall at %s" % [s, ball.cell()])
				return
			if result["event"] != BallPhysicsResolver.EVENT_ROLLING:
				terminated = true
				break
		if not terminated:
			failures.append("seed %d: ball never terminated (possible infinite roll)" % s)
			return


func _test_hole_capture(failures: Array[String]) -> void:
	# Open corridor; hole straight ahead of the ball.
	var fd: FloorData = _clear_floor(14, 3)
	fd.hole_position = Vector2i(9, 1)
	var ball: BallState = BallState.new(0, Vector2(2.5, 1.5))
	var resolver: BallPhysicsResolver = BallPhysicsResolver.new()
	resolver.apply_shot(ball, Vector2(1, 0), 1.0)
	var got_hole: bool = false
	for _f in MAX_FRAMES:
		var result: Dictionary = resolver.step(ball, fd, DELTA)
		if result["event"] == BallPhysicsResolver.EVENT_HOLE:
			got_hole = true
			break
		if result["event"] == BallPhysicsResolver.EVENT_STOPPED:
			break
	if not got_hole:
		failures.append("hole_capture: ball did not fall into the hole it rolled over")


## A floor whose interior is all walkable, bordered by walls.
func _clear_floor(w: int, h: int) -> FloorData:
	var fd: FloorData = FloorData.new(0, w, h)
	for x in w:
		fd.set_walkable(Vector2i(x, 0), false)
		fd.set_walkable(Vector2i(x, h - 1), false)
	for y in h:
		fd.set_walkable(Vector2i(0, y), false)
		fd.set_walkable(Vector2i(w - 1, y), false)
	return fd
