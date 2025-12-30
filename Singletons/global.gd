extends Node

var player_body: CharacterBody2D
var grapple_body: CharacterBody2D
var player_health: int = 7
var player_max_health: int = 7
var grapple_distance: float = 800
var player_hidden: bool = false
var player_falling: bool = false
var shooting_action: bool = false
var player_shooting: bool = false
var total_money: int = 0
var player_centric: bool = true
var can_grapple: bool = false
var grapple_cooldown_ongoing: bool = false
var grapple_is_anchored: bool = false
var direction: int = 1
var rope_points: PackedVector2Array = PackedVector2Array([])


var bin_position: Vector2 = Vector2.ZERO
