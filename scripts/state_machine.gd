class_name StateMachine
extends Node

@export var initialState: State
var currentState: State

func _ready() -> void:
	var childenNode: Array[Node] = get_children()
	for child in childenNode:
		if (child is State):
			child.setStateMachine(self)

	currentState = initialState
	currentState.onEnter();

func _physics_process(delta: float) -> void:
	currentState.physics_process(delta)

func changeState(newState: State) -> void:
	currentState.onExit();
	currentState = newState
	currentState.onEnter()
