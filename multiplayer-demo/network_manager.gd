extends Node
## Client-server multiplayer + offline prototype.
## Assign as autoload (e.g. NetworkManager) so any scene can call host/join/leave/offline.

const DEFAULT_PORT := 8080
const DEFAULT_IP := "127.0.0.1"

signal peer_connected(id: int, name: String)
signal peer_disconnected(id: int, name: String)
signal connection_succeeded()
signal connection_failed()
signal server_started()

var _peer: ENetMultiplayerPeer
var _offline_peer: OfflineMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


# --- Host (server) ---

func host_game(port: int = DEFAULT_PORT) -> bool:
	if _peer != null:
		leave_game()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port)
	if err != OK:
		push_error("Cannot host on port %d: %s" % [port, error_string(err)])
		return false
	multiplayer.multiplayer_peer = _peer
	server_started.emit()
	print("Server started on port %d. Waiting for players..." % port)
	return true


# --- Client ---

func join_game(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> bool:
	if _peer != null:
		leave_game()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(ip, port)
	if err != OK:
		push_error("Cannot join %s:%d - %s" % [ip, port, error_string(err)])
		connection_failed.emit()
		return false
	multiplayer.multiplayer_peer = _peer
	print("Joining %s:%d..." % [ip, port])
	return true


# --- Leave / cleanup ---

func leave_game() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_peer = null
	print("Left game.")


# --- Offline / single-player (no network) ---

func start_offline() -> void:
	leave_game()
	_offline_peer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = _offline_peer
	print("Offline mode: local peer is authority.")


# --- Queries ---

func is_server() -> bool:
	return multiplayer.is_server()


func is_offline() -> bool:
	return multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func get_local_id() -> int:
	return multiplayer.get_unique_id()


# --- RPC: example message from client to server ---

@rpc("any_peer")
func send_message_to_server(text: String) -> void:
	if multiplayer.is_server():
		var sender_id: int = multiplayer.get_remote_sender_id()
		print("Player %d says: %s" % [sender_id, text])


# --- Optional: RPC that runs on everyone (including caller with call_local) ---

@rpc("any_peer", "call_local")
func broadcast_message(text: String) -> void:
	var who := multiplayer.get_remote_sender_id() if not multiplayer.is_server() else get_local_id()
	print("Broadcast from %d: %s" % [who, text])


# --- Internal: signal handlers ---

func _on_multiplayer_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)
	peer_connected.emit(id, str(id))


func _on_multiplayer_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)
	peer_disconnected.emit(id, str(id))


func _on_connected_to_server() -> void:
	print("Connected to server as peer %d" % get_local_id())
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	push_error("Connection to server failed.")
	connection_failed.emit()
