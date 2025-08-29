extends StaticBody2D

var trash_counter: int = 0

func _ready() -> void:
	Global.bin_position = global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	SignalBus.enters_bin.emit(body)
	trash_counter += 1


func _on_area_2d_body_exited(body: Node2D) -> void:
	SignalBus.exits_bin.emit(body)
	trash_counter -= 1
