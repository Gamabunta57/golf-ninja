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
	
	parent.velocity += (parent.global_position - Global.last_attacker_position).normalized() * knockback
	
	hurt_timer.start()
	knockback_timer.start()

func _on_knockback_timer_timeout():
	parent.velocity = Vector2.ZERO
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
