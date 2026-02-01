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

# Total room count (set by dungeon)
var total_rooms: int = 5

# Room state
var is_completed: bool = false
var is_locked: bool = true
var current_puzzle: Node3D = null
var players_in_room: Array[int] = []
var puzzle_type: String = ""

# Reference to parent dungeon (set during initialization)
var dungeon: Node3D = null

# Door states
var doors_locked: Dictionary = {
	"left": false,
	"right": true  # Forward door locked by default
}

# Spawn positions at each door (set relative to room center)
const LEFT_DOOR_SPAWN: Vector3 = Vector3(-4.0, 1.0, 0)   # Just inside left door
const RIGHT_DOOR_SPAWN: Vector3 = Vector3(4.0, 1.0, 0)   # Just inside right door
const CENTER_SPAWN: Vector3 = Vector3(0, 1.0, 3)          # Center of room (fallback)

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
	_update_door_labels()
	_initialize_room()

	print("[Room3D %d] Initialized as %s (difficulty: %d)" % [
		room_index,
		DungeonGenerator.get_room_type_name(room_data.type),
		difficulty
	])


## Update door labels based on room position
func _update_door_labels() -> void:
	# Update left door label
	if left_door:
		var label = left_door.get_node_or_null("DoorLabel")
		if label and label is Label3D:
			if has_left_door:
				label.text = "<< BACK (Room %d)" % room_index
				label.visible = true
			else:
				label.visible = false

	# Update right door label
	if right_door:
		var label = right_door.get_node_or_null("DoorLabel")
		if label and label is Label3D:
			if has_right_door:
				label.text = "NEXT (Room %d) >>" % (room_index + 2)
				label.visible = true
			else:
				label.visible = false


## Setup door areas and connections
func _setup_doors() -> void:
	if left_door:
		left_door.visible = has_left_door
		left_door.monitoring = has_left_door
		if not left_door.body_entered.is_connected(_on_left_door_entered):
			left_door.body_entered.connect(_on_left_door_entered)
		# Create door blocker if it doesn't exist
		_create_door_blocker(left_door, "left")

	if right_door:
		right_door.visible = has_right_door
		right_door.monitoring = has_right_door
		if not right_door.body_entered.is_connected(_on_right_door_entered):
			right_door.body_entered.connect(_on_right_door_entered)
		# Create door blocker if it doesn't exist
		_create_door_blocker(right_door, "right")

	# Handle walls when door doesn't exist
	_update_wall_cutouts()
	_update_door_visuals()


## Create a StaticBody3D to block player when door is locked
func _create_door_blocker(door: Area3D, direction: String) -> void:
	var blocker_name = "DoorBlocker"
	if door.has_node(blocker_name):
		return  # Already exists

	var blocker = StaticBody3D.new()
	blocker.name = blocker_name
	blocker.collision_layer = 2  # World geometry layer

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.3, 2.3, 1.4)
	shape.shape = box
	blocker.add_child(shape)

	door.add_child(blocker)


## Update wall cutouts based on whether doors exist
func _update_wall_cutouts() -> void:
	# If no left door, fill the cutout
	var left_wall = get_node_or_null("LeftWallCombo")
	if left_wall:
		var cutout = left_wall.get_node_or_null("DoorCutout")
		if cutout:
			cutout.visible = has_left_door
			# If no door, we need to fill the hole - hide the cutout operation
			if not has_left_door:
				cutout.operation = 0  # Union instead of subtraction

	# If no right door, fill the cutout
	var right_wall = get_node_or_null("RightWallCombo")
	if right_wall:
		var cutout = right_wall.get_node_or_null("DoorCutout")
		if cutout:
			cutout.visible = has_right_door
			if not has_right_door:
				cutout.operation = 0  # Union instead of subtraction


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
	if left_door and has_left_door:
		var door_panel = left_door.get_node_or_null("DoorPanel")
		var door_blocker = left_door.get_node_or_null("DoorBlocker")

		if door_panel and door_panel is MeshInstance3D:
			var material = StandardMaterial3D.new()
			if doors_locked["left"]:
				material.albedo_color = Color(0.5, 0.1, 0.1)  # Red - locked
				material.emission_enabled = true
				material.emission = Color(0.6, 0, 0)
				material.emission_energy_multiplier = 0.3
				door_panel.visible = true
				if door_blocker:
					door_blocker.collision_layer = 2  # Enable collision
			else:
				material.albedo_color = Color(0.1, 0.5, 0.1)  # Green - unlocked
				material.emission_enabled = true
				material.emission = Color(0, 0.6, 0)
				material.emission_energy_multiplier = 0.3
				# Hide door panel when unlocked (door is open)
				door_panel.visible = false
				if door_blocker:
					door_blocker.collision_layer = 0  # Disable collision
			door_panel.material_override = material

	# Update right door
	if right_door and has_right_door:
		var door_panel = right_door.get_node_or_null("DoorPanel")
		var door_blocker = right_door.get_node_or_null("DoorBlocker")

		if door_panel and door_panel is MeshInstance3D:
			var material = StandardMaterial3D.new()
			if doors_locked["right"]:
				material.albedo_color = Color(0.5, 0.1, 0.1)  # Red - locked
				material.emission_enabled = true
				material.emission = Color(0.6, 0, 0)
				material.emission_energy_multiplier = 0.3
				door_panel.visible = true
				if door_blocker:
					door_blocker.collision_layer = 2  # Enable collision
			else:
				material.albedo_color = Color(0.1, 0.5, 0.1)  # Green - unlocked
				material.emission_enabled = true
				material.emission = Color(0, 0.6, 0)
				material.emission_energy_multiplier = 0.3
				# Hide door panel when unlocked (door is open)
				door_panel.visible = false
				if door_blocker:
					door_blocker.collision_layer = 0  # Disable collision
			door_panel.material_override = material


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


## Get player spawn position based on entry direction
## entry_direction: "left" = entered from left door, "right" = entered from right door, "" = default
func get_player_spawn_position(entry_direction: String = "") -> Vector3:
	var local_spawn: Vector3

	match entry_direction:
		"left":
			# Entered from left door - spawn just inside the left door, facing right
			local_spawn = LEFT_DOOR_SPAWN
		"right":
			# Entered from right door - spawn just inside the right door, facing left
			local_spawn = RIGHT_DOOR_SPAWN
		_:
			# Default spawn at center or marker
			if player_spawn:
				return player_spawn.global_position
			local_spawn = CENTER_SPAWN

	return global_position + local_spawn


## Get the rotation for player based on entry direction
func get_player_spawn_rotation(entry_direction: String = "") -> float:
	match entry_direction:
		"left":
			return deg_to_rad(90)   # Face right (into room)
		"right":
			return deg_to_rad(-90)  # Face left (into room)
		_:
			return 0  # Face forward


## Check if a door can be used
func can_use_door(direction: String) -> bool:
	if not doors_locked.has(direction):
		return false
	return not doors_locked[direction]


# === Signal Handlers ===

func _on_left_door_entered(body: Node3D) -> void:
	if doors_locked["left"]:
		print("[Room3D %d] Left door is locked" % room_index)
		return

	# Check if it's a player
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		print("[Room3D %d] Player %d entered left door, transitioning to room %d" % [room_index, player_id, room_index - 1])
		# Notify dungeon manager of room transition (entering from right side of previous room)
		if dungeon and dungeon.has_method("transition_to_room"):
			dungeon.transition_to_room(room_index - 1, player_id, "right")


func _on_right_door_entered(body: Node3D) -> void:
	if doors_locked["right"]:
		print("[Room3D %d] Right door is locked" % room_index)
		return

	# Check if it's a player
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		print("[Room3D %d] Player %d entered right door, transitioning to room %d" % [room_index, player_id, room_index + 1])
		# Notify dungeon manager of room transition (entering from left side of next room)
		if dungeon and dungeon.has_method("transition_to_room"):
			dungeon.transition_to_room(room_index + 1, player_id, "left")


func _on_puzzle_solved(puzzle_id: String, time_taken: float) -> void:
	print("[Room3D %d] Puzzle '%s' solved in %.2fs" % [room_index, puzzle_id, time_taken])
	complete_room()


func _on_puzzle_failed(puzzle_id: String) -> void:
	print("[Room3D %d] Puzzle '%s' failed" % [room_index, puzzle_id])
