class_name State
extends Node

var stateMachine: StateMachine

func setStateMachine(newStateMachine: StateMachine) -> void:
	stateMachine = newStateMachine

func onEnter() -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func onExit() -> void:
	pass
