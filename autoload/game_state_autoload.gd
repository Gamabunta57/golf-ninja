extends Node

## Autoload singleton (registered as `Game`) owning the GameStateManager — the
## single source of truth for win/loss resolution and player health/shots
## (plan Phase 11) — plus a reference to the active building.

var manager: GameStateManager = GameStateManager.new()
var current_building: BuildingData


## Stores the active building so systems can query generated layout data.
func set_building(building: BuildingData) -> void:
	current_building = building
