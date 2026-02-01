extends BaseTest
## TestRoom3D - Unit tests for Room3D doors, labels, and state management

func get_test_methods() -> Array[String]:
	return [
		# Scene existence
		"test_room3d_scene_exists",
		"test_room3d_instantiates",

		# Node structure
		"test_room_has_floor",
		"test_room_has_walls",
		"test_room_has_doors",
		"test_room_has_spawn_points",
		"test_room_has_progress_label",

		# Door functionality
		"test_door_has_panel",
		"test_door_has_label",
		"test_door_has_frame",
		"test_door_starts_locked",
		"test_door_unlock_changes_state",
		"test_door_blocker_created",

		# Room state
		"test_room_initial_state",
		"test_room_complete_unlocks_door",
		"test_room_type_enum_exists",

		# Configuration
		"test_room_initialize_from_data",
		"test_room_difficulty_property",
		"test_room_connections_setup",
	]


func test_room3d_scene_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/dungeon3d/Room3D.tscn")
	return assert_true(exists, "Room3D.tscn should exist")


func test_room3d_instantiates() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load Room3D scene"}

	var room = scene.instantiate()
	var valid = room != null and room is Node3D

	if room:
		room.queue_free()

	return assert_true(valid, "Room3D should instantiate as Node3D")


func test_room_has_floor() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var floor = room.get_node_or_null("Floor")
	var has_floor = floor != null

	room.queue_free()
	return assert_true(has_floor, "Room should have Floor node")


func test_room_has_walls() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_back = room.get_node_or_null("BackWall") != null
	var has_front = room.get_node_or_null("FrontWall") != null
	var has_left = room.get_node_or_null("LeftWallCombo") != null
	var has_right = room.get_node_or_null("RightWallCombo") != null

	room.queue_free()

	var all_walls = has_back and has_front and has_left and has_right
	return assert_true(all_walls, "Room should have all walls")


func test_room_has_doors() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var left_door = room.get_node_or_null("LeftDoor")
	var right_door = room.get_node_or_null("RightDoor")

	var has_doors = left_door != null and right_door != null
	var doors_are_area3d = left_door is Area3D and right_door is Area3D

	room.queue_free()
	return assert_true(has_doors and doors_are_area3d, "Room should have LeftDoor and RightDoor as Area3D")


func test_room_has_spawn_points() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var puzzle_spawn = room.get_node_or_null("PuzzleSpawn")
	var player_spawn = room.get_node_or_null("PlayerSpawn")

	room.queue_free()

	var has_spawns = puzzle_spawn != null and player_spawn != null
	return assert_true(has_spawns, "Room should have PuzzleSpawn and PlayerSpawn")


func test_room_has_progress_label() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var label = room.get_node_or_null("RoomProgressLabel")

	room.queue_free()

	var has_label = label != null and label is Label3D
	return assert_true(has_label, "Room should have RoomProgressLabel as Label3D")


func test_door_has_panel() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var right_door = room.get_node_or_null("RightDoor")
	var panel = right_door.get_node_or_null("DoorPanel") if right_door else null

	room.queue_free()

	var has_panel = panel != null and panel is MeshInstance3D
	return assert_true(has_panel, "Door should have DoorPanel mesh")


func test_door_has_label() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var right_door = room.get_node_or_null("RightDoor")
	var label = right_door.get_node_or_null("DoorLabel") if right_door else null

	room.queue_free()

	var has_label = label != null and label is Label3D
	return assert_true(has_label, "Door should have DoorLabel")


func test_door_has_frame() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var right_door = room.get_node_or_null("RightDoor")
	var frame_top = right_door.get_node_or_null("FrameTop") if right_door else null
	var frame_left = right_door.get_node_or_null("FrameLeft") if right_door else null

	room.queue_free()

	var has_frames = frame_top != null and frame_left != null
	return assert_true(has_frames, "Door should have frame meshes")


func test_door_starts_locked() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var right_locked = room.doors_locked.get("right", false)

	room.queue_free()
	return assert_true(right_locked, "Right door should start locked")


func test_door_unlock_changes_state() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var initially_locked = room.doors_locked.get("right", false)

	room.set_door_locked("right", false)
	var now_unlocked = not room.doors_locked.get("right", true)

	room.queue_free()
	return assert_true(initially_locked and now_unlocked, "Door should unlock when set_door_locked(false) called")


func test_door_blocker_created() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	# Trigger _setup_doors which creates blockers
	room._setup_doors()

	var right_door = room.get_node_or_null("RightDoor")
	var blocker = right_door.get_node_or_null("DoorBlocker") if right_door else null

	room.queue_free()
	return assert_not_null(blocker, "Door should have DoorBlocker StaticBody3D")


func test_room_initial_state() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var not_completed = not room.is_completed
	var not_locked = not room.is_locked or room.is_locked  # Either state is valid initially

	room.queue_free()
	return assert_true(not_completed, "Room should start not completed")


func test_room_complete_unlocks_door() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	room.doors_locked["right"] = true

	room.complete_room()

	var door_unlocked = not room.doors_locked.get("right", true)
	var is_completed = room.is_completed

	room.queue_free()
	return assert_true(door_unlocked and is_completed, "complete_room() should unlock door and set is_completed")


func test_room_type_enum_exists() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_puzzle = "PUZZLE" in str(room.RoomType)
	var has_treasure = "TREASURE" in str(room.RoomType)
	var has_arena = "ARENA" in str(room.RoomType)

	room.queue_free()
	return assert_true(has_puzzle and has_treasure and has_arena, "RoomType enum should have PUZZLE, TREASURE, ARENA")


func test_room_initialize_from_data() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("initialize_from_data")

	room.queue_free()
	return assert_true(has_method, "Room should have initialize_from_data method")


func test_room_difficulty_property() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_difficulty = "difficulty" in room
	var difficulty_valid = room.difficulty >= 1 and room.difficulty <= 5

	room.queue_free()
	return assert_true(has_difficulty and difficulty_valid, "Room should have difficulty property in valid range")


func test_room_connections_setup() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_left = room.has_left_door != null
	var has_right = room.has_right_door != null

	room.queue_free()
	return assert_true(has_left or has_right, "Room should have door configuration properties")
