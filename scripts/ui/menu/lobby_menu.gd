class_name TeamLobbyMenu extends Control

const NO_TEAM: int = 0;
const TEAM_1: int = 1;
const TEAM_2: int = 2;

@onready var team_1: VBoxContainer = $Teams/HBoxContainer/Team1
@onready var team_2: VBoxContainer = $Teams/HBoxContainer/Team2
@onready var unassigned: VBoxContainer = $Teams/HBoxContainer/Unassigned

var TEAM_CONTAINER_BY_ID: Dictionary[int, VBoxContainer] = {
	NO_TEAM: unassigned,
	TEAM_1: team_1,
	TEAM_2: team_2
}

@onready var player_team_slot_scene: PackedScene = preload("res://scenes/ui/menus/lobby/player_team_slot.tscn")

var team_to_player_id: Dictionary[int, Array] = {
	NO_TEAM: [],
	TEAM_1: [],
	TEAM_2: []
}

var player_id_to_team: Dictionary[int, int] = {}

func _ready() -> void:
	NetworkEvents.on_client_start.connect(_handle_client_connected)
	NetworkEvents.on_server_start.connect(_handle_host_started)
	NetworkEvents.on_peer_join.connect(_handle_new_peer)
	NetworkEvents.on_peer_leave.connect(_handle_leave)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_server_stop.connect(_handle_stop)

func _handle_client_connected(id: int) -> void:
	team_to_player_id.get(_get_next_team()).append(id)

func _handle_host_started() -> void:
	team_to_player_id.get(_get_next_team()).append(1)

func _handle_new_peer(id: int) -> void:
	team_to_player_id.get(_get_next_team()).append(id)

func _handle_leave(id: int) -> void:
	team_to_player_id.erase(id)

func _handle_stop(id: int) -> void:
	team_to_player_id.erase(id)

func _create_player_team_slot(id: int, team_id: int) -> void:
	var player_team_slot: Control = player_team_slot_scene.instantiate()
	TEAM_CONTAINER_BY_ID.get(team_id).add_child(player_team_slot)

func _get_next_team() -> int:
	if team_to_player_id.get(TEAM_1).length <= team_to_player_id.get(TEAM_2).length:
		return TEAM_1
	else:
		return TEAM_2
