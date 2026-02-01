extends BaseTest
## TestGameFlow - Integration tests for game systems working together

var game_manager_script: Script
var network_manager_script: Script
var game3d_script: Script


func setup() -> void:
	game_manager_script = load("res://src/autoload/GameManager.gd") if ResourceLoader.exists("res://src/autoload/GameManager.gd") else null
	network_manager_script = load("res://src/autoload/NetworkManager.gd") if ResourceLoader.exists("res://src/autoload/NetworkManager.gd") else null
	game3d_script = load("res://src/Game3D.gd") if ResourceLoader.exists("res://src/Game3D.gd") else null


func get_test_methods() -> Array[String]:
	return [
		"test_game_manager_exists",
		"test_game_manager_has_state_management",
		"test_game_manager_has_player_management",
		"test_network_manager_exists",
		"test_network_manager_has_lobby_system",
		"test_network_manager_has_connection_handling",
		"test_game3d_scene_exists",
		"test_project_has_required_autoloads",
		"test_project_has_main_scene",
	]


func test_game_manager_exists() -> Dictionary:
	return assert_not_null(game_manager_script, "GameManager.gd should exist")


func test_game_manager_has_state_management() -> Dictionary:
	if not game_manager_script:
		return {"passed": false, "message": "GameManager not loaded"}

	var source = game_manager_script.source_code
	var has_state = "GameState" in source or "game_state" in source or "current_state" in source
	var has_change = "change_state" in source or "set_state" in source

	var passed = has_state
	return {
		"passed": passed,
		"message": "State management present" if passed else "Missing state management"
	}


func test_game_manager_has_player_management() -> Dictionary:
	if not game_manager_script:
		return {"passed": false, "message": "GameManager not loaded"}

	var source = game_manager_script.source_code
	var has_players = "players" in source
	var has_add_player = "add_player" in source or "register_player" in source
	var has_get_player = "get_player" in source

	var passed = has_players and (has_add_player or has_get_player)
	return {
		"passed": passed,
		"message": "Player management present" if passed else "Missing player management"
	}


func test_network_manager_exists() -> Dictionary:
	return assert_not_null(network_manager_script, "NetworkManager.gd should exist")


func test_network_manager_has_lobby_system() -> Dictionary:
	if not network_manager_script:
		return {"passed": false, "message": "NetworkManager not loaded"}

	var source = network_manager_script.source_code
	var has_host = "host" in source.to_lower() or "create_server" in source.to_lower()
	var has_join = "join" in source.to_lower() or "connect" in source.to_lower()

	var passed = has_host and has_join
	return {
		"passed": passed,
		"message": "Lobby system present" if passed else "Missing lobby functionality"
	}


func test_network_manager_has_connection_handling() -> Dictionary:
	if not network_manager_script:
		return {"passed": false, "message": "NetworkManager not loaded"}

	var source = network_manager_script.source_code
	var has_connected = "connected" in source.to_lower()
	var has_disconnected = "disconnected" in source.to_lower()
	var has_signals = "signal" in source

	var passed = has_connected and has_disconnected
	return {
		"passed": passed,
		"message": "Connection handling present" if passed else "Missing connection handling"
	}


func test_game3d_scene_exists() -> Dictionary:
	return assert_not_null(game3d_script, "Game3D.gd should exist")


func test_project_has_required_autoloads() -> Dictionary:
	# Check project.godot for autoload entries
	var project_path = "res://project.godot"
	if not FileAccess.file_exists(project_path):
		return {"passed": false, "message": "project.godot not found"}

	var file = FileAccess.open(project_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var has_game_manager = "GameManager" in content
	var has_network_manager = "NetworkManager" in content

	var passed = has_game_manager and has_network_manager
	return {
		"passed": passed,
		"message": "Required autoloads configured" if passed else "Missing autoload configuration"
	}


func test_project_has_main_scene() -> Dictionary:
	var project_path = "res://project.godot"
	if not FileAccess.file_exists(project_path):
		return {"passed": false, "message": "project.godot not found"}

	var file = FileAccess.open(project_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var has_main_scene = "run/main_scene" in content

	return {
		"passed": has_main_scene,
		"message": "Main scene configured" if has_main_scene else "No main scene configured"
	}
