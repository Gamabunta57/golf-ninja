extends Node

var player_body: CharacterBody2D
var player_health: int = 7
var player_max_health: int = 7
#var player_hidden: bool = false
var player_falling: bool = false
var shooting_action: bool = false
var player_shooting: bool = false
var total_money: int = 0
#var player_centric: bool = true

var direction: int = 1
var rope_points: PackedVector2Array = PackedVector2Array([])


var bin_position: Vector2 = Vector2.ZERO

#BALL
var current_ball_position: Vector2 = Vector2.ZERO

#BALL TRAJECTORY PREVIEW
var current_preview_position: Vector2 = Vector2.ZERO

#KUNAI
var kunai_body: CharacterBody2D
var kunai_position: Vector2
var can_kunai: bool = false
var kunai_cooldown_ongoing: bool = false
var kunai_is_anchored: bool = false
var kunai_normal: Vector2
var kunai_idle_position: Vector2 = Vector2.ZERO

#CAMERA LOGIC
enum CameraMode { PLAYER, BALL, KUNAI, PREVIEW, HURT }
var camera_mode: CameraMode = CameraMode.PLAYER


#OBSOLETE
var grapple_body: CharacterBody2D
var can_grapple: bool = false
var grapple_cooldown_ongoing: bool = false
var grapple_is_anchored: bool = false
var grapple_distance: float = 800
