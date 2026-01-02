extends Node2D

@export var drone: PackedScene

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	
	if rng.randi_range(1, 15) > 1:
		queue_free()
		return
	
	var new_drone = drone.instantiate()
	new_drone.global_position = global_position
	get_tree().current_scene.add_child(new_drone)
	new_drone.global_position = global_position
