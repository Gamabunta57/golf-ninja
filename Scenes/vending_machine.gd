extends StaticBody2D

@onready var cost_label: RichTextLabel = $CostLabel

@export var max_sales: int = 10
@export var life_cost: int = 10

var buying: bool = false

func _ready() -> void:
	cost_label.text = str(life_cost, "$")

func _on_vending_machine_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		buying = true

func _on_vending_machine_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		buying = false

func _process(delta: float) -> void:
	if not buying:
		return
	
	if Global.total_money < life_cost:
		return
	
	if Global.player_health == Global.player_max_health:
		return
	
	if max_sales == 0:
		cost_label.text = "out"
		return
	
	if Input.is_action_just_pressed("shooting"):
		#print("should heal")
		Global.player_health += 1
		Global.total_money -= life_cost
		max_sales -= 1
		SignalBus.heal.emit()
