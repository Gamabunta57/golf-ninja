extends Node2D

@export var duration: float = 1.0        # seconds
@export var max_radius: float = 64.0     # final radius
@export var color: Color = Color(1, 1, 1, 0.1)
@export var line_thickness: float = 1.0  # outline width

var pos: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var active: bool = false

func _ready() -> void:
	SignalBus.ball_sound_emission.connect(_on_ball_sound_emission)

func _on_ball_sound_emission(pos) -> void:
	global_position = pos
	elapsed = 0.0
	active = true
	show()

func _process(delta: float) -> void:
	if not active:
		return

	elapsed += delta
	queue_redraw()

	if elapsed >= duration:
		active = false
		hide()

func _draw() -> void:
	if not active:
		return

	var t: float = clamp(elapsed / duration, 0.0, 1.0)
	var radius: float = lerp(0.0, max_radius, t)
	var alpha: float = lerp(color.a, 0.0, t)

	var c: Color = color
	c.a = alpha

	# draw arc approximates circle outline
	draw_arc(
		Vector2.ZERO,    # center
		radius,          # radius
		0,               # start angle
		TAU,             # full circle
		64,              # number of points (higher = smoother)
		c,
		line_thickness
	)
