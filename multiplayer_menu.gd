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


func _ready() -> void:
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	if leave_button:
		leave_button.pressed.connect(_on_leave_pressed)
	if offline_button:
		offline_button.pressed.connect(_on_offline_pressed)

	var nm := _get_network_manager()
	if nm:
		nm.connection_succeeded.connect(_on_connection_succeeded)
		nm.connection_failed.connect(_on_connection_failed)
		nm.server_started.connect(_on_server_started)
		_set_status("Ready. Host or Join.")
	else:
		_set_status("Add NetworkManager as autoload (project.godot).")


func _get_network_manager() -> Node:
	# Autoload is typically under root with the name you gave in project.godot
	return get_tree().root.get_node_or_null("NetworkManager")


func _on_host_pressed() -> void:
	var nm = _get_network_manager()
	if nm == null:
		_set_status("NetworkManager autoload missing.")
		return
	var port := _get_port()
	if nm.host_game(port):
		_set_status("Hosting on port %d" % port)
	else:
		_set_status("Host failed (port in use?).")


func _on_join_pressed() -> void:
	var nm = _get_network_manager()
	if nm == null:
		_set_status("NetworkManager autoload missing.")
		return
	var ip := _get_ip()
	var port := _get_port()
	if nm.join_game(ip, port):
		_set_status("Connecting to %s:%d..." % [ip, port])
	else:
		_set_status("Join failed.")


func _on_leave_pressed() -> void:
	var nm = _get_network_manager()
	if nm:
		nm.leave_game()
	_set_status("Left game.")


func _on_offline_pressed() -> void:
	var nm = _get_network_manager()
	if nm:
		nm.start_offline()
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
	if status_label:
		status_label.text = msg
	print(msg)
