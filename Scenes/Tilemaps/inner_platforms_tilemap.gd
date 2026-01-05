extends TileMapLayer

@export var platform_scene: PackedScene
@export var ball_scene: PackedScene
@export var sentinel_scene: PackedScene
@export var stroke_layer: TileMapLayer

# Atlas Mapping
const TILE_HORIZONTAL = Vector2i(0, 0)
const TILE_PLUS_120 = Vector2i(1, 0)
const TILE_MINUS_120 = Vector2i(2, 0)

func _ready() -> void:
	Global.level_tilemap = self
	var cells = get_used_cells()
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for cell in cells:
		# 1 in 5 chance to remove tile
		if rng.randi_range(1, 5) == 1:
			set_cell(cell, -1)
			stroke_layer.set_cell(cell, -1)
			continue

		# Randomize initial state
		var roll = rng.randi_range(1, 6)
		var coords = TILE_HORIZONTAL
		
		if roll == 1: coords = TILE_MINUS_120
		if roll == 2: coords = TILE_PLUS_120

		# Set the static tile
		set_cell(cell, 2, coords)
		stroke_layer.set_cell(cell, 0, coords)

		# Only spawn extras if horizontal (0,0)
		if coords == TILE_HORIZONTAL:
			var world_pos = to_global(map_to_local(cell))
			if rng.randi_range(1, 5) == 1:
				spawn_deferred(ball_scene, world_pos)
			elif rng.randi_range(1, 20) == 1:
				spawn_deferred(sentinel_scene, world_pos)

func spawn_deferred(scene: PackedScene, pos: Vector2):
	var inst = scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(inst)
	inst.global_position = pos

func swap_tile_for_scene(map_pos: Vector2i) -> Node2D:
	var coords = get_cell_atlas_coords(map_pos)
	if coords == Vector2i(-1, -1): return null
	
	var start_angle = 0.0
	if coords == TILE_MINUS_120: start_angle = -120.0
	elif coords == TILE_PLUS_120: start_angle = 120.0
	
	# Capture the world position BEFORE deleting the tile
	var spawn_pos = to_global(map_to_local(map_pos))
	
	set_cell(map_pos, -1)
	stroke_layer.set_cell(map_pos, -1)
	
	var inst = platform_scene.instantiate()
	
	# Add to the Scene Tree root or the TileMap's parent
	get_tree().current_scene.add_child(inst) 
	
	inst.global_position = spawn_pos
	inst.rotation_degrees = start_angle
	
	# DEBUG: If it's still invisible, this will tell you where it went
	#print("Spawned platform at: ", inst.global_position, " for map cell: ", map_pos)
	
	return inst

func swap_scene_for_tile(global_pos: Vector2, final_angle: float):
	var map_pos = local_to_map(to_local(global_pos))
	
	# Normalize angle to match atlas (0, 120, 240/-120)
	var norm_angle = posmod(round(final_angle), 360)
	var new_coords = TILE_HORIZONTAL
	
	if norm_angle == 120: new_coords = TILE_PLUS_120
	elif norm_angle == 240: new_coords = TILE_MINUS_120
	
	set_cell(map_pos, 2, new_coords) # Adjust '0' to your Source ID
	stroke_layer.set_cell(map_pos, 0, new_coords)
