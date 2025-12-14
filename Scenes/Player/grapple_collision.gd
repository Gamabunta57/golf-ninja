extends RayCast2D

var direction :Vector2 = Vector2(0,1)

func _process(_delta: float) -> void:
	target_position = direction * Global.grapple_distance
