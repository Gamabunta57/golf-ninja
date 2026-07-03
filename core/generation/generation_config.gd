class_name GenerationConfig
extends Resource

## Designer-facing tuning knobs for level generation (GDD §7.4, plan §2/§6).
## This resource + a PRNG seed are the ONLY inputs the MapGenerator needs, so
## generation stays deterministic and fully inspectable in the editor.
##
## Ranges are expressed as Vector2i(min, max) and sampled inclusively. Values
## that should scale with floor depth are exposed as optional Curve resources
## sampled at t = floor_index / (floor_count - 1); a null/empty curve is treated
## as a flat multiplier of 1.0 so defaults reproduce the flat table values.

@export_group("Determinism")
## When true, the generator derives a seed from supplied entropy (nondeterministic
## across runs). When false, `seed` is used verbatim for reproducible levels.
@export var use_random_seed: bool = false
@export var seed: int = 0

@export_group("Health")
@export var player_health: int = 10
## Single global HP shared by every guard in v1 (GDD §7.5).
@export var guard_health: int = 3

@export_group("Building")
@export var floor_size: Vector2i = Vector2i(16, 16)
@export var floor_count: int = 5
## Adds a one-cell non-walkable wall around every floor as a post-process.
@export var add_wall_border: bool = true

@export_group("Ball Routing")
@export var conduits_per_floor_range: Vector2i = Vector2i(1, 3)
## Conduits are downward-only and may skip at most this many floors (GDD §6.3).
@export var max_conduit_drop_distance: int = 5

@export_group("Navigation")
@export var elevators_per_floor_range: Vector2i = Vector2i(1, 2)

@export_group("Access")
@export var locked_doors_per_floor_range: Vector2i = Vector2i(0, 2)
## Highest keycard access level the generator will assign to a door/card.
@export var max_keycard_access_level: int = 2

@export_group("Stealth")
@export var cameras_per_floor_range: Vector2i = Vector2i(0, 2)
@export var guards_per_floor_range: Vector2i = Vector2i(0, 3)
@export var ball_jam_radius_cells: int = 2
@export var camera_jam_duration_sec: float = 3.0
@export var alarm_search_duration_sec: float = 8.0
@export var guard_fov_angle_degrees: float = 90.0
@export var guard_fov_range_cells: int = 4
@export var camera_fov_range_cells: int = 4

@export_group("Depth Scaling")
## Multiplier applied to the per-floor guard count, sampled by floor depth.
## Leave empty for a flat 1.0 (default). Shape it to put more guards on lower
## floors, e.g. rising from 0.5 at the top to 1.5 at the bottom.
@export var guard_density_curve: Curve
@export var camera_density_curve: Curve


## Builds the PRNG this config implies. `entropy` is only used when
## use_random_seed is true (callers pass a varying value there).
func make_prng(entropy: int = 0) -> PrngService:
	return PrngService.new(use_random_seed, seed, entropy)


func floor_width() -> int:
	return floor_size.x


func floor_height() -> int:
	return floor_size.y


## Samples a depth-scaling curve at floor `floor_index`, returning a multiplier.
## Returns 1.0 when the curve is null or has no points.
func sample_curve(curve: Curve, floor_index: int) -> float:
	if curve == null or curve.point_count == 0:
		return 1.0
	var t: float = 0.0
	if floor_count > 1:
		t = float(floor_index) / float(floor_count - 1)
	return curve.sample_baked(t)


func guard_density_at(floor_index: int) -> float:
	return sample_curve(guard_density_curve, floor_index)


func camera_density_at(floor_index: int) -> float:
	return sample_curve(camera_density_curve, floor_index)
