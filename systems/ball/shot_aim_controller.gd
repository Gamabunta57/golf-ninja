class_name ShotAimController
extends RefCounted

## Aim state for a player shot (plan §7.3 #4). Pure logic: it tracks the aim
## angle + power while active and adjusts them from abstract movement input. The
## caller (scene) drives it with PlayerIntent, renders it via ShotAimUI, and on
## confirm applies the shot through BallPhysicsResolver and spends 1 health.

const ROTATE_SPEED: float = 2.6   # radians/sec from horizontal input
const POWER_SPEED: float = 0.9    # power units/sec from vertical input
const MIN_POWER: float = 0.05     # below this, confirming does nothing

var active: bool = false
var angle: float = 0.0            # radians
var power: float = 0.5            # [0, 1]


## Opens the aim UI, seeding the aim angle (e.g. toward the floor hole).
func begin(initial_angle: float = 0.0) -> void:
	active = true
	angle = initial_angle
	power = 0.5


func cancel() -> void:
	active = false


## Adjusts aim from movement input: horizontal rotates, vertical (up = more)
## sets power.
func update(move: Vector2, delta: float) -> void:
	if not active:
		return
	angle = wrapf(angle + move.x * ROTATE_SPEED * delta, -PI, PI)
	power = clampf(power - move.y * POWER_SPEED * delta, 0.0, 1.0)


func aim_direction() -> Vector2:
	return Vector2.from_angle(angle)


## Whether a confirm would actually launch the ball.
func can_fire() -> bool:
	return active and power >= MIN_POWER
