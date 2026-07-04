class_name DoorKeycardSystem
extends RefCounted

## Runtime access control (plan §7.3 #8, Phase 10). Godot-agnostic logic over
## DoorData / KeycardData / PlayerState. The generator already guarantees every
## locked door's keycard is reachable beforehand (Phase 3); this enforces it at
## play time: locked doors block movement until the player holds a sufficient
## card, and cards auto-collect on walk-over.

## True if the player may move through this door right now (unlocked, already
## open, or the player holds a card of sufficient level).
func player_can_pass(door: DoorData, player_state: PlayerState) -> bool:
	if not door.is_locked():
		return true
	return player_state.has_access(door.required_access_level)


## Opens the door if the player is allowed through, latching it open. Returns
## true if the door is (now) open.
func open_if_allowed(door: DoorData, player_state: PlayerState) -> bool:
	if door.is_open:
		return true
	if door.required_access_level <= 0 or player_state.has_access(door.required_access_level):
		door.is_open = true
		return true
	return false


## Collects a keycard into the player's inventory (idempotent). Returns true if
## this call actually collected it.
func try_collect(card: KeycardData, player_state: PlayerState) -> bool:
	if card.collected:
		return false
	card.collected = true
	player_state.add_keycard(card.access_level)
	return true
