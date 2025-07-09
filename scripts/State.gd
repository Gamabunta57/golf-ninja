class_name State
extends Node

var stateMachine: StateMachine

func setStateMachine(stateMachine: StateMachine) -> void:
	self.stateMachine = stateMachine

func onEnter() -> void:
	pass

func physics_process(delta: float) -> void:
	pass

func onExit() -> void:
	pass
