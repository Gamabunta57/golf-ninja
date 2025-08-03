extends RigidBody2D

var initial_direction: Vector2 = Vector2.ZERO
@export var bullet_speed: float = 1500.0
@export var bullet_lifetime: Timer
@export var damage: int = 1
var hit_player: bool = false
var potent: bool = true

func _ready() -> void: 
	linear_velocity = initial_direction * bullet_speed
	bullet_lifetime.start()

func _physics_process(delta: float) -> void:
	if hit_player and potent:
		potent = false
		Global.player_health -= damage
		Global.last_attacker_position = global_position
		SignalBus.damage.emit()

func set_bullet_direction(direction_vector: Vector2) -> void:
	initial_direction = direction_vector
	linear_velocity = initial_direction * bullet_speed 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not hit_player:
		hit_player = true

func _on_timer_timeout() -> void:
	bullet_lifetime.stop()
	self.queue_free()
