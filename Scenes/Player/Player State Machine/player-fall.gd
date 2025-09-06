extends State

@export var jump_state: State
@export var idle_state: State
@export var move_state: State
@export var landing_state: State
@export var hurt_state: State

@export var landing_threshold: float = 600
@export var hurt_threshold: float = 1000


@export var fall_gravity_multiplier: float = 2

var last_y_velocity: float = 0

func enter() -> void:
	super()

#func process_input(event: InputEvent) -> State:
	#if inputs.get_jump_input() and parent.is_on_floor():
		#return jump_state
	#
	#return null

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	parent.velocity.x = movements.horizontal_movement(parent.velocity.x, delta, inputs, parent)

	if parent.velocity.y > 0:
		last_y_velocity = parent.velocity.y
	
	movements.flip_direction(inputs, parent)

	parent.move_and_slide()

	if parent.is_on_floor():
		print(last_y_velocity)
		
		if last_y_velocity < landing_threshold:
			return idle_state
		else:
			if last_y_velocity > hurt_threshold:
				Global.player_health -= 1
				SignalBus.damage.emit(parent.global_position + Vector2(0,10))
				return hurt_state
			else:
				return landing_state
	
	return null

func _on_damage_received() -> State:
	return hurt_state
