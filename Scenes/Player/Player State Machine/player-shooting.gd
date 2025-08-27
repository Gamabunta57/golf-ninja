extends State

@export var idle_state: State
@export var default_delta: Vector2 = Vector2(-10,10)

var ball_pos: Vector2
var target_pos: Vector2
var ball_vector: Vector2

func enter() -> void:
	super()
	parent.velocity.x = 0
	Global.player_shooting = true
	if parent.ball_body:
		ball_pos = parent.ball_body.global_position
		target_pos = ball_pos + default_delta

func process_input(event: InputEvent) -> State:
		
	if not inputs.get_shooting_input():
		Global.shooting_action = true
		Global.player_shooting = false
		return idle_state
		
	if not parent.ball_body:
		Global.player_shooting = false
		return idle_state
	
	return null

func process_physics(delta: float) -> State:
	var x_input = inputs.get_x_input()
	var y_input = inputs.get_y_input()
	
	target_pos.x += x_input
	target_pos.y -= y_input
	
	ball_vector = target_pos - ball_pos
	
	SignalBus.shooting.emit(ball_vector, parent.ball_body, parent.global_position)
	
	return null
