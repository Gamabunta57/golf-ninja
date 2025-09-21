class_name Prng extends Node

var _seed: int

"""
Initialise the random number generator given a seed
"""
func _init(baseSeed: int) -> void:
	_seed = baseSeed & 0x7FFFFFFFFFFFFFFF

func rand_float(x: int, y: int = 0, z: int = 0) -> float:
	var s = _seed
	for c in [x, y, z]:
		s = (s + c * 0x6E3779B97F4A7C15) & 0x7FFFFFFFFFFFFFFF
		var split = _splitmix64(s)
		s = split[0]
		s ^= split[1]
	var result = _splitmix64(s)[1]
	return (result >> 11) * (1.0 / (1 << 52))

func _splitmix64(x: int) -> Array[int]:
	x = (x + 0x6E3779B97F4A7C15) & 0x7FFFFFFFFFFFFFFF
	var z = x
	z = (z ^ (z >> 30)) * 0x7F58476D1CE4E5B9 & 0x7FFFFFFFFFFFFFFF
	z = (z ^ (z >> 27)) * 0x64D049BB133111EB & 0x7FFFFFFFFFFFFFFF
	z = z ^ (z >> 31)
	return [x, z & 0x7FFFFFFFFFFFFFFF]
