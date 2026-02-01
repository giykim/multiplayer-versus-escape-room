extends BaseTest
## TestDungeon - Comprehensive unit tests for dungeon generation

var generator: DungeonGenerator


func setup() -> void:
	generator = DungeonGenerator.new()


func get_test_methods() -> Array[String]:
	return [
		# Generator existence tests
		"test_generator_creates_layout",
		"test_generator_returns_valid_layout",

		# Room count tests
		"test_room_count_in_valid_range",
		"test_minimum_room_count_enforced",

		# Room type tests
		"test_first_room_is_transit",
		"test_last_room_is_arena",
		"test_has_puzzle_rooms",
		"test_puzzle_rooms_have_types",

		# Connection tests
		"test_all_rooms_connected",
		"test_room_connections_are_bidirectional",

		# Seed tests
		"test_same_seed_produces_same_layout",
		"test_different_seeds_produce_different_layouts",

		# Difficulty tests
		"test_difficulty_increases_with_progress",
		"test_difficulty_in_valid_range",

		# Validation tests
		"test_layout_passes_validation",
		"test_arena_room_index_set",
	]


func test_generator_creates_layout() -> Dictionary:
	var layout = generator.generate(12345)
	return assert_not_null(layout, "Generator should create a layout")


func test_generator_returns_valid_layout() -> Dictionary:
	var layout = generator.generate(12345)
	if layout == null:
		return {"passed": false, "message": "Layout is null"}
	return assert_true(layout is DungeonGenerator.DungeonLayout, "Layout should be DungeonLayout type")


func test_room_count_in_valid_range() -> Dictionary:
	var layout = generator.generate(12345)
	var count = layout.room_count
	var in_range = count >= DungeonGenerator.MIN_ROOMS and count <= DungeonGenerator.MAX_ROOMS
	return {
		"passed": in_range,
		"message": "Room count %d in range [%d, %d]" % [count, DungeonGenerator.MIN_ROOMS, DungeonGenerator.MAX_ROOMS] if in_range else "Room count %d out of range" % count
	}


func test_minimum_room_count_enforced() -> Dictionary:
	# Test with multiple seeds to ensure minimum is always met
	for seed_val in [1, 100, 999, 12345, 99999]:
		var gen = DungeonGenerator.new()
		var layout = gen.generate(seed_val)
		if layout.room_count < DungeonGenerator.MIN_ROOMS:
			return {"passed": false, "message": "Seed %d produced only %d rooms" % [seed_val, layout.room_count]}
	return {"passed": true, "message": "Minimum room count enforced across seeds"}


func test_first_room_is_transit() -> Dictionary:
	var layout = generator.generate(12345)
	var first_room = layout.get_room(0)
	return assert_equals(first_room.type, DungeonGenerator.RoomType.TRANSIT, "First room should be TRANSIT")


func test_last_room_is_arena() -> Dictionary:
	var layout = generator.generate(12345)
	var last_room = layout.get_room(layout.room_count - 1)
	return assert_equals(last_room.type, DungeonGenerator.RoomType.ARENA, "Last room should be ARENA")


func test_has_puzzle_rooms() -> Dictionary:
	var layout = generator.generate(12345)
	var puzzle_count = 0
	for room in layout.rooms:
		if room.type == DungeonGenerator.RoomType.PUZZLE:
			puzzle_count += 1

	var has_puzzles = puzzle_count >= DungeonGenerator.MIN_PUZZLES
	return {
		"passed": has_puzzles,
		"message": "Found %d puzzle rooms (min: %d)" % [puzzle_count, DungeonGenerator.MIN_PUZZLES]
	}


func test_puzzle_rooms_have_types() -> Dictionary:
	var layout = generator.generate(12345)
	for room in layout.rooms:
		if room.type == DungeonGenerator.RoomType.PUZZLE:
			if room.puzzle_type.is_empty():
				return {"passed": false, "message": "Puzzle room %d has no puzzle_type" % room.index}
	return {"passed": true, "message": "All puzzle rooms have puzzle types"}


func test_all_rooms_connected() -> Dictionary:
	var layout = generator.generate(12345)
	for i in range(layout.room_count):
		var room = layout.get_room(i)
		# First room should have right connection only
		if i == 0:
			if not room.connections.has("right"):
				return {"passed": false, "message": "First room missing right connection"}
		# Last room should have left connection only
		elif i == layout.room_count - 1:
			if not room.connections.has("left"):
				return {"passed": false, "message": "Last room missing left connection"}
		# Middle rooms should have both
		else:
			if not room.connections.has("left") or not room.connections.has("right"):
				return {"passed": false, "message": "Room %d missing connections" % i}
	return {"passed": true, "message": "All rooms properly connected"}


func test_room_connections_are_bidirectional() -> Dictionary:
	var layout = generator.generate(12345)
	for room in layout.rooms:
		for direction in room.connections:
			var target_index = room.connections[direction]
			var target_room = layout.get_room(target_index)

			var reverse_dir = "left" if direction == "right" else "right"
			if not target_room.connections.has(reverse_dir):
				return {"passed": false, "message": "Room %d -> %d not bidirectional" % [room.index, target_index]}
			if target_room.connections[reverse_dir] != room.index:
				return {"passed": false, "message": "Room %d <-> %d connection mismatch" % [room.index, target_index]}

	return {"passed": true, "message": "All connections are bidirectional"}


func test_same_seed_produces_same_layout() -> Dictionary:
	var seed_val = 42424242
	var layout1 = generator.generate(seed_val)
	var gen2 = DungeonGenerator.new()
	var layout2 = gen2.generate(seed_val)

	if layout1.room_count != layout2.room_count:
		return {"passed": false, "message": "Different room counts with same seed"}

	for i in range(layout1.room_count):
		var r1 = layout1.get_room(i)
		var r2 = layout2.get_room(i)
		if r1.type != r2.type:
			return {"passed": false, "message": "Room %d type mismatch with same seed" % i}
		if r1.puzzle_type != r2.puzzle_type:
			return {"passed": false, "message": "Room %d puzzle_type mismatch with same seed" % i}

	return {"passed": true, "message": "Same seed produces identical layouts"}


func test_different_seeds_produce_different_layouts() -> Dictionary:
	var layout1 = generator.generate(11111)
	var gen2 = DungeonGenerator.new()
	var layout2 = gen2.generate(22222)

	# Check if any puzzle types differ
	var differences = 0
	var min_count = mini(layout1.room_count, layout2.room_count)
	for i in range(min_count):
		var r1 = layout1.get_room(i)
		var r2 = layout2.get_room(i)
		if r1.type != r2.type or r1.puzzle_type != r2.puzzle_type:
			differences += 1

	# Should have at least some differences
	return {
		"passed": differences > 0 or layout1.room_count != layout2.room_count,
		"message": "Found %d differences between layouts" % differences
	}


func test_difficulty_increases_with_progress() -> Dictionary:
	var layout = generator.generate(12345)

	# Check that later rooms tend to have higher difficulty
	var early_avg = 0.0
	var late_avg = 0.0
	var early_count = 0
	var late_count = 0

	var mid_point = layout.room_count / 2
	for room in layout.rooms:
		if room.index < mid_point:
			early_avg += room.difficulty
			early_count += 1
		else:
			late_avg += room.difficulty
			late_count += 1

	if early_count > 0:
		early_avg /= early_count
	if late_count > 0:
		late_avg /= late_count

	# Late rooms should generally have higher difficulty
	return {
		"passed": late_avg >= early_avg,
		"message": "Early avg: %.1f, Late avg: %.1f" % [early_avg, late_avg]
	}


func test_difficulty_in_valid_range() -> Dictionary:
	var layout = generator.generate(12345)
	for room in layout.rooms:
		if room.difficulty < 1 or room.difficulty > 5:
			return {"passed": false, "message": "Room %d has invalid difficulty: %d" % [room.index, room.difficulty]}
	return {"passed": true, "message": "All difficulties in range [1, 5]"}


func test_layout_passes_validation() -> Dictionary:
	var layout = generator.generate(12345)
	var is_valid = generator.validate_layout(layout)
	return assert_true(is_valid, "Generated layout should pass validation")


func test_arena_room_index_set() -> Dictionary:
	var layout = generator.generate(12345)
	var expected_arena = layout.room_count - 1
	return assert_equals(layout.arena_room_index, expected_arena, "Arena should be last room")
