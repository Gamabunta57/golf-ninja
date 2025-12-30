extends State

@export var idle_state: State
@export var hurt_timer: Timer
@export var knockback_timer: Timer

@export var fall_gravity_multiplier: float = 3
@export var knockback_strength: float = 500
@export var game_over: PackedScene

var is_hurt : bool
var is_backlash: bool
var sentinel: CharacterBody2D

func enter() -> void:
	super()
	parent.state = "player hurt state"
	is_hurt = true
	Global.camera_mode = Global.CameraMode.HURT
	
	var knockback_direction = sign(parent.global_position.x - parent.enemy_position.x)
	parent.velocity.x = knockback_direction * knockback_strength
	
	hurt_timer.start()
	knockback_timer.start()

func exit() -> void:
	Global.camera_mode = Global.CameraMode.PLAYER
	
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
		if Global.player_health <= 0 :
			get_tree().change_scene_to_packed(game_over)
		else:
			return idle_state
	
	return null
