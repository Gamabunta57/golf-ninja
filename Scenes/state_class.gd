class_name State
extends Node

#@export var animation_name: String

var stateMachine: StateMachine
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

# Hold a reference to the parent so that it can be controlled by the state
var parent: CharacterBody2D
var inputs
var movements


func enter() -> void:
	#parent.animations.play(animation_name)
	pass

func exit() -> void:
	pass

func process_input(_event: InputEvent) -> void:
	pass

func process_frame(_delta: float) -> void:
	pass

func process_physics(_delta: float) -> void:
	pass
	
func change_state(newState: State) -> void:
	stateMachine.change_state(newState)
