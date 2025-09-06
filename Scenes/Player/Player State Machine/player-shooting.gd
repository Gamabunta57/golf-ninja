extends State

@export var idle_state: State
@export var move_state: State
@export var default_delta: Vector2 = Vector2(20,-20)

var ball_pos: Vector2
var target_pos: Vector2
var ball_vector: Vector2 = Vector2.ZERO

func enter() -> void:
	super()
	parent.velocity.x = 0
	parent.cancel_shooting = false
	Global.player_shooting = true
	if parent.ball_body:
		ball_pos = parent.ball_body.global_position
		var oriented_delta: Vector2 = Vector2(default_delta.x * parent.last_direction, default_delta.y)
		target_pos = ball_pos + oriented_delta

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
	parent.direction = sign(ball_vector.x)
		
	# cancel the shooting if press jump
	if inputs.get_jump_input():
		parent.cancel_shooting = true
		Global.player_shooting = false
		ball_vector = Vector2.ZERO
		
	SignalBus.shooting.emit(ball_vector, parent.ball_body, parent.global_position)
	
	if parent.cancel_shooting:
		if inputs.get_x_input() != 0:
			return move_state
		else:
			return idle_state
	
	return null
