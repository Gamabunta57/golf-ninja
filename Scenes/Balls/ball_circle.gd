extends RigidBody2D

var shoot_vector: Vector2 = Vector2.ZERO
var limited_shoot_vector: Vector2 = Vector2.ZERO

var ball_body: RigidBody2D

@export var default_delta: Vector2 = Vector2(20, -20)
@export var max_force: float = 100
@export var strengh: float = 8


func _ready() -> void:
	SignalBus.shooting.connect(_set_vector_and_body)

func _set_vector_and_body(vector: Vector2, body: RigidBody2D) -> void:
	ball_body = body
	if ball_body == self:
		shoot_vector = vector + default_delta
		queue_redraw()
	

func _physics_process(delta: float) -> void:
	if ball_body == self:
		if Global.player_shooting:
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			limited_shoot_vector = shoot_vector.limit_length(max_force)
			
		if Global.shooting_action:
			Global.shooting_action = false
			apply_impulse(limited_shoot_vector * strengh)
			shoot_vector = Vector2.ZERO
			queue_redraw()

func _draw() -> void:
	if Global.player_shooting and shoot_vector != Vector2.ZERO:
		draw_line(Vector2.ZERO, to_local(global_position + limited_shoot_vector), Color.WHITE, 2.0)
