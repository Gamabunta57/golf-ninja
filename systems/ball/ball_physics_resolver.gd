class_name BallPhysicsResolver
extends RefCounted

## Godot-agnostic mini-golf physics for the ball (plan §7.3 #3). Operates in
## CELL space: BallState.grid_position and velocity are in floor cells (and
## cells/sec), so the resolver only needs the FloorData walkable grid, never a
## physics server. Renderers multiply by cell size to draw.
##
## step() advances one frame with internal substepping (no tunnelling through
## thin walls or over holes) and reports the first significant event. Shot
## application is exposed as apply_shot()/apply_max_shot() so the player's aim
## controller AND guards (Phase 8, always max power) share the same launch code.

const MIN_LAUNCH_SPEED: float = 7.0    # cells/sec at power 0
const MAX_LAUNCH_SPEED: float = 22.0   # cells/sec at power 1
const FRICTION_DECEL: float = 11.0     # cells/sec^2
const STOP_SPEED: float = 0.6          # below this the ball is considered stopped
const BOUNCE_DAMP: float = 0.72        # speed retained per wall bounce
const MAX_SUBSTEP_CELLS: float = 0.2   # max distance advanced per integration substep

# step() event strings.
const EVENT_IDLE := "idle"
const EVENT_ROLLING := "rolling"
const EVENT_STOPPED := "stopped"
const EVENT_HOLE := "hole"
const EVENT_CONDUIT := "conduit"


## Speed (cells/sec) produced by a normalised power in [0, 1].
func launch_speed(power: float) -> float:
	return lerpf(MIN_LAUNCH_SPEED, MAX_LAUNCH_SPEED, clampf(power, 0.0, 1.0))


## Applies a shot: sets the ball's velocity from a direction + power.
func apply_shot(ball: BallState, direction: Vector2, power: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	ball.velocity = direction.normalized() * launch_speed(power)
	ball.is_in_transit = false


## Guards (and anything firing "as far as possible") use this — always power 1.
func apply_max_shot(ball: BallState, direction: Vector2) -> void:
	apply_shot(ball, direction, 1.0)


## Advances the ball one frame. Returns { "event": <one of EVENT_*>,
## "conduit": ConduitLink|null }. On HOLE/CONDUIT the caller performs the floor
## transition; on STOPPED the ball is at rest and can be shot again.
func step(ball: BallState, floor_data: FloorData, delta: float) -> Dictionary:
	if ball.is_in_transit or ball.velocity.length_squared() < 0.0001:
		return {"event": EVENT_IDLE, "conduit": null}

	var remaining: float = delta
	while remaining > 0.0:
		var speed: float = ball.velocity.length()
		if speed <= 0.0:
			break
		var dt: float = minf(remaining, MAX_SUBSTEP_CELLS / speed)
		_move_axis_resolved(ball, floor_data, dt)

		# Landing check: falling into the hole or entering a conduit mouth.
		var cell: Vector2i = ball.cell()
		if cell == floor_data.hole_position:
			ball.velocity = Vector2.ZERO
			return {"event": EVENT_HOLE, "conduit": null}
		for conduit: ConduitLink in floor_data.conduits:
			if cell == conduit.origin_position:
				ball.velocity = Vector2.ZERO
				return {"event": EVENT_CONDUIT, "conduit": conduit}

		# Friction.
		var new_speed: float = ball.velocity.length() - FRICTION_DECEL * dt
		if new_speed <= STOP_SPEED:
			ball.velocity = Vector2.ZERO
			return {"event": EVENT_STOPPED, "conduit": null}
		ball.velocity = ball.velocity.normalized() * new_speed

		remaining -= dt

	return {"event": EVENT_ROLLING, "conduit": null}


## Jams any camera within `jam_radius_cells` of the ball until now_ms+duration
## (GDD §4.1). Kept here so ball proximity is resolved with the physics; the
## visible effect on detection lands in Phase 7.
func apply_camera_jam(ball: BallState, floor_data: FloorData, jam_radius_cells: float, now_ms: int, duration_ms: int) -> void:
	for cam: CameraZoneData in floor_data.camera_zones:
		if ball.grid_position.distance_to(Vector2(cam.position)) <= jam_radius_cells:
			cam.jammed_until_ms = now_ms + duration_ms


# --- internal ---------------------------------------------------------------

## Moves the ball by `dt`, resolving each axis against walls independently and
## reflecting (with damping) on the blocked axis.
func _move_axis_resolved(ball: BallState, floor_data: FloorData, dt: float) -> void:
	var pos: Vector2 = ball.grid_position
	var nx: float = pos.x + ball.velocity.x * dt
	if _point_walkable(floor_data, nx, pos.y):
		pos.x = nx
	else:
		ball.velocity.x = -ball.velocity.x * BOUNCE_DAMP
	var ny: float = pos.y + ball.velocity.y * dt
	if _point_walkable(floor_data, pos.x, ny):
		pos.y = ny
	else:
		ball.velocity.y = -ball.velocity.y * BOUNCE_DAMP
	ball.grid_position = pos


func _point_walkable(floor_data: FloorData, fx: float, fy: float) -> bool:
	return floor_data.is_walkable(Vector2i(floori(fx), floori(fy)))
