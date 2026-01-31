extends Node2D
class_name Dungeon
## Dungeon - Manages active dungeon instance
## Handles room loading/unloading, player navigation, and progress tracking

# Dungeon lifecycle signals
signal dungeon_generated(room_count: int)
signal room_changed(old_room: int, new_room: int)
signal dungeon_completed(total_time: float)
signal player_progress_updated(player_id: int, room_index: int)

# Room type scenes
const ROOM_SCENES: Dictionary = {
	DungeonGenerator.RoomType.PUZZLE: "res://src/dungeon/RoomTypes/PuzzleRoom.tscn",
	DungeonGenerator.RoomType.TREASURE: "res://src/dungeon/RoomTypes/TreasureRoom.tscn",
	DungeonGenerator.RoomType.SHOP: "res://src/dungeon/Room.tscn",  # Use base for now
	DungeonGenerator.RoomType.TRANSIT: "res://src/dungeon/Room.tscn",
	DungeonGenerator.RoomType.ARENA: "res://src/dungeon/Room.tscn"  # Use base for now
}

# Base room scene fallback
const BASE_ROOM_SCENE: String = "res://src/dungeon/Room.tscn"

# Dungeon configuration
@export var preload_adjacent_rooms: bool = true
@export var unload_distant_rooms: bool = true
@export var max_loaded_rooms: int = 3

# Dungeon state
var layout: DungeonGenerator.DungeonLayout = null
var generator: DungeonGenerator = null
var loaded_rooms: Dictionary = {}  # room_index -> Room node
var current_room_index: int = 0
var dungeon_start_time: float = 0.0
var is_active: bool = false

# Player progress tracking (for multiplayer)
var player_positions: Dictionary = {}  # player_id -> room_index
var player_completion_times: Dictionary = {}  # player_id -> completion_time

# Container for room nodes
var room_container: Node2D = null


func _ready() -> void:
	room_container = Node2D.new()
	room_container.name = "RoomContainer"
	add_child(room_container)


## Generate and initialize a new dungeon
func generate_dungeon(seed_value: int = -1) -> void:
	# Use GameManager seed if not specified
	if seed_value < 0:
		if GameManager:
			seed_value = GameManager.get_match_seed()
		else:
			seed_value = randi()

	# Clean up existing dungeon
	_cleanup_dungeon()

	# Generate layout
	generator = DungeonGenerator.new()
	layout = generator.generate(seed_value)

	# Validate layout
	if not generator.validate_layout(layout):
		push_error("[Dungeon] Generated layout failed validation")
		return

	# Start tracking
	dungeon_start_time = Time.get_ticks_msec() / 1000.0
	is_active = true
	current_room_index = layout.start_room_index

	# Load starting room
	_load_room(current_room_index)

	# Preload adjacent rooms if enabled
	if preload_adjacent_rooms:
		_preload_adjacent_rooms(current_room_index)

	print("[Dungeon] Generated dungeon with %d rooms" % layout.room_count)
	dungeon_generated.emit(layout.room_count)


## Get the current room
func get_current_room() -> Room:
	return loaded_rooms.get(current_room_index)


## Get a specific room (loads if necessary)
func get_room(index: int) -> Room:
	if not layout:
		return null

	if index < 0 or index >= layout.room_count:
		return null

	if not loaded_rooms.has(index):
		_load_room(index)

	return loaded_rooms.get(index)


## Transition a player to a different room
func transition_to_room(room_index: int, player_id: int = 1) -> bool:
	if not layout:
		push_error("[Dungeon] No layout generated")
		return false

	if room_index < 0 or room_index >= layout.room_count:
		push_error("[Dungeon] Invalid room index: %d" % room_index)
		return false

	var old_room_index = current_room_index

	# Check if player can leave current room
	var current_room = get_current_room()
	if current_room:
		var direction = "right" if room_index > old_room_index else "left"
		if not current_room.can_use_door(direction):
			print("[Dungeon] Door is locked, cannot transition")
			return false

		# Notify current room of player exit
		current_room.on_player_exit(player_id)

	# Load new room if needed
	if not loaded_rooms.has(room_index):
		_load_room(room_index)

	var new_room = loaded_rooms.get(room_index)
	if not new_room:
		push_error("[Dungeon] Failed to load room %d" % room_index)
		return false

	# Update current room
	current_room_index = room_index

	# Update room visibility
	_update_room_visibility()

	# Position camera/viewport on new room (if applicable)
	_position_on_room(room_index)

	# Notify new room of player entry
	new_room.on_player_enter(player_id)

	# Update player progress
	player_positions[player_id] = room_index
	player_progress_updated.emit(player_id, room_index)

	# Preload adjacent rooms
	if preload_adjacent_rooms:
		_preload_adjacent_rooms(room_index)

	# Unload distant rooms
	if unload_distant_rooms:
		_unload_distant_rooms(room_index)

	print("[Dungeon] Player %d transitioned from room %d to room %d" % [
		player_id, old_room_index, room_index
	])

	room_changed.emit(old_room_index, room_index)

	# Check if arena reached
	if room_index == layout.arena_room_index:
		_on_player_reached_arena(player_id)

	return true


## Load a room by index
func _load_room(room_index: int) -> Room:
	if loaded_rooms.has(room_index):
		return loaded_rooms[room_index]

	if not layout:
		return null

	var room_data = layout.get_room(room_index)
	if not room_data:
		return null

	# Get appropriate scene for room type
	var scene_path = ROOM_SCENES.get(room_data.type, BASE_ROOM_SCENE)

	# Check if scene exists, fall back to base
	if not ResourceLoader.exists(scene_path):
		print("[Dungeon] Scene not found: %s, using base room" % scene_path)
		scene_path = BASE_ROOM_SCENE

	var room_scene = load(scene_path)
	if not room_scene:
		push_error("[Dungeon] Failed to load room scene: %s" % scene_path)
		return null

	var room = room_scene.instantiate() as Room
	if not room:
		push_error("[Dungeon] Room scene did not instantiate as Room")
		return null

	# Initialize room with data
	room.initialize_from_data(room_data)
	room.name = "Room_%d" % room_index

	# Position room in world space (linear arrangement)
	room.position = Vector2(room_index * Room.ROOM_WIDTH, 0)

	# Connect room signals
	room.room_completed.connect(_on_room_completed.bind(room_index))

	# Add to scene tree
	room_container.add_child(room)
	loaded_rooms[room_index] = room

	# Hide if not current room
	room.visible = (room_index == current_room_index)

	print("[Dungeon] Loaded room %d (%s)" % [
		room_index, DungeonGenerator.get_room_type_name(room_data.type)
	])

	return room


## Unload a room by index
func _unload_room(room_index: int) -> void:
	if not loaded_rooms.has(room_index):
		return

	var room = loaded_rooms[room_index]
	loaded_rooms.erase(room_index)

	if room:
		room.queue_free()

	print("[Dungeon] Unloaded room %d" % room_index)


## Preload rooms adjacent to the given index
func _preload_adjacent_rooms(room_index: int) -> void:
	if not layout:
		return

	var room_data = layout.get_room(room_index)
	if not room_data:
		return

	for direction in room_data.connections:
		var adjacent_index = room_data.connections[direction]
		if not loaded_rooms.has(adjacent_index):
			_load_room(adjacent_index)


## Unload rooms that are far from the current room
func _unload_distant_rooms(current_index: int) -> void:
	var rooms_to_unload: Array[int] = []

	for room_index in loaded_rooms:
		var distance = abs(room_index - current_index)
		if distance > max_loaded_rooms:
			rooms_to_unload.append(room_index)

	for room_index in rooms_to_unload:
		_unload_room(room_index)


## Update room visibility based on current room
func _update_room_visibility() -> void:
	for room_index in loaded_rooms:
		var room = loaded_rooms[room_index]
		if room:
			room.visible = (room_index == current_room_index)


## Position camera/viewport on a room
func _position_on_room(room_index: int) -> void:
	var room = loaded_rooms.get(room_index)
	if not room:
		return

	# Move camera to room position (if camera exists)
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.global_position = room.global_position


## Clean up all dungeon resources
func _cleanup_dungeon() -> void:
	# Unload all rooms
	for room_index in loaded_rooms.keys():
		_unload_room(room_index)

	loaded_rooms.clear()
	player_positions.clear()
	player_completion_times.clear()

	layout = null
	generator = null
	is_active = false
	current_room_index = 0


## Get dungeon elapsed time
func get_elapsed_time() -> float:
	if not is_active:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - dungeon_start_time


## Get formatted elapsed time
func get_elapsed_time_string() -> String:
	var time = get_elapsed_time()
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]


## Get progress through dungeon (0.0 to 1.0)
func get_progress() -> float:
	if not layout or layout.room_count <= 1:
		return 0.0
	return float(current_room_index) / float(layout.room_count - 1)


## Get room data for a given index
func get_room_data(room_index: int) -> DungeonGenerator.RoomData:
	if layout:
		return layout.get_room(room_index)
	return null


## Get total room count
func get_room_count() -> int:
	if layout:
		return layout.room_count
	return 0


## Check if dungeon is completed
func is_dungeon_completed() -> bool:
	return current_room_index == layout.arena_room_index if layout else false


# === Signal Handlers ===

func _on_room_completed(room_index: int) -> void:
	print("[Dungeon] Room %d completed" % room_index)

	# Notify GameManager if needed
	if GameManager:
		# Could track per-room completion here
		pass


func _on_player_reached_arena(player_id: int) -> void:
	var completion_time = get_elapsed_time()
	player_completion_times[player_id] = completion_time

	print("[Dungeon] Player %d reached arena in %.2f seconds" % [
		player_id, completion_time
	])

	# Check if all players have reached arena (multiplayer)
	if _all_players_at_arena():
		dungeon_completed.emit(completion_time)

		# Transition to arena phase
		if GameManager:
			GameManager.change_state(GameManager.GameState.ARENA_PHASE)


func _all_players_at_arena() -> bool:
	if not layout:
		return false

	# In single player, just check current player
	if not NetworkManager or not NetworkManager.has_method("is_multiplayer_active"):
		return current_room_index == layout.arena_room_index

	if not NetworkManager.is_multiplayer_active():
		return current_room_index == layout.arena_room_index

	# In multiplayer, check all players
	for player_id in player_positions:
		if player_positions[player_id] != layout.arena_room_index:
			return false

	return true


## Debug: Print dungeon layout
func debug_print_layout() -> void:
	if not layout:
		print("[Dungeon] No layout generated")
		return

	print("=== Dungeon Layout (Seed: %d) ===" % layout.generation_seed)
	print("Total Rooms: %d" % layout.room_count)
	print("Start Room: %d" % layout.start_room_index)
	print("Arena Room: %d" % layout.arena_room_index)
	print("")

	for room in layout.rooms:
		var type_name = DungeonGenerator.get_room_type_name(room.type)
		var puzzle_info = ""
		if room.type == DungeonGenerator.RoomType.PUZZLE:
			puzzle_info = " [%s]" % room.puzzle_type

		print("  Room %d: %s (diff: %d)%s" % [
			room.index, type_name, room.difficulty, puzzle_info
		])
		print("    Connections: %s" % str(room.connections))

	print("================================")
