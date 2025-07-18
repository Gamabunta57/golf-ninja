@icon("res://Icons/move.png")
class_name PlayerMovement
extends Node

@export var move_speed: float = 800
@export var max_speed: float = 400
@export var deceleration: float = 1500
@export var stairs_threshold: float = 0.5


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
	if y_input >= -stairs_threshold and y_input <= stairs_threshold :
		parent.set_collision_mask_value(3, true)
		parent.set_collision_mask_value(4, false)
	
	if parent.get_floor_angle() != 0 :
		parent.set_collision_mask_value(4, true)
	else:
		parent.set_collision_mask_value(4, false)
		
	if y_input < -stairs_threshold:
		parent.set_collision_mask_value(3, false)
		
	if y_input > stairs_threshold:
		parent.set_collision_mask_value(4, true)
		
	return velocityX
