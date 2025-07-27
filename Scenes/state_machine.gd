@icon("res://Icons/brain-circuit.png")
extends Node

@export var starting_state: State
#@export var movement: Node

var current_state: State

# Initialize the state machine by giving each child state a reference to the
# parent object it belongs to and enter the default starting_state.
func init(parent: CharacterBody2D, inputs: Node = null, movements: PlayerMovement = null) -> void:
	for child in get_children():
		child.parent = parent
	# Assign inputs, movements, and body only if they are provided (not null)
		if inputs != null:
			child.inputs = inputs

		if movements != null:
			child.movements = movements

	# Initialize to the default state
	change_state(starting_state)


# Change to the new state by first calling any exit logic on the current state.
func change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()

	current_state = new_state
	print(current_state)

	current_state.enter()
	
# Pass through functions for the Player to call,
# handling state changes as needed.
func process_physics(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)

func process_input(event: InputEvent) -> void:
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)

func process_frame(delta: float) -> void:
	var new_state = current_state.process_frame(delta)
	if new_state:
		change_state(new_state)
		
func on_body_entered(body: Node2D) -> void:
	var new_state = current_state.on_body_entered(body)
	if new_state:
		change_state(new_state)

func on_body_exited(body: Node2D) -> void:
	var new_state = current_state.on_body_exited(body)
	if new_state:
		change_state(new_state)

func on_area_entered(area: Area2D) -> void:
	var new_state = current_state.on_area_entered(area)
	if new_state:
		change_state(new_state)
