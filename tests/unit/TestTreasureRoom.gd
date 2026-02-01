extends BaseTest
## TestTreasureRoom - Unit tests for TreasureRoom3D chest and coin functionality

func get_test_methods() -> Array[String]:
	return [
		# Scene existence
		"test_treasure_room_scene_exists",
		"test_treasure_room_instantiates",
		"test_treasure_room_extends_room3d",

		# Configuration
		"test_treasure_room_has_coin_config",
		"test_treasure_room_has_chest_config",
		"test_treasure_room_type_is_treasure",

		# State tracking
		"test_treasure_room_tracks_coins",
		"test_treasure_room_tracks_chest_state",

		# Door behavior
		"test_treasure_door_starts_locked",
		"test_treasure_door_should_lock_method",

		# Methods
		"test_treasure_room_has_setup_treasure",
		"test_treasure_room_has_spawn_coins",
		"test_treasure_room_has_spawn_chest",

		# Callbacks
		"test_treasure_room_has_coin_callback",
		"test_treasure_room_has_chest_callback",
		"test_treasure_room_has_hud_update",
	]


func test_treasure_room_scene_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/dungeon3d/TreasureRoom3D.tscn")
	return assert_true(exists, "TreasureRoom3D.tscn should exist")


func test_treasure_room_instantiates() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var valid = room != null

	if room:
		room.queue_free()

	return assert_true(valid, "TreasureRoom3D should instantiate")


func test_treasure_room_extends_room3d() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var is_room3d = room is Room3D

	room.queue_free()
	return assert_true(is_room3d, "TreasureRoom3D should extend Room3D")


func test_treasure_room_has_coin_config() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_min = "min_coins" in room
	var has_max = "max_coins" in room
	var valid_range = room.min_coins <= room.max_coins

	room.queue_free()
	return assert_true(has_min and has_max and valid_range, "TreasureRoom should have valid min/max_coins")


func test_treasure_room_has_chest_config() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_spawn_chest = "spawn_chest" in room
	var has_item_drop = "item_drop_chance" in room

	room.queue_free()
	return assert_true(has_spawn_chest and has_item_drop, "TreasureRoom should have chest configuration")


func test_treasure_room_type_is_treasure() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var is_treasure = room.room_type == room.RoomType.TREASURE

	room.queue_free()
	return assert_true(is_treasure, "TreasureRoom room_type should be TREASURE")


func test_treasure_room_tracks_coins() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_collected = "coins_collected" in room
	var has_total = "total_coins" in room

	room.queue_free()
	return assert_true(has_collected and has_total, "TreasureRoom should track coins_collected and total_coins")


func test_treasure_room_tracks_chest_state() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_chest_opened = "chest_opened" in room
	var starts_closed = not room.chest_opened

	room.queue_free()
	return assert_true(has_chest_opened and starts_closed, "TreasureRoom should track chest_opened state")


func test_treasure_door_starts_locked() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var right_locked = room.doors_locked.get("right", false)

	room.queue_free()
	return assert_true(right_locked, "TreasureRoom right door should start locked")


func test_treasure_door_should_lock_method() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_should_lock_forward_door")
	var should_lock = true
	if has_method:
		should_lock = room._should_lock_forward_door()

	room.queue_free()
	return assert_true(has_method and should_lock, "TreasureRoom should override _should_lock_forward_door to return true")


func test_treasure_room_has_setup_treasure() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_setup_treasure")

	room.queue_free()
	return assert_true(has_method, "TreasureRoom should have _setup_treasure method")


func test_treasure_room_has_spawn_coins() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_spawn_coins")

	room.queue_free()
	return assert_true(has_method, "TreasureRoom should have _spawn_coins method")


func test_treasure_room_has_spawn_chest() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_spawn_chest")

	room.queue_free()
	return assert_true(has_method, "TreasureRoom should have _spawn_chest method")


func test_treasure_room_has_coin_callback() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_on_coin_picked_up")
	var has_placeholder = room.has_method("_on_placeholder_coin_touched")

	room.queue_free()
	return assert_true(has_method and has_placeholder, "TreasureRoom should have coin pickup callbacks")


func test_treasure_room_has_chest_callback() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_on_chest_opened")
	var has_placeholder = room.has_method("_on_placeholder_chest_touched")

	room.queue_free()
	return assert_true(has_method and has_placeholder, "TreasureRoom should have chest opened callbacks")


func test_treasure_room_has_hud_update() -> Dictionary:
	var scene = load("res://src/dungeon3d/TreasureRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var room = scene.instantiate()
	var has_method = room.has_method("_update_hud_coins")

	room.queue_free()
	return assert_true(has_method, "TreasureRoom should have _update_hud_coins method")
