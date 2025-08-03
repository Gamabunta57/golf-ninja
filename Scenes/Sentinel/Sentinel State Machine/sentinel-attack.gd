extends State

@export var idle_state: State
@export var damage: int = 1
@export var cooldown: Timer

var should_attack: bool

func enter() -> void:
	super()
	should_attack = true
	parent.flip()

func process_physics(delta: float) -> State:
	if should_attack and not parent.attack_cooldown:
		should_attack = false
		parent.attack_cooldown = true
		cooldown.start()
		Global.player_health -= damage
		Global.last_attacker_position = parent.global_position
		SignalBus.damage.emit()
	else:
		return idle_state
	return null

#func exit() -> void:
	#should_attack = true
