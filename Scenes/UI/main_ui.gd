extends Control

static var full_heart = load("res://Assets/UI/full-heart.png")

func set_health(amount):
	for child in $MarginContainer/hearts.get_children():
		child.queue_free()
	
	for i in amount:
		var heart = TextureRect.new()
		heart.texture = full_heart
		$MarginContainer/hearts.add_child(heart)
