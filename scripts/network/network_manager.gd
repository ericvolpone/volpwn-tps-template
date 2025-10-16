extends Node

signal noray_connected
signal joined_server

const NORAY_ADDRESS: String = "172.232.183.183"
const NORAY_PORT: int = 8890

var is_host: bool = false
var external_oid: String = ""

func _ready() -> void:
	Noray.on_connect_to_host.connect(on_noray_connected)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	
	Noray.connect_to_host(NORAY_ADDRESS, NORAY_PORT)

func on_noray_connected() -> void:
	print("Connected to Noray server")
	
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	noray_connected.emit()

func host() -> void:
	print("Hosting...")
	
	var peer: MultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	is_host = true

func join(oid: String) -> void:
	Noray.connect_nat(oid)
	external_oid = oid

func handle_nat_connection(address: String, port: int) -> Error:
	var err: Error = await connect_to_server(address, port)
	
	if err != OK && !is_host:
		print("NAT failed, using relay")
		Noray.connect_relay(external_oid)
		err = OK
	
	return err

func handle_relay_connection(address: String, port: int) -> Error:
	return await connect_to_server(address, port)

func connect_to_server(address: String, port: int) -> Error:
	var err: Error = OK
	
	if !is_host:
		var udp: PacketPeer = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		
		if err != OK:
			if err != ERR_BUSY:
				print("Handshake failed")
				return err
		else:
			print("Handshake success")
		
		var peer: MultiplayerPeer = ENetMultiplayerPeer.new()
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		
		if err != OK:
			return err
		
		multiplayer.multiplayer_peer = peer
		joined_server.emit()
		return OK
	else:
		err = await PacketHandshake.over_enet(multiplayer.multiplayer_peer.host, address, port)
		if err == OK:
			joined_server.emit()
	
	return err
	
