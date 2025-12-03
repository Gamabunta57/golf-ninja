extends TileMapLayer

func _process(delta):
	if Global.player_hidden:
		modulate.a = 0
	else:
		modulate.a = 1.0
