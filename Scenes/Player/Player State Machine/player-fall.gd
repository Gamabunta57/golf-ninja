extends State

@export var jump_state: State
@export var grappling_state: State
@export var idle_state: State
@export var move_state: State
@export var landing_state: State
@export var hurt_state: State
@export var slide_state: State
@export var coyote_timer: Timer

@export var landing_threshold: float = 1500
@export var hurt_threshold: float = 3000


@export var fall_gravity_multiplier: float = 1

var last_y_velocity: float = 0

func enter() -> void:
	super()
	coyote_timer.start()
	print("fall state")

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)

	if parent.velocity.y > 0:
		last_y_velocity = parent.velocity.y
	
	movements.flip_direction(inputs, parent)
	
	if Global.can_grapple and parent.velocity.y > 1 and not Global.grapple_cooldown_ongoing:
		return grappling_state

	parent.move_and_slide()
	
	if inputs.get_jump_input() and parent.should_coyote and parent.can_jump:
		return jump_state
	
	if not parent.should_coyote:
		parent.can_jump = false
	
	if parent.is_on_floor() and parent.get_floor_angle() > 1:
			return slide_state
	
	if parent.is_on_floor():
		
		if last_y_velocity < landing_threshold:
			if parent.velocity.x == 0:
				return idle_state
			else:
				return move_state
		else:
			if last_y_velocity > hurt_threshold:
				Global.player_health -= 1
				SignalBus.damage.emit(parent.global_position + Vector2(0,10))
				return hurt_state
			else:
				return landing_state
	
	return null

func exit() -> void:
	parent.should_coyote = false
	coyote_timer.stop()

func _on_damage_received() -> State:
	return hurt_state


func _on_coyote_time_timeout() -> void:
	parent.should_coyote = false
	coyote_timer.stop()
