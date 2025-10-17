class_name HomeScreen extends Control

#region SceneNodes
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

	#region SceneNodes : Host
@onready var host_prompt: VBoxContainer = $HostPrompt
@onready var host_localhost_checkbox: CheckBox = $HostPrompt/HostType/LocalhostCheckbox
@onready var host_noray_checkbox: CheckBox = $HostPrompt/HostType/NorayCheckbox
@onready var host_host_button: Button = $HostPrompt/HostButton
	#endregion

	#region SceneNodes: Join
@onready var join_prompt: VBoxContainer = $JoinPrompt
@onready var join_line_edit: LineEdit = $JoinPrompt/LineEdit
@onready var join_ip_address_checkbox: CheckBox = $JoinPrompt/HostType/IPAddressCheckbox
@onready var join_noray_checkbox: CheckBox = $JoinPrompt/HostType/NorayCheckbox
@onready var join_connect_button: Button = $JoinPrompt/ConnectButton
	#endregion
#endregion

#region PackedScenes
@onready var lobby_scene = preload("res://scenes/ui/menus/lobby/ffa_lobby_menu.tscn")
#endregion

#region AuxiliaryVariables
var joining_lobby: FFALobbyMenu;
#endregion

func _ready() -> void:
	host_prompt.visible = false
	join_prompt.visible = false

#region Func: HostPrompt
func _on_host_button_pressed() -> void:
	if not join_prompt.visible:
		host_prompt.visible = !host_prompt.visible

func _on_host_localhost_checkbox_pressed() -> void:
	if host_localhost_checkbox.button_pressed:
		host_noray_checkbox.button_pressed = false

func _on_host_noray_checkbox_pressed() -> void:
	if host_noray_checkbox.button_pressed:
		host_localhost_checkbox.button_pressed = false

func _on_host_host_button_pressed() -> void:
	var lobby: FFALobbyMenu = lobby_scene.instantiate();
	get_tree().root.add_child(lobby)
	if host_localhost_checkbox.button_pressed:
		print("Hosting with Local Host")
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		peer.create_server(9999)
		multiplayer.multiplayer_peer = peer
		while(peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED):
			pass
		print("Hosting server at:", IP.get_local_addresses())
	elif host_noray_checkbox.button_pressed:
		print("Hosting with Noray")
		NetworkManager.host()
	else:
		lobby.queue_free()
		print("Must choose a host type")
		return;

	get_tree().current_scene.queue_free()
	get_tree().current_scene = lobby
#endregion

#region Func: JoinPrompt
func _on_join_button_pressed() -> void:
	if not host_prompt.visible:
		join_prompt.visible = !join_prompt.visible

func _on_join_ip_address_checkbox_pressed() -> void:
	if join_ip_address_checkbox.button_pressed:
		join_noray_checkbox.button_pressed = false

func _on_join_noray_checkbox_pressed() -> void:
	if join_noray_checkbox.button_pressed:
		join_ip_address_checkbox.button_pressed = false

func _on_join_connect_button_pressed() -> void:
	joining_lobby = lobby_scene.instantiate()
	get_tree().root.add_child(joining_lobby)
	var ip_address: String = join_line_edit.text

	if join_ip_address_checkbox.button_pressed:
		print("Joining with IP Address, " + ip_address)
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		peer.create_client(ip_address, 9999)
		multiplayer.multiplayer_peer = peer
		multiplayer.connected_to_server.connect(_on_joined_server)
	elif join_noray_checkbox.button_pressed:
		print("Joining with Noray")
		NetworkManager.joined_server.connect(_on_joined_server)
		NetworkManager.join(ip_address)
	else:
		joining_lobby = null;
		print("Must choose a connection type")

func _on_joined_server() -> void:
	print("Joined server")
	get_tree().current_scene.queue_free()
	get_tree().current_scene = joining_lobby
#endregion

func _on_quit_button_pressed() -> void:
	get_tree().quit();
