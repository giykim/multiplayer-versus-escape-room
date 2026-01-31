extends Node2D
class_name Game
## Game - Main game scene that connects all systems
## Manages match flow, spawns players, generates dungeon, and displays HUD

signal match_started()
signal match_ended(winner_id: int)

# Scene references
const PLAYER_SCENE: PackedScene = preload("res://src/player/Player.tscn")
const HUD_SCENE: PackedScene = preload("res://src/ui/HUD.tscn")

# Child node references
@onready var dungeon: Dungeon = $Dungeon
@onready var player_container: Node2D = $PlayerContainer

# Game state
var local_player: Player = null
var players: Dictionary = {}  # player_id -> Player node
var hud: CanvasLayer = null
var is_match_active: bool = false


func _ready() -> void:
	# Connect to GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.puzzle_completed.connect(_on_puzzle_completed)

	# Connect to dungeon signals
	dungeon.dungeon_generated.connect(_on_dungeon_generated)
	dungeon.room_changed.connect(_on_room_changed)
	dungeon.dungeon_completed.connect(_on_dungeon_completed)

	# Initialize match
	_setup_match()


func _setup_match() -> void:
	# Create HUD
	hud = HUD_SCENE.instantiate()
	add_child(hud)

	# Generate dungeon with match seed
	var seed_value = GameManager.get_match_seed()
	if seed_value == 0:
		seed_value = randi()
		GameManager.match_seed = seed_value

	dungeon.generate_dungeon(seed_value)

	# Spawn players
	_spawn_players()

	# Start match
	_start_match()


func _spawn_players() -> void:
	if NetworkManager.is_multiplayer_active():
		# Multiplayer: spawn all connected players
		for player_id in NetworkManager.connected_players:
			_spawn_player(player_id)
	else:
		# Single player: spawn local player
		_spawn_player(1)


func _spawn_player(player_id: int) -> void:
	var player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player_%d" % player_id

	# Set multiplayer authority
	if NetworkManager.is_multiplayer_active():
		player.set_multiplayer_authority(player_id)

	# Get spawn position from current room
	var current_room = dungeon.get_current_room()
	if current_room:
		player.global_position = current_room.get_player_spawn_position()
	else:
		player.global_position = Vector2.ZERO

	# Track local player
	var is_local = (player_id == NetworkManager.get_local_player_id()) or (player_id == 1 and not NetworkManager.is_multiplayer_active())

	if is_local:
		local_player = player
		# Initialize HUD with local player
		if hud and hud.has_method("initialize"):
			hud.initialize(player_id)

	# Connect player signals
	player.interaction_triggered.connect(_on_player_interaction)

	# Add to scene
	player_container.add_child(player)
	players[player_id] = player

	print("[Game] Spawned player %d (local: %s)" % [player_id, is_local])


func _start_match() -> void:
	is_match_active = true

	# Change game state to puzzle phase
	GameManager.change_state(GameManager.GameState.PUZZLE_PHASE)

	# Start first room's puzzle
	var current_room = dungeon.get_current_room()
	if current_room:
		current_room.activate()

	print("[Game] Match started with seed: %d" % GameManager.get_match_seed())
	match_started.emit()


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PUZZLE_PHASE:
			AudioManager.play_music(AudioManager.MusicTrack.PUZZLE)
		GameManager.GameState.ARENA_PHASE:
			AudioManager.play_music(AudioManager.MusicTrack.ARENA)
			_start_arena_phase()
		GameManager.GameState.GAME_OVER:
			is_match_active = false


func _on_puzzle_completed(player_id: int, puzzle_id: String, time_taken: float) -> void:
	# Update HUD
	if hud and hud.has_method("show_message"):
		if player_id == NetworkManager.get_local_player_id():
			hud.show_message("Puzzle solved!")
		else:
			var player_name = NetworkManager.connected_players.get(player_id, "Player %d" % player_id)
			hud.show_message("%s solved a puzzle!" % player_name)

	# Unlock door in current room
	var current_room = dungeon.get_current_room()
	if current_room:
		current_room.unlock_exit_door()


func _on_dungeon_generated(room_count: int) -> void:
	print("[Game] Dungeon generated with %d rooms" % room_count)


func _on_room_changed(old_room: int, new_room: int) -> void:
	print("[Game] Room changed: %d -> %d" % [old_room, new_room])

	# Activate new room's puzzle
	var room = dungeon.get_current_room()
	if room:
		room.activate()

	# Reposition local player at new room's spawn
	if local_player:
		var spawn_pos = room.get_player_spawn_position() if room else Vector2.ZERO
		local_player.global_position = spawn_pos


func _on_dungeon_completed(total_time: float) -> void:
	print("[Game] Dungeon completed in %.2f seconds" % total_time)


func _on_player_interaction(interactable: Node2D) -> void:
	# Check if interacting with a door
	if interactable.is_in_group("door"):
		_handle_door_interaction(interactable)


func _handle_door_interaction(door: Node2D) -> void:
	var direction = door.get("direction") if door.has_method("get") else "right"
	var current_index = dungeon.current_room_index

	var target_index = current_index
	if direction == "right" or direction == "forward":
		target_index = current_index + 1
	elif direction == "left" or direction == "back":
		target_index = current_index - 1

	var player_id = NetworkManager.get_local_player_id() if NetworkManager.is_multiplayer_active() else 1
	dungeon.transition_to_room(target_index, player_id)


func _start_arena_phase() -> void:
	print("[Game] Arena phase started - combat begins!")
	# TODO: Implement arena combat
	# For now, just declare the first player to arrive as winner
	var winner_id = 1
	if not dungeon.player_completion_times.is_empty():
		var fastest_time = INF
		for player_id in dungeon.player_completion_times:
			if dungeon.player_completion_times[player_id] < fastest_time:
				fastest_time = dungeon.player_completion_times[player_id]
				winner_id = player_id

	# Delay before ending
	await get_tree().create_timer(3.0).timeout
	_end_match(winner_id)


func _end_match(winner_id: int) -> void:
	is_match_active = false
	GameManager.change_state(GameManager.GameState.GAME_OVER)

	print("[Game] Match ended - Winner: Player %d" % winner_id)
	match_ended.emit(winner_id)

	# Show winner in HUD
	if hud and hud.has_method("show_message"):
		var winner_name = NetworkManager.connected_players.get(winner_id, "Player %d" % winner_id)
		hud.show_message("%s wins!" % winner_name, 5.0)


func _process(_delta: float) -> void:
	if not is_match_active:
		return

	# Update HUD with dungeon progress
	if hud and hud.has_method("_update_puzzle_progress"):
		hud._update_puzzle_progress(dungeon.current_room_index, dungeon.get_room_count())


## Get the local player node
func get_local_player() -> Player:
	return local_player


## Get a player by ID
func get_player(player_id: int) -> Player:
	return players.get(player_id)


## Clean up and return to menu
func return_to_menu() -> void:
	# Clean up
	for player_id in players:
		if players[player_id]:
			players[player_id].queue_free()
	players.clear()

	if hud:
		hud.queue_free()

	# Load main menu
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")
