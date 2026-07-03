class_name TestPrngDeterminism
extends RefCounted

## Phase 1 acceptance: identical seeds reproduce identical output sequences
## across separate PrngService instances; different seeds diverge; ranges hold.

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_same_seed_same_sequence(failures)
	_test_streams_reproducible(failures)
	_test_different_seeds_diverge(failures)
	_test_ranges(failures)
	return failures


func _test_same_seed_same_sequence(failures: Array[String]) -> void:
	var a: PrngService = PrngService.new(false, 987654321)
	var b: PrngService = PrngService.new(false, 987654321)
	for i in 1000:
		if a.next_raw() != b.next_raw():
			failures.append("same_seed: raw sequence diverged at %d" % i)
			return
	var c: PrngService = PrngService.new(false, 42)
	var d: PrngService = PrngService.new(false, 42)
	for i in 500:
		if c.randf() != d.randf():
			failures.append("same_seed: randf diverged at %d" % i)
			return
		if c.randi_range(0, 1000) != d.randi_range(0, 1000):
			failures.append("same_seed: randi_range diverged at %d" % i)
			return


func _test_streams_reproducible(failures: Array[String]) -> void:
	var a: PrngService = PrngService.new(false, 555)
	var b: PrngService = PrngService.new(false, 555)
	# Consume different amounts from parents; sub-streams must still match
	# because they derive from the initial seed, not the current state.
	for _i in 37:
		a.next_raw()
	var sa: PrngService = a.get_stream("map_gen")
	var sb: PrngService = b.get_stream("map_gen")
	for i in 200:
		if sa.next_raw() != sb.next_raw():
			failures.append("streams: 'map_gen' diverged at %d" % i)
			return
	# Different stream names should (almost certainly) differ.
	var s1: PrngService = a.get_stream("cameras")
	var s2: PrngService = a.get_stream("guards")
	if s1.get_seed() == s2.get_seed():
		failures.append("streams: distinct names produced identical seed")


func _test_different_seeds_diverge(failures: Array[String]) -> void:
	var a: PrngService = PrngService.new(false, 1)
	var b: PrngService = PrngService.new(false, 2)
	var same: bool = true
	for _i in 10:
		if a.next_raw() != b.next_raw():
			same = false
			break
	if same:
		failures.append("different_seeds: seeds 1 and 2 produced identical first 10 values")


func _test_ranges(failures: Array[String]) -> void:
	var p: PrngService = PrngService.new(false, 7)
	for _i in 5000:
		var v: int = p.randi_range(3, 9)
		if v < 3 or v > 9:
			failures.append("ranges: randi_range out of bounds: %d" % v)
			return
		var f: float = p.randf()
		if f < 0.0 or f >= 1.0:
			failures.append("ranges: randf out of [0,1): %f" % f)
			return
	if p.pick_index(0) != -1:
		failures.append("ranges: pick_index(0) should be -1")
	var idx: int = p.pick_index(5)
	if idx < 0 or idx > 4:
		failures.append("ranges: pick_index(5) out of bounds: %d" % idx)
	# Regression guard: pick_index / chance / randf_range must be deterministic
	# too (they must not fall through to @GlobalScope's nondeterministic RNG).
	var q1: PrngService = PrngService.new(false, 24680)
	var q2: PrngService = PrngService.new(false, 24680)
	for i in 500:
		if q1.pick_index(196) != q2.pick_index(196):
			failures.append("determinism: pick_index diverged at %d" % i)
			return
		if q1.chance(0.5) != q2.chance(0.5):
			failures.append("determinism: chance diverged at %d" % i)
			return
		if q1.randf_range(-5.0, 5.0) != q2.randf_range(-5.0, 5.0):
			failures.append("determinism: randf_range diverged at %d" % i)
			return
