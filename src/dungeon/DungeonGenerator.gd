extends RefCounted
class_name DungeonGenerator
## DungeonGenerator - Procedural dungeon layout generator
## Uses seed-based RNG for deterministic layouts across all players

# Room types available in the dungeon
enum RoomType {
	PUZZLE,    # Standard puzzle room
	TREASURE,  # Room with loot/coins
	SHOP,      # Room to spend coins on upgrades
	TRANSIT,   # Empty transition room
	ARENA      # Final combat arena
}

# Room layout data structure
class RoomData:
	var index: int
	var type: RoomType
	var puzzle_type: String  # For PUZZLE rooms, which puzzle to spawn
	var difficulty: int
	var connections: Dictionary  # Direction -> room_index (left, right)
	var seed_offset: int  # Unique seed offset for this room

	func _init(room_index: int, room_type: RoomType):
		index = room_index
		type = room_type
		puzzle_type = ""
		difficulty = 1
		connections = {}
		seed_offset = room_index * 1000

# Dungeon layout data structure
class DungeonLayout:
	var rooms: Array[RoomData] = []
	var room_count: int = 0
	var generation_seed: int = 0
	var start_room_index: int = 0
	var arena_room_index: int = -1

	func get_room(index: int) -> RoomData:
		if index >= 0 and index < rooms.size():
			return rooms[index]
		return null

# Generation configuration
const MIN_ROOMS: int = 8
const MAX_ROOMS: int = 12
const MIN_PUZZLES: int = 4
const MAX_PUZZLES: int = 6

# Available puzzle types (will be expanded as more puzzles are created)
const PUZZLE_TYPES: Array[String] = [
	"sliding_tile",
	"pattern_match",
	"wire_connect",
	"sequence_memory",
	"lock_pick"
]

# Seeded random number generator
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _generation_seed: int = 0


## Generate a complete dungeon layout using the provided seed
func generate(seed_value: int) -> DungeonLayout:
	_generation_seed = seed_value
	_rng.seed = seed_value

	var layout = DungeonLayout.new()
	layout.generation_seed = seed_value

	# Determine room count
	layout.room_count = _rng.randi_range(MIN_ROOMS, MAX_ROOMS)

	# Generate room sequence
	_generate_room_sequence(layout)

	# Connect rooms in linear sequence
	_connect_rooms(layout)

	# Assign puzzles to puzzle rooms
	_assign_puzzles(layout)

	# Set difficulty progression
	_assign_difficulties(layout)

	print("[DungeonGenerator] Generated dungeon with %d rooms using seed %d" % [layout.room_count, seed_value])

	return layout


## Generate the sequence of room types
func _generate_room_sequence(layout: DungeonLayout) -> void:
	var room_count = layout.room_count

	# First room is always a SHOP (players can return to buy items)
	var start_room = RoomData.new(0, RoomType.SHOP)
	start_room.seed_offset = _rng.randi()
	layout.rooms.append(start_room)
	layout.start_room_index = 0

	# Last room is always the arena
	var arena_index = room_count - 1
	layout.arena_room_index = arena_index

	# Calculate room distribution for middle rooms
	var middle_room_count = room_count - 2  # Exclude start (shop) and arena
	var puzzle_count = _rng.randi_range(MIN_PUZZLES, mini(MAX_PUZZLES, middle_room_count))
	var treasure_count = _rng.randi_range(1, 2)
	# No transit rooms - only puzzles and treasure in the middle
	# Adjust puzzle count to fill remaining slots
	puzzle_count = maxi(puzzle_count, middle_room_count - treasure_count)

	# Ensure we don't exceed middle room count
	if puzzle_count + treasure_count > middle_room_count:
		puzzle_count = middle_room_count - treasure_count

	# Create pool of room types
	var room_pool: Array[RoomType] = []
	for i in puzzle_count:
		room_pool.append(RoomType.PUZZLE)
	for i in treasure_count:
		room_pool.append(RoomType.TREASURE)

	# Shuffle the pool
	_shuffle_array(room_pool)

	# Create middle rooms
	for i in range(1, arena_index):
		var pool_index = i - 1
		var room_type = RoomType.PUZZLE
		if pool_index < room_pool.size():
			room_type = room_pool[pool_index]

		var room = RoomData.new(i, room_type)
		room.seed_offset = _rng.randi()
		layout.rooms.append(room)

	# Add arena as final room
	var arena_room = RoomData.new(arena_index, RoomType.ARENA)
	arena_room.seed_offset = _rng.randi()
	layout.rooms.append(arena_room)


## Connect rooms in a linear sequence
func _connect_rooms(layout: DungeonLayout) -> void:
	for i in range(layout.rooms.size()):
		var room = layout.rooms[i]

		# Connect to previous room
		if i > 0:
			room.connections["left"] = i - 1

		# Connect to next room
		if i < layout.rooms.size() - 1:
			room.connections["right"] = i + 1


## Assign puzzle types to puzzle rooms
func _assign_puzzles(layout: DungeonLayout) -> void:
	var available_puzzles = PUZZLE_TYPES.duplicate()
	_shuffle_array(available_puzzles)

	var puzzle_index = 0
	for room in layout.rooms:
		if room.type == RoomType.PUZZLE:
			# Assign puzzle type, cycling through available types
			room.puzzle_type = available_puzzles[puzzle_index % available_puzzles.size()]
			puzzle_index += 1


## Assign difficulty levels based on room position
func _assign_difficulties(layout: DungeonLayout) -> void:
	var room_count = layout.rooms.size()

	for room in layout.rooms:
		# Calculate difficulty based on position (1-5 scale)
		var progress = float(room.index) / float(room_count - 1)
		var base_difficulty = int(progress * 4) + 1  # 1-5 scale

		# Add some randomness
		var difficulty_variance = _rng.randi_range(-1, 1)
		room.difficulty = clampi(base_difficulty + difficulty_variance, 1, 5)


## Shuffle an array in place using the seeded RNG
func _shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = _rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp


## Get a human-readable string for a room type
static func get_room_type_name(type: RoomType) -> String:
	match type:
		RoomType.PUZZLE:
			return "Puzzle"
		RoomType.TREASURE:
			return "Treasure"
		RoomType.SHOP:
			return "Shop"
		RoomType.TRANSIT:
			return "Transit"
		RoomType.ARENA:
			return "Arena"
	return "Unknown"


## Validate a layout for debugging
func validate_layout(layout: DungeonLayout) -> bool:
	if layout.rooms.is_empty():
		push_error("[DungeonGenerator] Layout has no rooms")
		return false

	if layout.arena_room_index < 0:
		push_error("[DungeonGenerator] Layout has no arena room")
		return false

	# Check connections
	for room in layout.rooms:
		for direction in room.connections:
			var target_index = room.connections[direction]
			if target_index < 0 or target_index >= layout.rooms.size():
				push_error("[DungeonGenerator] Invalid connection in room %d" % room.index)
				return false

	# Check puzzle assignments
	for room in layout.rooms:
		if room.type == RoomType.PUZZLE and room.puzzle_type.is_empty():
			push_error("[DungeonGenerator] Puzzle room %d has no puzzle type" % room.index)
			return false

	return true
