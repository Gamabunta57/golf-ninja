class_name State
extends Node

#@export var animation_name: String

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

# Hold a reference to the parent so that it can be controlled by the state
var parent: CharacterBody2D
var movement


func enter() -> void:
	#parent.animations.play(animation_name)
	pass

func exit() -> void:
	pass

func process_input(event: InputEvent) -> State:
	return null

func process_frame(delta: float) -> State:
	return null

func process_physics(delta: float) -> State:
	return null

#func get_x_input() -> float:
	#return movement.get_x_movement()
#
#func get_jump() -> bool:
	#return movement.get_jump()
