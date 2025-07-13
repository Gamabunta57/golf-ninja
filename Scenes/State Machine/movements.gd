@icon("res://Icons/move.png")
extends Node

@export var move_speed: float = 100
@export var max_speed: float = 60
@export var deceleration: float = 300

func horizontal_deceleration(velocityX: float, delta: float) -> float:
	velocityX = move_toward(velocityX, 0, deceleration * delta)
	return velocityX
	
func horizontal_movement(velocityX: float, delta: float, inputs, parent: CharacterBody2D) -> float:
	var x_input = inputs.get_x_input()
	var y_input = inputs.get_y_input()
	
	if sign(x_input) != sign(velocityX) and not is_zero_approx(velocityX):
		velocityX = horizontal_deceleration(velocityX, delta)
	else:
		velocityX += x_input * move_speed * delta
		velocityX = clamp(velocityX, -max_speed, max_speed)

	
	# Staircase collision
	if y_input < -0.5:
		parent.set_collision_mask_value(5, false)
		parent.set_collision_mask_value(3, true)
	elif y_input > 0.5:
		parent.set_collision_mask_value(4, true)
		parent.set_collision_mask_value(3, true)
	else:
		parent.set_collision_mask_value(5, true)
		parent.set_collision_mask_value(4, false)
		parent.set_collision_mask_value(3, false)
		
	return velocityX
