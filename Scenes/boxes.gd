extends Node2D

const BoxScene = preload("res://Scenes/box.tscn")

const SPAWN_AREA = Rect2(Vector2(-112, -48), Vector2(224, 96))

var NUMBER_OF_INSTANCES : int = 10

const MIN_DISTANCE = 20.0

const MAX_TRIES_PER_INSTANCE = 20


# --- Script Logic ---

func _ready():
	NUMBER_OF_INSTANCES = randi_range(5, 20)
	randomize()
	generate_and_place_instances()


func generate_and_place_instances():

	var placed_positions = [] # Keep track of where we've placed boxes
	
	# Loop to create the desired number of instances
	for _i in range(NUMBER_OF_INSTANCES):
		
		# Inner loop to try and find a valid position
		for _j in range(MAX_TRIES_PER_INSTANCE):
			# Pick a random position
			var random_x = randf_range(SPAWN_AREA.position.x, SPAWN_AREA.end.x)
			var random_y = randf_range(SPAWN_AREA.position.y, SPAWN_AREA.end.y)
			var candidate_position = Vector2(random_x, random_y)
			
			# Assume the position is valid until we find otherwise
			var is_valid_position = true
			
			# Check against all previously placed positions
			for pos in placed_positions:
				if candidate_position.distance_to(pos) < MIN_DISTANCE:
					is_valid_position = false
					break # It's too close, no need to check others
			
			# If the position is valid, place the box and move to the next one
			if is_valid_position:
				# Add the valid position to our list
				placed_positions.append(candidate_position)
				
				# Create and place the instance
				var instance = BoxScene.instantiate()
				instance.position = candidate_position
				add_child(instance)
				print("Instantiated box at: %s" % candidate_position)
				
				# Exit the "tries" loop and move to the next instance
				break
