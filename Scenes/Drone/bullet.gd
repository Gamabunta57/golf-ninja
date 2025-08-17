extends RigidBody2D

var initial_direction: Vector2 = Vector2.ZERO
@export var bullet_speed: float = 1500.0
@export var bullet_lifetime: Timer
@export var damage: int = 1
@export var min_potent_speed: float = 100.0
var hit_player: bool = false
var potent: bool = true
var drone_origin_position: Vector2

func _ready() -> void: 
	linear_velocity = initial_direction * bullet_speed
	bullet_lifetime.start()

func _physics_process(delta: float) -> void:
	if linear_velocity.length() < min_potent_speed and potent:
		potent = false

	if hit_player and potent:
		potent = false
		Global.player_health -= damage
		SignalBus.damage.emit(drone_origin_position)

func set_bullet_direction(direction_vector: Vector2) -> void:
	initial_direction = direction_vector
	linear_velocity = initial_direction * bullet_speed 

func set_origin_position(origin: Vector2) -> void:
	drone_origin_position = origin
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not hit_player:
		hit_player = true

func _on_timer_timeout() -> void:
	bullet_lifetime.stop()
	self.queue_free()
