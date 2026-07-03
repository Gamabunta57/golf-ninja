class_name DoorData
extends RefCounted

## A door on a floor. Locked doors require a keycard of at least
## `required_access_level`; a level of 0 means the door is always passable.

var position: Vector2i
var required_access_level: int = 0
var is_open: bool = false


func _init(p_position: Vector2i = Vector2i.ZERO, p_required_access_level: int = 0) -> void:
	position = p_position
	required_access_level = p_required_access_level


func is_locked() -> bool:
	return required_access_level > 0 and not is_open


## True if an inventory holding these access levels can open this door.
func can_be_opened_by(held_access_levels: Array[int]) -> bool:
	if required_access_level <= 0:
		return true
	for level in held_access_levels:
		if level >= required_access_level:
			return true
	return false
