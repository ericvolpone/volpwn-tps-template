class_name Level extends Node3D

@onready var player_spawner: PlayerSpawner = $PlayerSpawner

var active_players: Dictionary[int, Player] = {};

func initialize_game(player_ids: Array[int]) -> void:
	for player_id: int in player_ids:
		player_spawner._spawn(player_id)
