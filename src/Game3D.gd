extends Node3D
class_name Game3D
## Game3D - Main 3D game scene connecting all systems
## Manages match flow, spawns players, generates dungeon, displays HUD

signal match_started()
signal match_ended(winner_id: int)

# Scene references
const PLAYER_SCENE: PackedScene = preload("res://src/player3d/Player3D.tscn")
const HUD_SCENE: PackedScene = preload("res://src/ui/HUD.tscn")

# Child node references
@onready var dungeon: Node3D = $Dungeon3D
@onready var player_container: Node3D = $PlayerContainer

# Game state
var local_player: CharacterBody3D = null
var players: Dictionary = {}  # player_id -> Player3D node
var hud: CanvasLayer = null
var opponent_tracker: Control = null
var is_match_active: bool = false


func _ready() -> void:
	# Connect to GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.puzzle_completed.connect(_on_puzzle_completed)

	# Connect to dungeon signals
	if dungeon:
		dungeon.dungeon_generated.connect(_on_dungeon_generated)
		dungeon.room_changed.connect(_on_room_changed)
		dungeon.dungeon_completed.connect(_on_dungeon_completed)

	# Capture mouse for FPS controls
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Initialize match
	_setup_match()


func _input(event: InputEvent) -> void:
	# ESC to release/capture mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _setup_match() -> void:
	# Create HUD
	hud = HUD_SCENE.instantiate()
	add_child(hud)

	# Create opponent tracker
	var tracker_scene = load("res://src/ui/OpponentTracker.tscn")
	if tracker_scene:
		opponent_tracker = tracker_scene.instantiate()
		add_child(opponent_tracker)

	# Generate dungeon with match seed
	var seed_value = GameManager.get_match_seed()
	if seed_value == 0:
		seed_value = randi()
		GameManager.match_seed = seed_value

	if dungeon and dungeon.has_method("generate_dungeon"):
		dungeon.generate_dungeon(seed_value)

	# Spawn players
	_spawn_players()

	# Start match
	_start_match()


func _spawn_players() -> void:
	if NetworkManager.is_multiplayer_active():
		for player_id in NetworkManager.connected_players:
			_spawn_player(player_id)
	else:
		_spawn_player(1)


func _spawn_player(player_id: int) -> void:
	var player = PLAYER_SCENE.instantiate()
	player.name = "Player3D_%d" % player_id

	# Set multiplayer authority
	if NetworkManager.is_multiplayer_active():
		player.set_multiplayer_authority(player_id)

	# Set player ID
	if player.has_method("set_player_id"):
		player.set_player_id(player_id)

	# Get spawn position from dungeon
	var spawn_pos = Vector3.ZERO
	if dungeon and dungeon.has_method("get_player_spawn_position"):
		spawn_pos = dungeon.get_player_spawn_position()

	player.global_position = spawn_pos

	# Track local player
	var is_local = (player_id == NetworkManager.get_local_player_id()) or (player_id == 1 and not NetworkManager.is_multiplayer_active())

	if is_local:
		local_player = player
		# Initialize HUD
		if hud and hud.has_method("initialize"):
			hud.initialize(player_id)
		# Initialize opponent tracker
		if opponent_tracker and opponent_tracker.has_method("initialize"):
			opponent_tracker.initialize(player_id)
		# Enable camera only for local player
		var camera = player.get_node_or_null("Head/Camera3D")
		if camera:
			camera.current = true
	else:
		# Disable camera for remote players
		var camera = player.get_node_or_null("Head/Camera3D")
		if camera:
			camera.current = false

	# Connect signals
	if player.has_signal("interaction_triggered"):
		player.interaction_triggered.connect(_on_player_interaction)

	player_container.add_child(player)
	players[player_id] = player

	print("[Game3D] Spawned player %d (local: %s)" % [player_id, is_local])


func _start_match() -> void:
	is_match_active = true
	GameManager.change_state(GameManager.GameState.PUZZLE_PHASE)

	# Activate first room
	if dungeon and dungeon.has_method("get_current_room"):
		var room = dungeon.get_current_room()
		if room and room.has_method("activate"):
			room.activate()

	print("[Game3D] Match started")
	match_started.emit()


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PUZZLE_PHASE:
			AudioManager.play_music(AudioManager.MusicTrack.PUZZLE)
		GameManager.GameState.ARENA_PHASE:
			AudioManager.play_music(AudioManager.MusicTrack.ARENA)
		GameManager.GameState.GAME_OVER:
			is_match_active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_puzzle_completed(player_id: int, puzzle_id: String, time_taken: float) -> void:
	if hud and hud.has_method("show_message"):
		if player_id == NetworkManager.get_local_player_id():
			hud.show_message("Puzzle solved!")

	# Broadcast progress to opponents
	if opponent_tracker and opponent_tracker.has_method("broadcast_progress"):
		var room_index = 0
		if dungeon:
			room_index = dungeon.current_room_index
		opponent_tracker.broadcast_progress(room_index, "Solved puzzle")


func _on_dungeon_generated(room_count: int) -> void:
	print("[Game3D] Dungeon generated with %d rooms" % room_count)


func _on_room_changed(old_room: int, new_room: int) -> void:
	print("[Game3D] Room changed: %d -> %d" % [old_room, new_room])

	# Teleport local player to new room spawn
	if local_player and dungeon:
		var room = dungeon.get_current_room()
		if room and room.has_method("get_player_spawn_position"):
			local_player.global_position = room.get_player_spawn_position()

		if room and room.has_method("activate"):
			room.activate()

	# Broadcast progress
	if opponent_tracker and opponent_tracker.has_method("broadcast_progress"):
		opponent_tracker.broadcast_progress(new_room, "Entered room")


func _on_dungeon_completed(total_time: float) -> void:
	print("[Game3D] Dungeon completed in %.2f seconds" % total_time)


func _on_player_interaction(interactable: Node) -> void:
	# Handle door interactions
	if interactable.is_in_group("door"):
		var direction = interactable.get("direction") if "direction" in interactable else "forward"
		if dungeon and dungeon.has_method("transition_to_next_room"):
			dungeon.transition_to_next_room()


func return_to_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for player_id in players:
		if players[player_id]:
			players[player_id].queue_free()
	players.clear()
	if hud:
		hud.queue_free()
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")
