class_name FFALobbyMenu extends Control

var _logger: _NetfoxLogger = _NetfoxLogger.new("Menu", "FFALobbyMenu")

@onready var players: VBoxContainer = $Teams/HBoxContainer/Players
@onready var player_team_slot_scene: PackedScene = preload("res://scenes/ui/menus/lobby/player_team_slot.tscn")

var player_ids: Dictionary[int, PlayerTeamSlot] = {}

# TODO There's something here, old clients don't seem to be getting the connected network event, which is fine for now

func _ready() -> void:
	hide()
	NetworkEvents.on_server_start.connect(_handle_host_started)
	NetworkEvents.on_client_start.connect(_handle_client_started)
	NetworkEvents.on_peer_join.connect(_create_player_team_slot)
	NetworkEvents.on_peer_leave.connect(_remove_player_team_slot)
	NetworkEvents.on_client_stop.connect(_remove_player_team_slot)
	NetworkEvents.on_server_stop.connect(_remove_player_team_slot)

func _handle_host_started() -> void:
	show()
	_create_player_team_slot(1)

func _handle_client_started(id: int) -> void:
	show()
	_create_player_team_slot(id)

func _create_player_team_slot(id: int) -> void:
	_logger.info("CONNECTION: Player [" + str(id) + "] has connected")
	var player_team_slot: PlayerTeamSlot = player_team_slot_scene.instantiate()
	player_team_slot.player_name = str(id)
	player_ids.set(id, player_team_slot)
	players.add_child(player_team_slot)

func _remove_player_team_slot(id: int) -> void:
	_logger.info("DISCONNECTION: Player [" + str(id) + "] has disconnected")
	player_ids[id].call_deferred("queue_free")
	player_ids.erase(id)
