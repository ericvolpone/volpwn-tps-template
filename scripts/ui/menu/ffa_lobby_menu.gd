class_name FFALobbyMenu extends Control

var _logger: _NetfoxLogger = _NetfoxLogger.new("Menu", "FFALobbyMenu")

@onready var players: VBoxContainer = $Teams/HBoxContainer/Players
@onready var player_team_slot_scene: PackedScene = preload("res://scenes/ui/menus/lobby/player_team_slot.tscn")

var player_ids: Dictionary[int, bool] = {}

# TODO There's something here, old clients don't seem to be getting the connected network event, which is fine for now

func _ready() -> void:
	_handle_client_connected(multiplayer.get_unique_id())
	for id: int in multiplayer.get_peers():
		_logger.info("Handling connected peer for " + str(id))
		_handle_client_connected(id)
	
	NetworkEvents.on_client_start.connect(_handle_client_connected)
	NetworkEvents.on_server_start.connect(_handle_host_started)
	NetworkEvents.on_peer_join.connect(_handle_new_peer)
	NetworkEvents.on_peer_leave.connect(_handle_leave)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_server_stop.connect(_handle_stop)

func _handle_client_connected(id: int) -> void:
	player_ids.set(id, true)
	_create_player_team_slot(id)

func _handle_host_started() -> void:
	player_ids.set(1, true)

func _handle_new_peer(id: int) -> void:
	player_ids.set(id, true)

func _handle_leave(id: int) -> void:
	player_ids.erase(id)

func _handle_stop(id: int) -> void:
	player_ids.erase(id)

func _create_player_team_slot(id: int) -> void:
	var player_team_slot: PlayerTeamSlot = player_team_slot_scene.instantiate()
	player_team_slot.player_name = str(id)
	players.add_child(player_team_slot)
