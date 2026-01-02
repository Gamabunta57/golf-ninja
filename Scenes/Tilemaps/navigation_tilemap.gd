extends TileMapLayer

@export var obstacle_layer_mask: int = 2 
@export var update_interval: float = 0.15 
var time_since_update: float = 0.0

# 1. FIX: Define as a plain Dictionary (no Array typing)
var original_tiles: Dictionary = {}

func _ready() -> void:
	# 2. FIX: Manually fill the dictionary so we store the Atlas Coords
	var used_cells = get_used_cells()
	for coords in used_cells:
		# Store the position as the Key, and Atlas Coordinates as the Value
		original_tiles[coords] = get_cell_atlas_coords(coords)

func _physics_process(delta: float) -> void:
	time_since_update += delta
	if time_since_update >= update_interval:
		refresh_navigation_grid()
		time_since_update = 0.0

func refresh_navigation_grid() -> void:
	var space_state = get_world_2d().direct_space_state
	
	# 3. Iterate through the keys (the Vector2i positions)
	for coords in original_tiles.keys():
		var local_pos = map_to_local(coords)
		var world_pos = to_global(local_pos) # Handles your (90, -104) transform
		
		var query = PhysicsPointQueryParameters2D.new()
		query.position = world_pos
		query.collision_mask = obstacle_layer_mask
		query.collide_with_bodies = true
		
		var result = space_state.intersect_point(query)
		
		if result.size() > 0:
			# If obstacle hit, remove tile
			set_cell(coords, -1)
		else:
			# If clear, restore the original tile
			if get_cell_source_id(coords) == -1:
				# Use source 0 and the coordinates we saved in _ready
				set_cell(coords, 0, original_tiles[coords])
