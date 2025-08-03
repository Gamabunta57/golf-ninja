extends RayCast2D

#@onready var parent = get_parent() 

var tracking_player : bool = false
var target : CharacterBody2D

func _process(delta: float) -> void:	
	if tracking_player:
		target_position = to_local(target.global_position - Vector2(0.0, 25.0))

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		tracking_player = true
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		tracking_player = false
