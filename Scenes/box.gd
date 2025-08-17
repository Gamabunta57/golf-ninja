extends RigidBody2D

func _physics_process(delta):
	angular_velocity = clamp(angular_velocity, -5, 5)
