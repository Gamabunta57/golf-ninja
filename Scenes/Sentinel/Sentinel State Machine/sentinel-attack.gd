extends State

@export var idle_state: State
@export var sprite: Sprite2D

func enter() -> void:
	super()
	sprite.modulate = Color("red")
	print('body entered')

func on_body_exited(body: Node2D) -> State:
	return idle_state
