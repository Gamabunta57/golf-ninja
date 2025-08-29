extends Control

static var empty_heart_texture = load("res://Assets/UI/empty-heart.png")
static var full_heart_texture = load("res://Assets/UI/full-heart.png")

@onready var money_amount: RichTextLabel = %money_amount
@onready var hearts: HBoxContainer = %hearts
@onready var empty_hearts: HBoxContainer = %empty_hearts

func _ready() -> void:
	set_health(null)
	SignalBus.damage.connect(set_health)
	SignalBus.update_UI_money_count.connect(_update_money)

func set_health(origin_position):
	for child in hearts.get_children():
		child.queue_free()
	
	for child in empty_hearts.get_children():
		child.queue_free()
	
	for i in Global.player_max_health:
		var empty_heart = TextureRect.new()
		empty_heart.texture = empty_heart_texture
		empty_hearts.add_child(empty_heart)
		
	for i in Global.player_health:
		var heart = TextureRect.new()
		heart.texture = full_heart_texture
		hearts.add_child(heart)


func _update_money(amount: int) -> void:
		Global.total_money += amount
		money_amount.text = str(Global.total_money, "$")
