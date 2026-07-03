class_name PrngService
extends RefCounted

## Deterministic, Godot-independent pseudo-random number generator.
##
## Implements the SplitMix64 algorithm so that a given seed always reproduces
## the exact same output sequence, independent of Godot's global RNG. No code
## in this project should ever call the engine's global `randi()`/`randf()` —
## every system draws from a shared PrngService instance (or a named sub-stream
## derived from it) so generation stays fully reproducible for a seed.
##
## Named sub-streams (`get_stream("map_gen")`) let different systems consume
## randomness without perturbing each other's sequences: each sub-stream is a
## fresh PrngService seeded deterministically from the parent seed + name.

const _GOLDEN_GAMMA: int = -7046029254386353131  # 0x9E3779B97F4A7C15 as signed 64-bit
const _MIX_A: int = -4658895280553007687         # 0xBF58476D1CE4E5B9
const _MIX_B: int = -7723592293110705685         # 0x94D049BB133111EB
const _FNV_OFFSET: int = -3750763034362895579    # 0xCBF29CE484222325
const _FNV_PRIME: int = 1099511628211            # 0x00000100000001B3

var _seed: int
var _state: int


## Constructs a generator. Mirrors the GenerationConfig contract:
##   use_random_seed == true  -> derive a seed from a caller-provided entropy int
##   use_random_seed == false -> use `seed_value` verbatim
## `entropy` is only consulted when use_random_seed is true; callers that want
## nondeterminism must pass a varying value (e.g. Time.get_ticks_usec()) because
## this module deliberately never touches the engine clock or global RNG itself.
func _init(use_random_seed: bool = false, seed_value: int = 0, entropy: int = 0) -> void:
	if use_random_seed:
		_seed = _mix64(entropy ^ _GOLDEN_GAMMA)
	else:
		_seed = seed_value
	_state = _seed


## The seed this generator was initialised with (useful for logging/repro).
func get_seed() -> int:
	return _seed


## Resets the stream back to its initial seed.
func reset() -> void:
	_state = _seed


## Advances the internal state and returns the next raw 64-bit value (signed).
func next_raw() -> int:
	_state = _wrap_add(_state, _GOLDEN_GAMMA)
	return _mix64(_state)


## Returns a float in [0, 1).
##
## NOTE: `randf`/`randf_range`/`randi_range` share names with @GlobalScope
## utility functions. An UNQUALIFIED call to those names from inside this class
## binds to the (nondeterministic) global RNG, not to these methods — a subtle
## GDScript footgun. To stay deterministic, the public methods here only wrap
## private helpers (`_unit_float`/`_int_in_range`), and every internal caller
## uses those helpers, never the public names. External callers are safe because
## they always call qualified (`prng.randf()`), which resolves to these methods.
func randf() -> float:
	return _unit_float()


## Returns a float in [min_value, max_value).
func randf_range(min_value: float, max_value: float) -> float:
	return min_value + _unit_float() * (max_value - min_value)


## Returns an int in [min_value, max_value] inclusive on both ends.
func randi_range(min_value: int, max_value: int) -> int:
	return _int_in_range(min_value, max_value)


## Returns a valid random index into an array of `size` elements, or -1 if empty.
func pick_index(size: int) -> int:
	if size <= 0:
		return -1
	return _int_in_range(0, size - 1)


## Returns a random element from `array` (null if empty). Does not mutate.
func pick(array: Array) -> Variant:
	var idx: int = pick_index(array.size())
	if idx < 0:
		return null
	return array[idx]


## Returns true with probability `p` (clamped to [0, 1]).
func chance(p: float) -> bool:
	return _unit_float() < clampf(p, 0.0, 1.0)


## Returns a new independent PrngService whose seed is derived deterministically
## from this generator's seed and `stream_name`. Same parent seed + same name
## always yields the same sub-stream, regardless of how much randomness the
## parent has consumed — so systems can request their stream lazily.
func get_stream(stream_name: String) -> PrngService:
	var mixed: int = _mix64(_seed ^ _hash_string(stream_name))
	return PrngService.new(false, mixed)


## Fisher-Yates shuffle of `array` in place, using this stream.
func shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = _int_in_range(0, i)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp


# --- internal helpers -------------------------------------------------------

## Uniform double in [0, 1) from the top 53 bits of the next raw value.
func _unit_float() -> float:
	var bits: int = _shr(next_raw(), 11)
	return float(bits) / 9007199254740992.0  # 2^53


## Inclusive integer in [min_value, max_value].
func _int_in_range(min_value: int, max_value: int) -> int:
	if max_value <= min_value:
		return min_value
	var span: int = max_value - min_value + 1
	# Drop the sign bit to get a non-negative 63-bit magnitude, then reduce.
	var magnitude: int = _shr(next_raw(), 1)
	return min_value + (magnitude % span)

## SplitMix64 finaliser applied to a state value.
static func _mix64(z: int) -> int:
	z = _wrap_mul(z ^ _shr(z, 30), _MIX_A)
	z = _wrap_mul(z ^ _shr(z, 27), _MIX_B)
	return z ^ _shr(z, 31)


## Logical (unsigned) right shift for a signed 64-bit int, n in 1..63.
## GDScript's `>>` is arithmetic (sign-extending); we mask off the bits that
## would otherwise be filled with the sign bit so the result matches an
## unsigned shift. (1 << (64 - n)) - 1 produces the correct low-bit mask for
## every n in this range, including n == 1 where 1<<63 wraps to INT64_MIN and
## the subsequent -1 yields exactly 0x7FFF...FF.
static func _shr(x: int, n: int) -> int:
	if n <= 0:
		return x
	if n >= 64:
		return 0
	return (x >> n) & ((1 << (64 - n)) - 1)


## Deterministic 64-bit FNV-1a hash of a string (independent of Godot's hash()).
static func _hash_string(s: String) -> int:
	var h: int = _FNV_OFFSET
	for i in s.length():
		h = _wrap_mul(h ^ s.unicode_at(i), _FNV_PRIME)
	return h


# GDScript int arithmetic already wraps on overflow (two's complement 64-bit);
# these wrappers document intent and keep the algorithm readable.
static func _wrap_add(a: int, b: int) -> int:
	return a + b


static func _wrap_mul(a: int, b: int) -> int:
	return a * b
