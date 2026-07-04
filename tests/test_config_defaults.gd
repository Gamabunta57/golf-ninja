class_name TestConfigDefaults
extends RefCounted

## Phase 12: guards the designer contract — every tunable from the GDD/plan §2
## table exists on GenerationConfig with the documented default, and the shipped
## generation_config.tres asset loads and matches. If a knob is renamed/dropped,
## this fails loudly.

const CONFIG_PATH := "res://config/generation_config.tres"


func run() -> Array[String]:
	var failures: Array[String] = []
	_check_defaults("code default", GenerationConfig.new(), failures)
	var loaded: Resource = load(CONFIG_PATH)
	if loaded == null or not (loaded is GenerationConfig):
		failures.append("asset: %s did not load as a GenerationConfig" % CONFIG_PATH)
	else:
		_check_defaults("asset", loaded, failures)
	_check_curve_fallback(failures)
	return failures


func _check_defaults(label: String, c: GenerationConfig, failures: Array[String]) -> void:
	var expected: Dictionary = {
		"player_health": 10,
		"guard_health": 3,
		"floor_size": Vector2i(16, 16),
		"floor_count": 5,
		"conduits_per_floor_range": Vector2i(1, 3),
		"max_conduit_drop_distance": 5,
		"elevators_per_floor_range": Vector2i(1, 2),
		"locked_doors_per_floor_range": Vector2i(0, 2),
		"cameras_per_floor_range": Vector2i(0, 2),
		"guards_per_floor_range": Vector2i(0, 3),
		"lockers_per_floor_range": Vector2i(1, 3),
		"max_keycard_access_level": 2,
		"ball_jam_radius_cells": 2,
		"camera_jam_duration_sec": 3.0,
		"alarm_search_duration_sec": 8.0,
		"guard_fov_angle_degrees": 90.0,
		"guard_fov_range_cells": 4,
		"camera_fov_range_cells": 4,
		"add_wall_border": true,
		"use_random_seed": false,
	}
	for key: String in expected:
		var actual: Variant = c.get(key)
		if actual == null and not (key in c):
			failures.append("%s: missing config field '%s'" % [label, key])
			continue
		if actual != expected[key]:
			failures.append("%s: '%s' = %s, expected %s" % [label, key, str(actual), str(expected[key])])


func _check_curve_fallback(failures: Array[String]) -> void:
	var c: GenerationConfig = GenerationConfig.new()
	# Null curves must behave as a flat 1.0 multiplier at any floor.
	if not is_equal_approx(c.guard_density_at(0), 1.0) or not is_equal_approx(c.camera_density_at(3), 1.0):
		failures.append("curve: null depth curve should sample to 1.0")
