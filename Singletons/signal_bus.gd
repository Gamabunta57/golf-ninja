extends Node

signal damage(origin_position: Vector2)
signal heal()
signal shooting(vector: Vector2, body: RigidBody2D, player: Vector2)
signal enters_bin(body: RigidBody2D)
signal exits_bin(body: RigidBody2D)
signal ball_in_range(body: RigidBody2D, nearby: bool)
signal update_UI_money_count(amount: int)
signal last_trajectory_point(point:Vector2, body: RigidBody2D)
