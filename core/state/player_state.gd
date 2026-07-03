class_name PlayerState
extends RefCounted

## Mutable player state. Health doubles as the shot budget (GDD §3.2): each shot
## costs 1 point and reaching 0 ends the game.

var health: int = 0
var max_health: int = 0
var current_floor: int = 0
var grid_position: Vector2i = Vector2i.ZERO
var keycards_held: Array[int] = []  # access levels held


func _init(p_max_health: int = 0) -> void:
	max_health = p_max_health
	health = p_max_health


func spend_health(amount: int = 1) -> void:
	health = maxi(0, health - amount)


func is_out_of_health() -> bool:
	return health <= 0


func add_keycard(access_level: int) -> void:
	if not keycards_held.has(access_level):
		keycards_held.append(access_level)


## True if the player holds a card of at least `required_access_level`.
func has_access(required_access_level: int) -> bool:
	if required_access_level <= 0:
		return true
	for level in keycards_held:
		if level >= required_access_level:
			return true
	return false
