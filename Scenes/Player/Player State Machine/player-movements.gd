@icon("res://Icons/move.png")
class_name PlayerMovement
extends Node

#@export var move_speed: float = 1200
#@export var max_speed: float = 800

	
func horizontal_movement(velocityX: float, deceleration: float, move_speed: float, max_speed: float, delta: float, inputs) -> float:
	var x_input = inputs.get_x_input()
	#var y_input = inputs.get_y_input()
	
	if sign(x_input) != sign(velocityX) and not is_zero_approx(velocityX):
		velocityX = move_toward(velocityX, 0, deceleration * delta)
	else:
		velocityX += x_input * move_speed * delta
		velocityX = clamp(velocityX, -max_speed, max_speed)
		
	return velocityX

func flip_direction(inputs) -> void:
	if inputs.get_x_input() != 0:
		Global.direction = sign(inputs.get_x_input())
