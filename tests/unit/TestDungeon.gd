extends BaseTest
## TestDungeon - Unit tests for dungeon generation

var dungeon_generator_script: Script
var dungeon_script: Script
var room_script: Script
var room3d_script: Script


func setup() -> void:
	dungeon_generator_script = load("res://src/dungeon/DungeonGenerator.gd") if ResourceLoader.exists("res://src/dungeon/DungeonGenerator.gd") else null
	dungeon_script = load("res://src/dungeon/Dungeon.gd") if ResourceLoader.exists("res://src/dungeon/Dungeon.gd") else null
	room_script = load("res://src/dungeon/Room.gd") if ResourceLoader.exists("res://src/dungeon/Room.gd") else null
	room3d_script = load("res://src/dungeon3d/Room3D.gd") if ResourceLoader.exists("res://src/dungeon3d/Room3D.gd") else null


func get_test_methods() -> Array[String]:
	return [
		"test_dungeon_generator_exists",
		"test_generator_has_seed_system",
		"test_generator_has_room_types",
		"test_dungeon_container_exists",
		"test_room_base_exists",
		"test_room_has_door_system",
		"test_room3d_exists",
		"test_room3d_has_3d_geometry",
	]


func test_dungeon_generator_exists() -> Dictionary:
	return assert_not_null(dungeon_generator_script, "DungeonGenerator.gd should exist")


func test_generator_has_seed_system() -> Dictionary:
	if not dungeon_generator_script:
		return {"passed": false, "message": "DungeonGenerator not loaded"}

	var source = dungeon_generator_script.source_code
	var has_seed = "seed" in source.to_lower()
	var has_rng = "rng" in source.to_lower() or "random" in source.to_lower()

	var passed = has_seed or has_rng
	return {
		"passed": passed,
		"message": "Seed/RNG system present" if passed else "Missing seed system"
	}


func test_generator_has_room_types() -> Dictionary:
	if not dungeon_generator_script:
		return {"passed": false, "message": "DungeonGenerator not loaded"}

	var source = dungeon_generator_script.source_code
	var has_room_types = "room_type" in source.to_lower() or "RoomType" in source

	return {
		"passed": has_room_types,
		"message": "Room types present" if has_room_types else "Missing room type system"
	}


func test_dungeon_container_exists() -> Dictionary:
	return assert_not_null(dungeon_script, "Dungeon.gd should exist")


func test_room_base_exists() -> Dictionary:
	return assert_not_null(room_script, "Room.gd should exist")


func test_room_has_door_system() -> Dictionary:
	if not room_script:
		return {"passed": false, "message": "Room not loaded"}

	var source = room_script.source_code
	var has_doors = "door" in source.to_lower()
	var has_connections = "connect" in source.to_lower() or "neighbor" in source.to_lower()

	var passed = has_doors
	return {
		"passed": passed,
		"message": "Door system present" if passed else "Missing door system"
	}


func test_room3d_exists() -> Dictionary:
	return assert_not_null(room3d_script, "Room3D.gd should exist")


func test_room3d_has_3d_geometry() -> Dictionary:
	if not room3d_script:
		return {"passed": false, "message": "Room3D not loaded"}

	var source = room3d_script.source_code
	var has_3d_elements = "CSG" in source or "Mesh" in source or "StaticBody3D" in source
	var has_dimensions = "width" in source.to_lower() or "size" in source.to_lower()

	var passed = has_3d_elements or has_dimensions
	return {
		"passed": passed,
		"message": "3D geometry present" if passed else "Missing 3D geometry"
	}
