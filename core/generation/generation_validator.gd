class_name GenerationValidator
extends RefCounted

## Standalone checker for the five completability guarantees in GDD §6.3.
## Kept independent of the generator so it can validate any BuildingData
## (hand-built or generated) and be run across many seeds in tests.
##
## check_all() returns { "valid": bool, "errors": Array[String] } — errors names
## the first failure per guarantee so a failing seed is diagnosable.

const _NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func check_all(building: BuildingData, config: GenerationConfig) -> Dictionary:
	var errors: Array[String] = []
	errors.append_array(_check_ball_path(building))
	errors.append_array(_check_conduit_directionality(building, config))
	errors.append_array(_check_elevator_consistency(building))
	# Player path (#2) and card accessibility (#3) share one reachability pass.
	var reach: Dictionary = _compute_reachable(building)
	errors.append_array(_check_player_path(building, reach))
	errors.append_array(_check_card_accessibility(building, reach))
	return {"valid": errors.is_empty(), "errors": errors}


# --- #1 ball path completeness ----------------------------------------------

func _check_ball_path(building: BuildingData) -> Array[String]:
	var errors: Array[String] = []
	var n: int = building.floor_count()
	if n == 0:
		errors.append("ball_path: building has no floors")
		return errors
	var final_index: int = building.final_floor_index()
	# Directed down-graph: hole f -> f+1, plus each conduit origin -> dest.
	var adjacency: Dictionary = {}
	for f in n:
		var edges: Array[int] = []
		if f < final_index:
			edges.append(f + 1)  # this floor's hole drops one floor
		for conduit: ConduitLink in building.floors[f].conduits:
			edges.append(conduit.destination_floor)
		adjacency[f] = edges
	# Every floor must be able to reach the final floor's hole.
	for f in n:
		if not _can_reach_floor(adjacency, f, final_index):
			errors.append("ball_path: floor %d cannot reach final hole (floor %d)" % [f, final_index])
			break
	return errors


func _can_reach_floor(adjacency: Dictionary, start: int, target: int) -> bool:
	if start == target:
		return true
	var seen: Dictionary = {start: true}
	var queue: Array[int] = [start]
	while not queue.is_empty():
		var cur: int = queue.pop_back()
		for nxt: int in adjacency.get(cur, []):
			if nxt == target:
				return true
			if not seen.has(nxt):
				seen[nxt] = true
				queue.append(nxt)
	return false


# --- #5 conduit directionality ----------------------------------------------

func _check_conduit_directionality(building: BuildingData, config: GenerationConfig) -> Array[String]:
	var errors: Array[String] = []
	var max_drop: int = config.max_conduit_drop_distance
	var final_index: int = building.final_floor_index()
	for fd: FloorData in building.floors:
		for conduit: ConduitLink in fd.conduits:
			if conduit.destination_floor <= conduit.origin_floor:
				errors.append("conduit: non-downward %d -> %d" % [conduit.origin_floor, conduit.destination_floor])
				return errors
			if conduit.destination_floor > final_index:
				errors.append("conduit: destination floor %d out of range" % conduit.destination_floor)
				return errors
			if conduit.drop_distance() > max_drop:
				errors.append("conduit: drop %d exceeds max %d" % [conduit.drop_distance(), max_drop])
				return errors
	return errors


# --- #4 elevator coordinate consistency -------------------------------------

func _check_elevator_consistency(building: BuildingData) -> Array[String]:
	var errors: Array[String] = []
	for coord: Vector2i in building.elevator_network:
		var link: ElevatorLink = building.elevator_network[coord]
		if link.grid_position != coord:
			errors.append("elevator: network key %s != link position %s" % [coord, link.grid_position])
			return errors
		if link.serviced_floors.size() < 2:
			errors.append("elevator: shaft at %s services fewer than 2 floors" % coord)
			return errors
		for f: int in link.serviced_floors:
			var fd: FloorData = building.get_floor(f)
			if fd == null or not fd.elevator_positions.has(coord):
				errors.append("elevator: %s missing on serviced floor %d" % [coord, f])
				return errors
			if not fd.is_walkable(coord):
				errors.append("elevator: %s not walkable on floor %d" % [coord, f])
				return errors
	return errors


# --- reachability (shared by #2 and #3) -------------------------------------

## Iteratively computes the set of building cells the player can reach, opening
## doors as matching keycards are collected. Returns:
##   { "cells": Dictionary<Vector3i,bool>, "held": Dictionary<int,bool>,
##     "max_level": int }
## Vector3i keys are (floor, x, y).
func _compute_reachable(building: BuildingData) -> Dictionary:
	var held: Dictionary = {}
	var cells: Dictionary = {}
	while true:
		cells = _bfs_reachable(building, _max_level(held))
		var collected_new: bool = false
		for key: Vector3i in cells:
			var fd: FloorData = building.get_floor(key.x)
			for card: KeycardData in fd.keycards:
				if card.position == Vector2i(key.y, key.z) and not held.has(card.access_level):
					held[card.access_level] = true
					collected_new = true
		if not collected_new:
			break
	return {"cells": cells, "held": held, "max_level": _max_level(held)}


func _bfs_reachable(building: BuildingData, max_level: int) -> Dictionary:
	var seen: Dictionary = {}
	var start: Vector3i = Vector3i(building.player_start_floor, building.player_start_cell.x, building.player_start_cell.y)
	var start_fd: FloorData = building.get_floor(start.x)
	if start_fd == null or not start_fd.is_walkable(building.player_start_cell):
		return seen
	seen[start] = true
	var queue: Array[Vector3i] = [start]
	while not queue.is_empty():
		var cur: Vector3i = queue.pop_back()
		var fd: FloorData = building.get_floor(cur.x)
		var cur_cell: Vector2i = Vector2i(cur.y, cur.z)
		# Walk to open neighbours on the same floor.
		for step in _NEIGHBORS:
			var nc: Vector2i = cur_cell + step
			if not fd.is_walkable(nc):
				continue
			var door: DoorData = fd.get_door_at(nc)
			if door != null and door.required_access_level > max_level:
				continue  # locked, no sufficient card yet
			var nkey: Vector3i = Vector3i(cur.x, nc.x, nc.y)
			if not seen.has(nkey):
				seen[nkey] = true
				queue.append(nkey)
		# Ride an elevator to every other serviced floor (same coordinate).
		var link: ElevatorLink = building.get_elevator(cur_cell)
		if link != null:
			for f: int in link.serviced_floors:
				if f == cur.x:
					continue
				var ekey: Vector3i = Vector3i(f, cur_cell.x, cur_cell.y)
				if not seen.has(ekey):
					seen[ekey] = true
					queue.append(ekey)
	return seen


func _max_level(held: Dictionary) -> int:
	var m: int = 0
	for level: int in held:
		m = maxi(m, level)
	return m


# --- #2 player path completeness --------------------------------------------

func _check_player_path(building: BuildingData, reach: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var cells: Dictionary = reach["cells"]
	# The ball can reach every floor, so the player must be able to reach a cell
	# on every floor via elevator routes.
	for f in building.floor_count():
		var found: bool = false
		for key: Vector3i in cells:
			if key.x == f:
				found = true
				break
		if not found:
			errors.append("player_path: floor %d unreachable from player start" % f)
			break
	return errors


# --- #3 card accessibility ---------------------------------------------------

func _check_card_accessibility(building: BuildingData, reach: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var max_level: int = reach["max_level"]
	# Every locked door must be openable — its required card must have been
	# reachable without first passing that door (the fixpoint BFS enforces this:
	# a card only obtainable through its own door is never collected).
	for fd: FloorData in building.floors:
		for door: DoorData in fd.doors:
			if door.required_access_level > max_level:
				errors.append("card_access: door on floor %d needs level %d but only level %d is reachable" % [fd.floor_index, door.required_access_level, max_level])
				return errors
	return errors
