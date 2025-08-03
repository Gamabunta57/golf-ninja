extends Control

var world: PackedScene = load("res://Scenes/world.tscn")

func _ready() -> void:
	Global.player_health = Global.player_max_health
	
func _process(delta):
	if Input.is_action_just_pressed("jump"):
		print("go back")
		get_tree().change_scene_to_packed(world)
