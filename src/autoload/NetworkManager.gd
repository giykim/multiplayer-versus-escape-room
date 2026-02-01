extends Node
## NetworkManager - Multiplayer networking singleton
## Handles lobby, connections, and game state synchronization

signal connection_succeeded()
signal connection_failed()
signal server_disconnected()
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal lobby_updated(player_list: Array)
signal game_started()  # Emitted when all peers should transition to game scene

const DEFAULT_PORT: int = 7777
const MAX_CLIENTS: int = 3  # Plus host = 4 players

var peer: ENetMultiplayerPeer = null
var is_host: bool = false
var local_player_id: int = 0
var connected_players: Dictionary = {}  # peer_id -> player_name


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("[NetworkManager] Initialized")


func host_game(port: int = DEFAULT_PORT, player_name: String = "Host") -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CLIENTS)

	if error != OK:
		print("[NetworkManager] Failed to create server: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_host = true
	local_player_id = 1  # Host is always ID 1

	# Register host as player
	connected_players[1] = player_name
	GameManager.register_player(1, player_name)

	print("[NetworkManager] Hosting game on port %d as '%s'" % [port, player_name])
	lobby_updated.emit(connected_players.values())
	return OK


func join_game(address: String, port: int = DEFAULT_PORT, player_name: String = "Player") -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)

	if error != OK:
		print("[NetworkManager] Failed to connect: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_host = false

	# Store name to send after connection
	connected_players[0] = player_name  # Temporary, will be replaced with actual ID

	print("[NetworkManager] Connecting to %s:%d as '%s'" % [address, port, player_name])
	return OK


func disconnect_from_game() -> void:
	if peer:
		peer.close()
		peer = null

	multiplayer.multiplayer_peer = null
	is_host = false
	local_player_id = 0
	connected_players.clear()

	print("[NetworkManager] Disconnected from game")


func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] Peer connected: %d" % peer_id)
	player_connected.emit(peer_id)

	if is_host:
		# Host sends current lobby state to new player
		_send_lobby_state.rpc_id(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] Peer disconnected: %d" % peer_id)

	if connected_players.has(peer_id):
		connected_players.erase(peer_id)
		GameManager.unregister_player(peer_id)

	player_disconnected.emit(peer_id)
	lobby_updated.emit(connected_players.values())


func _on_connected_to_server() -> void:
	local_player_id = multiplayer.get_unique_id()
	var player_name = connected_players.get(0, "Player")
	connected_players.erase(0)
	connected_players[local_player_id] = player_name

	print("[NetworkManager] Connected to server with ID: %d" % local_player_id)

	# Register with server
	_register_with_server.rpc_id(1, player_name)

	connection_succeeded.emit()


func _on_connection_failed() -> void:
	print("[NetworkManager] Connection failed")
	disconnect_from_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("[NetworkManager] Server disconnected")
	disconnect_from_game()
	server_disconnected.emit()


@rpc("any_peer", "reliable")
func _register_with_server(player_name: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	connected_players[sender_id] = player_name
	GameManager.register_player(sender_id, player_name)

	print("[NetworkManager] Player registered: %s (ID: %d)" % [player_name, sender_id])

	# Broadcast updated lobby to all clients
	_sync_lobby.rpc(connected_players)
	lobby_updated.emit(connected_players.values())


@rpc("authority", "reliable")
func _send_lobby_state() -> void:
	_sync_lobby.rpc(connected_players)


@rpc("authority", "reliable")
func _sync_lobby(players: Dictionary) -> void:
	connected_players = players

	# Register all players with GameManager
	for peer_id in players:
		if not GameManager.players.has(peer_id):
			GameManager.register_player(peer_id, players[peer_id])

	lobby_updated.emit(connected_players.values())


# Game state synchronization

@rpc("authority", "call_local", "reliable")
func start_game(seed_value: int) -> void:
	if GameManager:
		GameManager.start_match(seed_value)


@rpc("authority", "call_local", "reliable")
func _transition_to_game() -> void:
	# All peers (host and clients) receive this and transition to game scene
	game_started.emit()


func request_start_game() -> void:
	if is_host:
		var seed_value = randi()
		# Start game on all peers (including host with call_local)
		start_game.rpc(seed_value)
		# Small delay to ensure seed is synced, then transition all peers
		await get_tree().create_timer(0.3).timeout
		_transition_to_game.rpc()


@rpc("any_peer", "reliable")
func notify_puzzle_completed(puzzle_id: String, time_taken: float) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = local_player_id

	# Host processes locally, then broadcasts to clients only
	if is_host:
		GameManager.on_puzzle_solved(sender_id, puzzle_id, time_taken)
		# Broadcast to clients (excluding host)
		for peer_id in connected_players:
			if peer_id != 1:  # Don't send to host (ourselves)
				_broadcast_puzzle_completion.rpc_id(peer_id, sender_id, puzzle_id, time_taken)


@rpc("authority", "reliable")
func _broadcast_puzzle_completion(player_id: int, puzzle_id: String, time_taken: float) -> void:
	# Only clients should receive this
	if not is_host:
		GameManager.on_puzzle_solved(player_id, puzzle_id, time_taken)


func is_multiplayer_active() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func get_player_count() -> int:
	return connected_players.size()


func get_local_player_id() -> int:
	return local_player_id
