extends State

@export var idle_state: State
@export var default_delta: Vector2 = Vector2(20,-20)

var ball_pos: Vector2
var target_pos: Vector2
var ball_vector: Vector2

func enter() -> void:
	super()
	parent.velocity.x = 0
	Global.player_shooting = true
	if parent.ball_body:
		ball_pos = parent.ball_body.global_position
		ajust_orientation(inputs, parent)
		var oriented_delta: Vector2 = Vector2(default_delta.x * parent.direction, default_delta.y)
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
	if parent.direction > 0:
		target_pos.x = max(ball_pos.x, target_pos.x)
	elif parent.direction < 0:
		target_pos.x = min(ball_pos.x, target_pos.x)

	ball_vector = target_pos - ball_pos
	print(ball_vector)
	SignalBus.shooting.emit(ball_vector, parent.ball_body, parent.global_position)
	
	return null
	
func ajust_orientation(inputs, parent) -> void:
	var difference: int = sign(ball_pos.x - parent.global_position.x)
	if difference != parent.direction:
		parent.scale.x =  -1
		parent.direction = parent.direction * -1
