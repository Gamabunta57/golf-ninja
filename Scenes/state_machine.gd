@icon("res://Icons/brain-circuit.png")
class_name StateMachine
extends Node

@export var starting_state: State
#@export var movement: Node

var current_state: State

# Initialize the state machine by giving each child state a reference to the
# parent object it belongs to and enter the default starting_state.
func init(parent: CharacterBody2D, inputs, movements) -> void:
	for child in get_children():
		if (!child is State): continue

		child.parent = parent
		child.inputs = inputs
		child.movements = movements
		child.stateMachine = self
	# Initialize to the default state
	current_state = starting_state
	current_state.enter()

# Change to the new state by first calling any exit logic on the current state.
func change_state(new_state: State) -> void:
	current_state.exit()

	current_state = new_state
	print(current_state)

	current_state.enter()
	
# Pass through functions for the Player to call
func process_physics(delta: float) -> void:
	current_state.process_physics(delta)

func process_input(event: InputEvent) -> void:
	current_state.process_input(event)

func process_frame(delta: float) -> void:
	current_state.process_frame(delta)
