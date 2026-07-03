extends Node

## Autoload singleton (registered as `Game`) that will own the GameStateManager
## — the single source of truth for player/guard health, ball position, and
## win/loss resolution (plan Phase 11). Scaffolded now so the autoload exists
## from Phase 0; the manager is wired in when Phase 11 lands.

# Populated in Phase 11:
# var manager: GameStateManager

var current_building: BuildingData


func _ready() -> void:
	pass


## Stores the active building so systems can query generated layout data.
func set_building(building: BuildingData) -> void:
	current_building = building
