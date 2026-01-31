extends Control
## Lobby - Multiplayer lobby screen
## Handles player list, connection setup, and game start

signal player_ready_changed(player_id: int, is_ready: bool)

@onready var player_list_container: VBoxContainer = %PlayerListContainer
@onready var player_name_input: LineEdit = %PlayerNameInput
@onready var ip_input: LineEdit = %IPInput
@onready var port_input: LineEdit = %PortInput
@onready var connect_button: Button = %ConnectButton
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton
@onready var ready_button: Button = %ReadyButton
@onready var connection_panel: PanelContainer = %ConnectionPanel
@onready var status_label: Label = %StatusLabel

# Set by MainMenu when instantiating
var is_hosting: bool = false

# Local player state
var local_ready: bool = false

# Player ready states (peer_id -> is_ready)
var player_ready_states: Dictionary = {}

# Template for player list items
const PLAYER_LIST_ITEM = preload("res://src/ui/PlayerListItem.tscn") if ResourceLoader.exists("res://src/ui/PlayerListItem.tscn") else null


func _ready() -> void:
	# Connect UI signals
	connect_button.pressed.connect(_on_connect_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	ready_button.pressed.connect(_on_ready_pressed)

	# Connect network signals
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	NetworkManager.lobby_updated.connect(_on_lobby_updated)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

	# Set default values
	port_input.text = str(NetworkManager.DEFAULT_PORT)
	ip_input.text = "127.0.0.1"
	player_name_input.text = "Player"

	# Configure UI based on hosting mode
	_setup_for_mode()

	# Update game state
	GameManager.change_state(GameManager.GameState.LOBBY)
	AudioManager.play_music(AudioManager.MusicTrack.LOBBY)

	print("[Lobby] Ready (hosting: %s)" % is_hosting)


func _setup_for_mode() -> void:
	if is_hosting:
		# Host mode - hide IP input, show different button text
		ip_input.visible = false
		ip_input.get_parent().get_node_or_null("IPLabel").visible = false if ip_input.get_parent().get_node_or_null("IPLabel") else true
		connect_button.text = "Create Lobby"
		status_label.text = "Configure your lobby"
		start_button.visible = false  # Hidden until connected
		ready_button.visible = false  # Host doesn't need ready button
	else:
		# Join mode
		connect_button.text = "Join Lobby"
		status_label.text = "Enter host details"
		start_button.visible = false  # Only host can start
		ready_button.visible = false  # Hidden until connected


func _on_connect_pressed() -> void:
	AudioManager.play_ui_click()

	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"

	var port = int(port_input.text)
	if port <= 0 or port > 65535:
		port = NetworkManager.DEFAULT_PORT

	connect_button.disabled = true
	status_label.text = "Connecting..."

	var error: Error
	if is_hosting:
		error = NetworkManager.host_game(port, player_name)
		if error == OK:
			_on_host_created()
	else:
		var ip = ip_input.text.strip_edges()
		if ip.is_empty():
			ip = "127.0.0.1"
		error = NetworkManager.join_game(ip, port, player_name)

	if error != OK:
		status_label.text = "Connection failed: %s" % error_string(error)
		connect_button.disabled = false


func _on_host_created() -> void:
	status_label.text = "Lobby created! Waiting for players..."
	connection_panel.visible = false
	start_button.visible = true
	start_button.disabled = true  # Disabled until at least 2 players
	_update_player_list()


func _on_connection_succeeded() -> void:
	status_label.text = "Connected!"
	connection_panel.visible = false
	ready_button.visible = true
	_update_player_list()


func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check IP and port."
	connect_button.disabled = false


func _on_server_disconnected() -> void:
	status_label.text = "Disconnected from server."
	_return_to_menu()


func _on_lobby_updated(player_names: Array) -> void:
	_update_player_list()

	# Update start button state for host
	if is_hosting:
		var player_count = NetworkManager.get_player_count()
		start_button.disabled = player_count < 2 or not _all_players_ready()


func _on_player_connected(peer_id: int) -> void:
	player_ready_states[peer_id] = false
	_update_player_list()


func _on_player_disconnected(peer_id: int) -> void:
	player_ready_states.erase(peer_id)
	_update_player_list()


func _on_start_pressed() -> void:
	AudioManager.play_ui_click()

	if not is_hosting:
		return

	status_label.text = "Starting game..."
	start_button.disabled = true

	# Request game start through NetworkManager
	NetworkManager.request_start_game()

	# Transition to game scene
	# TODO: Replace with actual game scene
	await get_tree().create_timer(0.5).timeout
	_load_game_scene()


func _on_ready_pressed() -> void:
	AudioManager.play_ui_click()

	local_ready = not local_ready
	ready_button.text = "Not Ready" if local_ready else "Ready"

	var local_id = NetworkManager.get_local_player_id()
	player_ready_states[local_id] = local_ready

	# Notify other players
	_sync_ready_state.rpc(local_id, local_ready)

	_update_player_list()


@rpc("any_peer", "reliable")
func _sync_ready_state(player_id: int, is_ready: bool) -> void:
	player_ready_states[player_id] = is_ready
	_update_player_list()

	# Update start button for host
	if is_hosting:
		start_button.disabled = NetworkManager.get_player_count() < 2 or not _all_players_ready()


func _all_players_ready() -> bool:
	if player_ready_states.is_empty():
		return false

	for peer_id in NetworkManager.connected_players:
		if peer_id == 1:  # Host is always ready
			continue
		if not player_ready_states.get(peer_id, false):
			return false

	return true


func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	NetworkManager.disconnect_from_game()
	_return_to_menu()


func _return_to_menu() -> void:
	var menu_scene = load("res://src/ui/MainMenu.tscn")
	get_tree().root.add_child(menu_scene.instantiate())
	queue_free()


func _update_player_list() -> void:
	# Clear existing items
	for child in player_list_container.get_children():
		child.queue_free()

	# Add player items
	for peer_id in NetworkManager.connected_players:
		var player_name = NetworkManager.connected_players[peer_id]
		var is_ready = player_ready_states.get(peer_id, false)
		var is_host_player = peer_id == 1

		_add_player_list_item(peer_id, player_name, is_ready, is_host_player)


func _add_player_list_item(peer_id: int, player_name: String, is_ready: bool, is_host_player: bool) -> void:
	var item = HBoxContainer.new()
	item.custom_minimum_size = Vector2(0, 40)

	# Player name label
	var name_label = Label.new()
	name_label.text = player_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)

	# Host indicator
	if is_host_player:
		var host_label = Label.new()
		host_label.text = "[HOST]"
		host_label.add_theme_color_override("font_color", Color(0.494, 0.851, 0.341))
		item.add_child(host_label)

	# Ready indicator
	var ready_indicator = Label.new()
	if is_host_player:
		ready_indicator.text = "Ready"
		ready_indicator.add_theme_color_override("font_color", Color(0.494, 0.851, 0.341))
	elif is_ready:
		ready_indicator.text = "Ready"
		ready_indicator.add_theme_color_override("font_color", Color(0.494, 0.851, 0.341))
	else:
		ready_indicator.text = "Not Ready"
		ready_indicator.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))

	item.add_child(ready_indicator)

	player_list_container.add_child(item)


func _load_game_scene() -> void:
	get_tree().change_scene_to_file("res://src/Game.tscn")
