extends State

@export var fall_state: State
@export var hurt_state: State
@export var idle_state: State
@export var move_state: State
@export var original_parent: Node

var platform: Node2D

var original_rotation : float = 0.0

func enter() -> void:
	super()
	parent.state = "player teleport state"
	#parent.set_collision_mask_value(2, false)
	
	if Global.kunai_anchor_object:
		# 1. Get the TileMap reference
		var tilemap = Global.level_tilemap
		
		# 2. Determine the platform (Swap if it's a TileMap)
		if Global.kunai_anchor_object == tilemap and Global.kunai_rotation_valid:
				var local_pos = tilemap.to_local(Global.kunai_position)
				var map_pos = tilemap.local_to_map(local_pos)
				#var map_pos = tilemap.get_coords_for_body_rid(Global.kunai_anchor_rid)
				platform = tilemap.swap_tile_for_scene(map_pos)
		else:
			platform = Global.kunai_anchor_object

		# 3. SAFETY CHECK: Only proceed if platform was successfully found/created
		if platform != null:
			original_parent = parent.get_parent()
			var hit_pos = Global.kunai_position 
			
			original_parent.remove_child(parent)
			platform.add_child(parent) # This will no longer crash
			
			parent.global_position = hit_pos + Global.kunai_normal
			parent.global_rotation = Global.kunai_normal.angle() + (PI / 2)
	
	Global.is_clipping_world = false
	
func process_physics(delta: float) -> State:
	parent.velocity = Vector2.ZERO
	if inputs.get_shooting_just_pressed():
		if platform and platform.has_method("trigger_rotation"):
			platform.trigger_rotation()
	
	
	for i in parent.get_slide_collision_count():
		var collision = parent.get_slide_collision(i)
		if collision.get_collider() != platform:
			Global.is_clipping_world = true
			break
	
	if not inputs.get_jump_input() or Global.is_clipping_world:
		if parent.is_on_floor():
			return idle_state
		else:
			return fall_state
		
	parent.move_and_slide()
	
	return null

func exit() -> void:
# 1. Capture the current absolute world transform before we move anything
	var final_world_pos = parent.global_position
	var final_world_rot = parent.global_rotation

	# 2. Safety check: Only move if we are actually a child of the platform
	if platform and parent.get_parent() == platform:
		platform.remove_child(parent)
		original_parent.add_child(parent)
		
		# 3. Force the position and rotation back to absolute world values
		parent.global_position = final_world_pos
		parent.global_rotation = final_world_rot

	# 4. Reset Globals
	Global.kunai_cooldown_ongoing = true
	parent.kunai_cooldown_timer.start()
	Global.can_kunai = false
	Global.kunai_is_anchored = false
	Global.rotate_platform = false
	
	# 5. Fixed Rotation Tween
	# We use lerp_angle to ensure the player rotates the "shortest way" back to 0
	var tween := parent.create_tween()
	tween.tween_method(
		func(angle): parent.rotation = angle,
		parent.rotation, # Current rotation
		0.0,             # Target rotation (upright)
		0.25             # Duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_damage_received() -> State:
	return hurt_state
