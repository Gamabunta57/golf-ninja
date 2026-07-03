class_name ShotAimUI
extends Node2D

## World-space aim indicator (plan Phase 6). Draws an arrow from the ball in the
## aim direction whose length + colour reflect power. Purely presentational: the
## root feeds it the ball position, angle, and power from ShotAimController.

const MIN_LEN: float = 24.0
const MAX_LEN: float = 150.0
const COL_LOW: Color = Color(0.4, 0.9, 0.4)
const COL_HIGH: Color = Color(0.95, 0.4, 0.3)

var _ball_pos: Vector2
var _angle: float
var _power: float
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	visible = false


func show_aim(ball_world_pos: Vector2, angle: float, power: float) -> void:
	_ball_pos = ball_world_pos
	_angle = angle
	_power = power
	visible = true
	queue_redraw()


func hide_aim() -> void:
	visible = false
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var dir: Vector2 = Vector2.from_angle(_angle)
	var length: float = lerpf(MIN_LEN, MAX_LEN, _power)
	var tip: Vector2 = _ball_pos + dir * length
	var col: Color = COL_LOW.lerp(COL_HIGH, _power)

	draw_line(_ball_pos, tip, col, 3.0)
	# Arrowhead.
	var back: Vector2 = dir.rotated(PI * 0.85) * 12.0
	var back2: Vector2 = dir.rotated(-PI * 0.85) * 12.0
	draw_line(tip, tip + back, col, 3.0)
	draw_line(tip, tip + back2, col, 3.0)
	# Power readout near the ball.
	if _font != null:
		draw_string(_font, _ball_pos + Vector2(12, -12), "power %d%%" % roundi(_power * 100.0),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
