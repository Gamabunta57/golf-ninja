extends State

@export var idle_state: State
@export var hurt_timer: Timer
@export var knockback_timer: Timer

@export var fall_gravity_multiplier: float = 3
@export var knockback: float = 500

var is_hurt : bool
var is_backlash: bool
var sentinel: CharacterBody2D

func enter() -> void:
	super()
	is_hurt = true
	parent.player_health -= 1
	parent.health()
	
	print(parent.player_health)
	parent.velocity = (parent.global_position - parent.last_attacker.global_position).normalized() * knockback
	
	knockback_timer.connect("timeout", Callable(self, "_on_knockback_timer_timeout"))
	hurt_timer.connect("timeout", Callable(self, "_on_hurt_timer_timeout"))
	hurt_timer.start()
	knockback_timer.start()

func _on_knockback_timer_timeout():
	parent.velocity.x = 0
	parent.velocity.y = 0
	knockback_timer.stop()

func _on_hurt_timer_timeout():
	is_hurt = false
	hurt_timer.stop()

func process_physics(delta: float) -> State:
	
	parent.velocity.y += gravity * fall_gravity_multiplier * delta
	parent.move_and_slide()
	
	if not is_hurt:
		return idle_state
	
	return null
