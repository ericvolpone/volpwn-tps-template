class_name FFALobbyMenu extends Control

var _logger: _NetfoxLogger = _NetfoxLogger.new("Menu", "FFALobbyMenu")

#region Maps
const maps_by_id: Dictionary[int, PackedScene] = {
	0: preload("res://scenes/levels/level.tscn")
}
#endregion

#region Var: Player Container
@onready var players_container: VBoxContainer = $Teams/HBoxContainer/Players
@onready var player_team_slot_scene: PackedScene = preload("res://scenes/ui/menus/lobby/player_team_slot.tscn")
#endregion

#region Var: LobbyButtons
@onready var start_game_button: Button = $StartGameButton
@onready var leave_button: Button = $LeaveButton
@onready var map_select_button: OptionButton = $MapSelectButton
#endregion

var player_ids: Dictionary[int, PlayerTeamSlot] = {}

# TODO There's something here, old clients don't seem to be getting the connected network event, which is fine for now

func _ready() -> void:
	hide()
	
	NetworkEvents.on_server_start.connect(_handle_host_started)
	NetworkEvents.on_client_start.connect(_handle_client_started)
	NetworkEvents.on_peer_join.connect(_create_player_team_slot)
	NetworkEvents.on_peer_leave.connect(_remove_player_team_slot)
	NetworkEvents.on_server_stop.connect(_handle_server_stop)
	NetworkEvents.on_client_stop.connect(_handle_client_stop)

#region Func: Connection
func _handle_host_started() -> void:
	show()
	_create_player_team_slot(1)

func _handle_client_started(id: int) -> void:
	start_game_button.disabled = true
	map_select_button.disabled = true
	show()
	_create_player_team_slot(id)

func _handle_server_stop() -> void:
	_go_back_to_home_screen()

func _handle_client_stop() -> void:
	_go_back_to_home_screen()

func _create_player_team_slot(id: int) -> void:
	_logger.info("CONNECTION: Player [" + str(id) + "] has connected")
	var player_team_slot: PlayerTeamSlot = player_team_slot_scene.instantiate()
	player_team_slot.player_name = str(id)
	player_ids.set(id, player_team_slot)
	players_container.add_child(player_team_slot)

func _remove_player_team_slot(id: int) -> void:
	_logger.info("DISCONNECTION: Player [" + str(id) + "] has disconnected")
	player_ids[id].call_deferred("queue_free")
	player_ids.erase(id)
#endregion

#region Func: LobbyActions
func _on_start_game_button_pressed() -> void:
	_start_lobby.rpc(map_select_button.get_selected_id())

@rpc("authority", "call_local", "reliable")
func _start_lobby(map_id: int) -> void:
	var level: Level = maps_by_id[map_id].instantiate()
	get_tree().root.add_child(level);
	level.call_deferred("initialize_game", player_ids.keys())
	self.call_deferred("queue_free")

func _on_leave_button_pressed() -> void:
	multiplayer.multiplayer_peer.close()

func _go_back_to_home_screen() -> void:
	get_tree().change_scene_to_packed(load("res://scenes/ui/home_screen.tscn"))
#endregion
