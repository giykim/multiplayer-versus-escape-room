extends Node2D
class_name Room
## Room - Base class for all dungeon rooms
## Manages room state, doors, puzzles, and player interactions

# Signals for room lifecycle
signal room_entered(player_id: int)
signal room_exited(player_id: int)
signal room_completed()
signal door_state_changed(direction: String, is_locked: bool)
signal puzzle_spawned(puzzle: BasePuzzle)

# Room type enum (mirrors DungeonGenerator.RoomType)
enum RoomType {
	PUZZLE,
	TREASURE,
	SHOP,
	TRANSIT,
	ARENA
}

# Room configuration
@export var room_type: RoomType = RoomType.TRANSIT
@export var room_index: int = 0
@export var room_seed: int = 0
@export var difficulty: int = 1

# Door configuration
@export var has_left_door: bool = true
@export var has_right_door: bool = true

# Node references
@onready var puzzle_spawn: Marker2D = $PuzzleSpawn if has_node("PuzzleSpawn") else null
@onready var player_spawn: Marker2D = $PlayerSpawn if has_node("PlayerSpawn") else null
@onready var left_door: Area2D = $LeftDoor if has_node("LeftDoor") else null
@onready var right_door: Area2D = $RightDoor if has_node("RightDoor") else null
@onready var background: ColorRect = $Background if has_node("Background") else null

# Room state
var is_completed: bool = false
var is_locked: bool = true  # Doors locked until puzzle solved
var current_puzzle: BasePuzzle = null
var players_in_room: Array[int] = []
var puzzle_type: String = ""

# Door states
var doors_locked: Dictionary = {
	"left": false,
	"right": true  # Forward door locked by default
}

# Room dimensions
const ROOM_WIDTH: float = 1920.0
const ROOM_HEIGHT: float = 1080.0

# Puzzle scene paths (extend as more puzzles are created)
const PUZZLE_SCENES: Dictionary = {
	"sliding_tile": "res://src/puzzles/logic/SlidingTilePuzzle.tscn",
	"pattern_match": "res://src/puzzles/logic/PatternMatchPuzzle.tscn",
	"wire_connect": "res://src/puzzles/logic/WireConnectPuzzle.tscn",
	"sequence_memory": "res://src/puzzles/logic/SequenceMemoryPuzzle.tscn",
	"lock_pick": "res://src/puzzles/logic/LockPickPuzzle.tscn"
}


func _ready() -> void:
	_setup_doors()
	_setup_background()
	_initialize_room()


## Initialize room with data from DungeonGenerator
func initialize_from_data(room_data: DungeonGenerator.RoomData) -> void:
	room_index = room_data.index
	room_type = room_data.type as RoomType
	room_seed = room_data.seed_offset
	difficulty = room_data.difficulty
	puzzle_type = room_data.puzzle_type

	# Configure doors based on connections
	has_left_door = room_data.connections.has("left")
	has_right_door = room_data.connections.has("right")

	# Update door locks
	doors_locked["left"] = false  # Back door always unlocked
	doors_locked["right"] = _should_lock_forward_door()

	_setup_doors()
	_initialize_room()

	print("[Room %d] Initialized as %s (difficulty: %d)" % [
		room_index,
		DungeonGenerator.get_room_type_name(room_data.type),
		difficulty
	])


## Setup door areas and collision
func _setup_doors() -> void:
	if left_door:
		left_door.visible = has_left_door
		left_door.monitoring = has_left_door
		if left_door.has_signal("body_entered"):
			if not left_door.body_entered.is_connected(_on_left_door_entered):
				left_door.body_entered.connect(_on_left_door_entered)

	if right_door:
		right_door.visible = has_right_door
		right_door.monitoring = has_right_door
		if right_door.has_signal("body_entered"):
			if not right_door.body_entered.is_connected(_on_right_door_entered):
				right_door.body_entered.connect(_on_right_door_entered)

	_update_door_visuals()


## Setup background placeholder
func _setup_background() -> void:
	if background:
		background.size = Vector2(ROOM_WIDTH, ROOM_HEIGHT)
		background.position = Vector2(-ROOM_WIDTH / 2, -ROOM_HEIGHT / 2)

		# Color based on room type
		match room_type:
			RoomType.PUZZLE:
				background.color = Color(0.2, 0.3, 0.4)  # Blue-gray
			RoomType.TREASURE:
				background.color = Color(0.4, 0.35, 0.2)  # Gold-brown
			RoomType.SHOP:
				background.color = Color(0.3, 0.4, 0.3)  # Green
			RoomType.TRANSIT:
				background.color = Color(0.25, 0.25, 0.25)  # Dark gray
			RoomType.ARENA:
				background.color = Color(0.4, 0.2, 0.2)  # Red


## Initialize room-specific content
func _initialize_room() -> void:
	match room_type:
		RoomType.PUZZLE:
			_spawn_puzzle()
		RoomType.TREASURE:
			_setup_treasure()
		RoomType.SHOP:
			_setup_shop()
		RoomType.TRANSIT:
			pass  # Empty transition room
		RoomType.ARENA:
			_setup_arena()


## Spawn the puzzle for this room
func _spawn_puzzle() -> void:
	if puzzle_type.is_empty():
		push_warning("[Room %d] No puzzle type specified" % room_index)
		return

	if not PUZZLE_SCENES.has(puzzle_type):
		push_warning("[Room %d] Unknown puzzle type: %s" % [room_index, puzzle_type])
		return

	var puzzle_scene_path = PUZZLE_SCENES[puzzle_type]

	# Check if scene exists
	if not ResourceLoader.exists(puzzle_scene_path):
		push_warning("[Room %d] Puzzle scene not found: %s" % [room_index, puzzle_scene_path])
		return

	var puzzle_scene = load(puzzle_scene_path)
	if puzzle_scene:
		current_puzzle = puzzle_scene.instantiate() as BasePuzzle
		if current_puzzle:
			# Position puzzle at spawn point
			if puzzle_spawn:
				current_puzzle.position = puzzle_spawn.position
			else:
				current_puzzle.position = Vector2.ZERO

			# Initialize puzzle with room seed
			var puzzle_seed_value = room_seed
			if GameManager:
				puzzle_seed_value = GameManager.get_match_seed() + room_seed

			add_child(current_puzzle)
			current_puzzle.initialize(puzzle_seed_value, difficulty)

			# Connect puzzle signals
			current_puzzle.puzzle_solved.connect(_on_puzzle_solved)
			current_puzzle.puzzle_failed.connect(_on_puzzle_failed)

			puzzle_spawned.emit(current_puzzle)
			print("[Room %d] Spawned puzzle: %s" % [room_index, puzzle_type])


## Check if forward door should be locked
func _should_lock_forward_door() -> bool:
	match room_type:
		RoomType.PUZZLE:
			return true  # Must solve puzzle
		RoomType.ARENA:
			return true  # Arena has special logic
		_:
			return false  # Other rooms don't lock


## Setup treasure room content
func _setup_treasure() -> void:
	# Placeholder - will spawn treasure/coin pickups
	pass


## Setup shop room content
func _setup_shop() -> void:
	# Placeholder - will spawn shop UI/NPC
	pass


## Setup arena room
func _setup_arena() -> void:
	# Placeholder - arena specific setup
	pass


## Activate the room (start puzzle, enable interactions)
func activate() -> void:
	print("[Room %d] Activated" % room_index)

	# Start puzzle if exists
	if current_puzzle and not current_puzzle.is_active:
		current_puzzle.start_puzzle()


## Update door visual states
func _update_door_visuals() -> void:
	# Update left door
	if left_door:
		var left_sprite = left_door.get_node_or_null("Sprite2D")
		if left_sprite and left_sprite is Sprite2D:
			left_sprite.modulate = Color.RED if doors_locked["left"] else Color.GREEN

	# Update right door
	if right_door:
		var right_sprite = right_door.get_node_or_null("Sprite2D")
		if right_sprite and right_sprite is Sprite2D:
			right_sprite.modulate = Color.RED if doors_locked["right"] else Color.GREEN


## Lock or unlock a door
func set_door_locked(direction: String, locked: bool) -> void:
	if doors_locked.has(direction):
		doors_locked[direction] = locked
		_update_door_visuals()
		door_state_changed.emit(direction, locked)


## Complete the room (unlock forward door)
func complete_room() -> void:
	if is_completed:
		return

	is_completed = true
	set_door_locked("right", false)
	room_completed.emit()
	print("[Room %d] Completed" % room_index)


## Called when a player enters the room
func on_player_enter(player_id: int) -> void:
	if not players_in_room.has(player_id):
		players_in_room.append(player_id)
		room_entered.emit(player_id)
		print("[Room %d] Player %d entered" % [room_index, player_id])

		# Start puzzle when player enters
		if current_puzzle and not current_puzzle.is_active:
			current_puzzle.start_puzzle()


## Called when a player exits the room
func on_player_exit(player_id: int) -> void:
	players_in_room.erase(player_id)
	room_exited.emit(player_id)
	print("[Room %d] Player %d exited" % [room_index, player_id])


## Get player spawn position
func get_player_spawn_position() -> Vector2:
	if player_spawn:
		return player_spawn.global_position
	return global_position


## Check if a door can be used
func can_use_door(direction: String) -> bool:
	if not doors_locked.has(direction):
		return false
	return not doors_locked[direction]


# === Signal Handlers ===

func _on_left_door_entered(body: Node2D) -> void:
	if doors_locked["left"]:
		return

	# Check if it's a player
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		# Notify dungeon manager of room transition
		if get_parent() and get_parent().has_method("transition_to_room"):
			get_parent().transition_to_room(room_index - 1, player_id)


func _on_right_door_entered(body: Node2D) -> void:
	if doors_locked["right"]:
		return

	# Check if it's a player
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		# Notify dungeon manager of room transition
		if get_parent() and get_parent().has_method("transition_to_room"):
			get_parent().transition_to_room(room_index + 1, player_id)


func _on_puzzle_solved(puzzle_id: String, time_taken: float) -> void:
	print("[Room %d] Puzzle '%s' solved in %.2fs" % [room_index, puzzle_id, time_taken])
	complete_room()


func _on_puzzle_failed(puzzle_id: String) -> void:
	print("[Room %d] Puzzle '%s' failed" % [room_index, puzzle_id])
	# Could add fail penalty here
