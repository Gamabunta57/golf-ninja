extends Control

static var empty_heart_texture = load("res://Assets/UI/empty-heart.png")
static var full_heart_texture = load("res://Assets/UI/full-heart.png")

func _ready() -> void:
	set_health(null)
	SignalBus.damage.connect(set_health)

func set_health(origin_position):
	for child in $MarginContainer/hearts.get_children():
		child.queue_free()
	
	for child in $MarginContainer/empty_hearts.get_children():
		child.queue_free()
	
	for i in Global.player_max_health:
		var empty_heart = TextureRect.new()
		empty_heart.texture = empty_heart_texture
		$MarginContainer/empty_hearts.add_child(empty_heart)
		
	for i in Global.player_health:
		var heart = TextureRect.new()
		heart.texture = full_heart_texture
		$MarginContainer/hearts.add_child(heart)
