class_name KeycardData
extends RefCounted

## A keycard pickup placed on a floor. Collecting it grants `access_level`,
## which opens any door of matching-or-lower required access level.

var position: Vector2i
var access_level: int = 1
var floor_index: int = 0
var collected: bool = false


func _init(p_position: Vector2i = Vector2i.ZERO, p_access_level: int = 1, p_floor_index: int = 0) -> void:
	position = p_position
	access_level = p_access_level
	floor_index = p_floor_index
