extends Node3D
class_name Room3D
## Room3D - Base class for all 3D dungeon rooms
## Manages room state, doors, puzzles, and player interactions in 3D space

# Signals for room lifecycle (same as 2D version)
signal room_entered(player_id: int)
signal room_exited(player_id: int)
signal room_completed()
signal door_state_changed(direction: String, is_locked: bool)
signal puzzle_spawned(puzzle: Node3D)

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

# Room dimensions (10m x 4m x 10m)
const ROOM_WIDTH: float = 10.0
const ROOM_HEIGHT: float = 4.0
const ROOM_DEPTH: float = 10.0
const WALL_THICKNESS: float = 0.3

# Node references
@onready var puzzle_spawn: Marker3D = $PuzzleSpawn if has_node("PuzzleSpawn") else null
@onready var player_spawn: Marker3D = $PlayerSpawn if has_node("PlayerSpawn") else null
@onready var left_door: Area3D = $LeftDoor if has_node("LeftDoor") else null
@onready var right_door: Area3D = $RightDoor if has_node("RightDoor") else null
@onready var room_light: OmniLight3D = $RoomLight if has_node("RoomLight") else null

# Room state
var is_completed: bool = false
var is_locked: bool = true
var current_puzzle: Node3D = null
var players_in_room: Array[int] = []
var puzzle_type: String = ""

# Door states
var doors_locked: Dictionary = {
	"left": false,
	"right": true  # Forward door locked by default
}

# Room type colors for materials
const ROOM_COLORS: Dictionary = {
	RoomType.PUZZLE: Color(0.2, 0.3, 0.4),     # Blue-gray
	RoomType.TREASURE: Color(0.4, 0.35, 0.2),  # Gold-brown
	RoomType.SHOP: Color(0.3, 0.4, 0.3),       # Green
	RoomType.TRANSIT: Color(0.25, 0.25, 0.25), # Dark gray
	RoomType.ARENA: Color(0.4, 0.2, 0.2)       # Red
}


func _ready() -> void:
	_setup_doors()
	_setup_room_color()
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
	_setup_room_color()
	_initialize_room()

	print("[Room3D %d] Initialized as %s (difficulty: %d)" % [
		room_index,
		DungeonGenerator.get_room_type_name(room_data.type),
		difficulty
	])


## Setup door areas and connections
func _setup_doors() -> void:
	if left_door:
		left_door.visible = has_left_door
		left_door.monitoring = has_left_door
		if not left_door.body_entered.is_connected(_on_left_door_entered):
			left_door.body_entered.connect(_on_left_door_entered)

	if right_door:
		right_door.visible = has_right_door
		right_door.monitoring = has_right_door
		if not right_door.body_entered.is_connected(_on_right_door_entered):
			right_door.body_entered.connect(_on_right_door_entered)

	_update_door_visuals()


## Setup room color based on room type
func _setup_room_color() -> void:
	var color = ROOM_COLORS.get(room_type, Color(0.25, 0.25, 0.25))

	# Apply color to all wall meshes
	for child in get_children():
		if child is CSGBox3D:
			var material = StandardMaterial3D.new()
			material.albedo_color = color
			child.material = material


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


## Spawn the puzzle for this room (override in PuzzleRoom3D)
func _spawn_puzzle() -> void:
	pass  # Implemented in PuzzleRoom3D


## Check if forward door should be locked
func _should_lock_forward_door() -> bool:
	match room_type:
		RoomType.PUZZLE:
			return true  # Must solve puzzle
		RoomType.ARENA:
			return true  # Arena has special logic
		_:
			return false  # Other rooms don't lock


## Setup treasure room content (override in TreasureRoom3D)
func _setup_treasure() -> void:
	pass


## Setup shop room content
func _setup_shop() -> void:
	pass


## Setup arena room
func _setup_arena() -> void:
	pass


## Activate the room (start puzzle, enable interactions)
func activate() -> void:
	print("[Room3D %d] Activated" % room_index)

	# Start puzzle if exists
	if current_puzzle and current_puzzle.has_method("start_puzzle"):
		if current_puzzle.has_method("get") and not current_puzzle.get("is_active"):
			current_puzzle.start_puzzle()


## Update door visual states
func _update_door_visuals() -> void:
	# Update left door
	if left_door:
		var left_mesh = left_door.get_node_or_null("MeshInstance3D")
		if left_mesh and left_mesh is MeshInstance3D:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color.RED if doors_locked["left"] else Color.GREEN
			material.emission_enabled = true
			material.emission = material.albedo_color
			material.emission_energy_multiplier = 0.5
			left_mesh.material_override = material

	# Update right door
	if right_door:
		var right_mesh = right_door.get_node_or_null("MeshInstance3D")
		if right_mesh and right_mesh is MeshInstance3D:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color.RED if doors_locked["right"] else Color.GREEN
			material.emission_enabled = true
			material.emission = material.albedo_color
			material.emission_energy_multiplier = 0.5
			right_mesh.material_override = material


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
	print("[Room3D %d] Completed" % room_index)


## Called when a player enters the room
func on_player_enter(player_id: int) -> void:
	if not players_in_room.has(player_id):
		players_in_room.append(player_id)
		room_entered.emit(player_id)
		print("[Room3D %d] Player %d entered" % [room_index, player_id])

		# Start puzzle when player enters
		if current_puzzle and current_puzzle.has_method("start_puzzle"):
			if current_puzzle.has_method("get") and not current_puzzle.get("is_active"):
				current_puzzle.start_puzzle()


## Called when a player exits the room
func on_player_exit(player_id: int) -> void:
	players_in_room.erase(player_id)
	room_exited.emit(player_id)
	print("[Room3D %d] Player %d exited" % [room_index, player_id])


## Get player spawn position
func get_player_spawn_position() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return global_position


## Check if a door can be used
func can_use_door(direction: String) -> bool:
	if not doors_locked.has(direction):
		return false
	return not doors_locked[direction]


# === Signal Handlers ===

func _on_left_door_entered(body: Node3D) -> void:
	if doors_locked["left"]:
		return

	# Check if it's a player
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		# Notify dungeon manager of room transition
		if get_parent() and get_parent().has_method("transition_to_room"):
			get_parent().transition_to_room(room_index - 1, player_id)


func _on_right_door_entered(body: Node3D) -> void:
	if doors_locked["right"]:
		return

	# Check if it's a player
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		# Notify dungeon manager of room transition
		if get_parent() and get_parent().has_method("transition_to_room"):
			get_parent().transition_to_room(room_index + 1, player_id)


func _on_puzzle_solved(puzzle_id: String, time_taken: float) -> void:
	print("[Room3D %d] Puzzle '%s' solved in %.2fs" % [room_index, puzzle_id, time_taken])
	complete_room()


func _on_puzzle_failed(puzzle_id: String) -> void:
	print("[Room3D %d] Puzzle '%s' failed" % [room_index, puzzle_id])
