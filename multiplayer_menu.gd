extends Control
## Simple UI for host / join / leave / offline.
## Add to a Control with buttons: HostButton, JoinButton, LeaveButton, OfflineButton;
## optional: IPEdit (LineEdit), PortEdit (LineEdit), StatusLabel (Label).

@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var leave_button: Button = %LeaveButton
@onready var offline_button: Button = %OfflineButton
@onready var ip_edit: LineEdit = %IPEdit if has_node("%IPEdit") else null
@onready var port_edit: LineEdit = %PortEdit if has_node("%PortEdit") else null
@onready var status_label: Label = %StatusLabel if has_node("%StatusLabel") else null

const DEFAULT_PORT := 8080
const DEFAULT_IP := "127.0.0.1"

# Connection test: when the other peer presses T, we draw a blue triangle here
var _triangle_positions: Array[Vector2] = []
var _triangle_sender_ids: Array[int] = []


func _ready() -> void:
	# Connect buttons by path so it works even if @onready fails
	_connect_button("VBox/HostButton", _on_host_pressed)
	_connect_button("VBox/JoinButton", _on_join_pressed)
	_connect_button("VBox/LeaveButton", _on_leave_pressed)
	_connect_button("VBox/OfflineButton", _on_offline_pressed)

	# Use autoload by name (Project Settings > Autoload)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_started.connect(_on_server_started)
	_set_status("Ready. Host or Join.")
	print("[MultiplayerMenu] _ready done. Buttons should be clickable.")
	print("[MultiplayerMenu] Press T to send a blue triangle to the other process (when connected).")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_T and event.pressed and not event.echo:
		_send_triangle_to_others()


func _send_triangle_to_others() -> void:
	if not multiplayer.multiplayer_peer:
		print("[MultiplayerMenu] Press T: not connected, no peer.")
		return
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		print("[MultiplayerMenu] Press T: offline mode, no other process.")
		return
	# RPC runs on the other peer(s) only (no call_local)
	rpc("draw_blue_triangle_on_my_screen", NetworkManager.get_local_id())
	print("[MultiplayerMenu] Press T: sent triangle request to other process(es).")


@rpc("any_peer")
func draw_blue_triangle_on_my_screen(sender_id: int) -> void:
	var pos := Vector2(randf_range(150, 500), randf_range(150, 400))
	_triangle_positions.append(pos)
	_triangle_sender_ids.append(sender_id)
	queue_redraw()
	print("[MultiplayerMenu] Received triangle from peer ", sender_id, " at ", pos)


func _draw() -> void:
	var size := 18.0
	var half := size * 0.5
	for i in _triangle_positions.size():
		var pos := _triangle_positions[i]
		var points := PackedVector2Array([
			pos + Vector2(0, -half),
			pos + Vector2(-half, half),
			pos + Vector2(half, half)
		])
		draw_colored_polygon(points, Color(0.2, 0.4, 0.9))  # blue


func _connect_button(path: StringName, callback: Callable) -> void:
	var btn := get_node_or_null(NodePath(path)) as Button
	if btn:
		btn.pressed.connect(callback)
		print("[MultiplayerMenu] Connected button: ", path)
	else:
		print("[MultiplayerMenu] WARNING: Button not found: ", path)


func _on_host_pressed() -> void:
	print("[MultiplayerMenu] Host button pressed.")
	_set_status("Starting host...")
	await get_tree().process_frame

	var port := _get_port()
	if NetworkManager.host_game(port):
		_set_status("Hosting on port %d — wait for players" % port)
	else:
		_set_status("Host failed. Is port %d in use?" % port)


func _on_join_pressed() -> void:
	print("[MultiplayerMenu] Join button pressed.")
	var ip := _get_ip()
	var port := _get_port()
	if NetworkManager.join_game(ip, port):
		_set_status("Connecting to %s:%d..." % [ip, port])
	else:
		_set_status("Join failed.")


func _on_leave_pressed() -> void:
	print("[MultiplayerMenu] Leave button pressed.")
	NetworkManager.leave_game()
	_set_status("Left game.")


func _on_offline_pressed() -> void:
	print("[MultiplayerMenu] Offline button pressed.")
	NetworkManager.start_offline()
	_set_status("Offline mode.")


func _on_connection_succeeded() -> void:
	_set_status("Connected to server.")


func _on_connection_failed() -> void:
	_set_status("Connection failed.")


func _on_server_started() -> void:
	_set_status("Server started. Waiting for players...")


func _get_ip() -> String:
	if ip_edit and ip_edit.text.strip_edges().is_empty() == false:
		return ip_edit.text.strip_edges()
	return DEFAULT_IP


func _get_port() -> int:
	if port_edit and port_edit.text.strip_edges().is_empty() == false:
		return port_edit.text.to_int()
	return DEFAULT_PORT


func _set_status(msg: String) -> void:
	var label := status_label
	if label == null:
		label = get_node_or_null(NodePath("VBox/StatusLabel")) as Label
	if label:
		label.text = msg
	print("[MultiplayerMenu] ", msg)
