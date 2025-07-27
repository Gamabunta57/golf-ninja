extends Control

var world: PackedScene = load("res://Scenes/world.tscn")

func _process(delta):
	if Input.is_action_just_pressed("jump"):
		print("go back")
		get_tree().change_scene_to_packed(world)
