extends State

@export var idle_state: State

var player: CharacterBody2D
var delta_x: float

func enter() -> void:
	super()
	player = get_tree().get_first_node_in_group("Player")
	flip()

func on_body_exited(body: Node2D) -> State:
	flip()
	return idle_state

func flip() -> void:
	delta_x = player.global_position.x - parent.global_position.x
	if delta_x  * parent.direction < 0:
		parent.flip_direction()
