extends Node

var player_body: CharacterBody2D
var player_health: int = 7
var player_max_health: int = 7
var player_hidden: bool = false
var player_falling: bool = false
var shooting_action: bool = false
var player_shooting: bool = false
var total_money: int = 0
var player_centric: bool = true

var bin_position: Vector2 = Vector2.ZERO
