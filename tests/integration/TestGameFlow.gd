extends BaseTest
## TestGameFlow - Integration tests for complete game flow

func get_test_methods() -> Array[String]:
	return [
		# Scene existence tests
		"test_main_menu_scene_exists",
		"test_game3d_scene_exists",
		"test_player3d_scene_exists",
		"test_hud_scene_exists",
		"test_lobby_scene_exists",

		# Room scene tests
		"test_room3d_scene_exists",
		"test_puzzle_room_scene_exists",
		"test_arena_room_scene_exists",
		"test_treasure_room_scene_exists",

		# Puzzle scene tests
		"test_puzzle_panel_scene_exists",
		"test_puzzle_panel_can_instantiate",

		# Autoload tests
		"test_game_manager_autoload",
		"test_network_manager_autoload",
		"test_audio_manager_autoload",

		# GameManager tests
		"test_game_manager_has_states",
		"test_game_manager_player_registration",
		"test_game_manager_state_changes",

		# Scene instantiation tests
		"test_player_instantiation",
		"test_hud_instantiation",
		"test_room_instantiation",

		# Component integration tests
		"test_dungeon_generates_for_game",
		"test_room_can_load_puzzle",

		# Project configuration tests
		"test_project_has_required_autoloads",
		"test_project_has_main_scene",
		"test_project_has_input_actions",
	]


# === Scene Existence Tests ===

func test_main_menu_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/ui/MainMenu.tscn"),
		"MainMenu.tscn should exist"
	)


func test_game3d_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/Game3D.tscn"),
		"Game3D.tscn should exist"
	)


func test_player3d_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/player3d/Player3D.tscn"),
		"Player3D.tscn should exist"
	)


func test_hud_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/ui/HUD.tscn"),
		"HUD.tscn should exist"
	)


func test_lobby_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/ui/Lobby.tscn"),
		"Lobby.tscn should exist"
	)


func test_room3d_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/dungeon3d/Room3D.tscn"),
		"Room3D.tscn should exist"
	)


func test_puzzle_room_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/dungeon3d/PuzzleRoom3D.tscn"),
		"PuzzleRoom3D.tscn should exist"
	)


func test_arena_room_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/dungeon3d/ArenaRoom3D.tscn"),
		"ArenaRoom3D.tscn should exist"
	)


func test_treasure_room_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/dungeon3d/TreasureRoom3D.tscn"),
		"TreasureRoom3D.tscn should exist"
	)


func test_puzzle_panel_scene_exists() -> Dictionary:
	return assert_true(
		ResourceLoader.exists("res://src/puzzles3d/InteractivePuzzlePanel.tscn"),
		"InteractivePuzzlePanel.tscn should exist"
	)


func test_puzzle_panel_can_instantiate() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load puzzle panel scene"}

	var instance = scene.instantiate()
	if not instance:
		return {"passed": false, "message": "Could not instantiate puzzle panel"}

	var has_signals = instance.has_signal("puzzle_solved") and instance.has_signal("puzzle_started")
	var has_methods = instance.has_method("interact") and instance.has_method("start_puzzle")

	instance.queue_free()

	return {
		"passed": has_signals and has_methods,
		"message": "Puzzle panel has required signals and methods"
	}


# === Autoload Tests ===

func test_game_manager_autoload() -> Dictionary:
	return assert_not_null(GameManager, "GameManager autoload should exist")


func test_network_manager_autoload() -> Dictionary:
	return assert_not_null(NetworkManager, "NetworkManager autoload should exist")


func test_audio_manager_autoload() -> Dictionary:
	return assert_not_null(AudioManager, "AudioManager autoload should exist")


# === GameManager Tests ===

func test_game_manager_has_states() -> Dictionary:
	var has_menu = "MENU" in str(GameManager.GameState)
	var has_puzzle = "PUZZLE_PHASE" in str(GameManager.GameState)
	var has_arena = "ARENA_PHASE" in str(GameManager.GameState)

	return {
		"passed": has_menu or has_puzzle or has_arena,
		"message": "GameManager has game states"
	}


func test_game_manager_player_registration() -> Dictionary:
	# Test registering a player
	var test_id = 9999
	GameManager.register_player(test_id, "TestPlayer")

	var registered = GameManager.players.has(test_id)
	var data = GameManager.get_player_data(test_id)

	# Cleanup
	GameManager.players.erase(test_id)

	return {
		"passed": registered and data != null,
		"message": "Player registration works" if registered else "Player registration failed"
	}


func test_game_manager_state_changes() -> Dictionary:
	var initial_state = GameManager.current_state

	# Try changing state
	GameManager.change_state(GameManager.GameState.PUZZLE_PHASE)
	var changed = GameManager.current_state == GameManager.GameState.PUZZLE_PHASE

	# Restore state
	GameManager.change_state(initial_state)

	return {
		"passed": changed,
		"message": "State change works" if changed else "State change failed"
	}


# === Scene Instantiation Tests ===

func test_player_instantiation() -> Dictionary:
	var scene = load("res://src/player3d/Player3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load Player3D scene"}

	var player = scene.instantiate()
	if not player:
		return {"passed": false, "message": "Could not instantiate player"}

	var is_character = player is CharacterBody3D
	var has_camera = player.get_node_or_null("Head/Camera3D") != null
	var has_collision = player.get_node_or_null("CollisionShape3D") != null

	player.queue_free()

	return {
		"passed": is_character and has_camera and has_collision,
		"message": "Player has CharacterBody3D, camera, and collision"
	}


func test_hud_instantiation() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load HUD scene"}

	var hud = scene.instantiate()
	if not hud:
		return {"passed": false, "message": "Could not instantiate HUD"}

	var is_canvas = hud is CanvasLayer

	hud.queue_free()

	return {
		"passed": is_canvas,
		"message": "HUD is CanvasLayer" if is_canvas else "HUD is not CanvasLayer"
	}


func test_room_instantiation() -> Dictionary:
	var scene = load("res://src/dungeon3d/Room3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load Room3D scene"}

	var room = scene.instantiate()
	if not room:
		return {"passed": false, "message": "Could not instantiate room"}

	var is_node3d = room is Node3D
	var has_floor = room.get_node_or_null("Floor") != null
	var has_spawn = room.get_node_or_null("PlayerSpawn") != null

	room.queue_free()

	return {
		"passed": is_node3d and has_floor and has_spawn,
		"message": "Room has Node3D, floor, and spawn point"
	}


# === Component Integration Tests ===

func test_dungeon_generates_for_game() -> Dictionary:
	var generator = DungeonGenerator.new()
	var layout = generator.generate(GameManager.get_match_seed())

	if not layout:
		return {"passed": false, "message": "Failed to generate dungeon"}

	var valid = generator.validate_layout(layout)

	return {
		"passed": valid,
		"message": "Dungeon generated and validated for game seed"
	}


func test_room_can_load_puzzle() -> Dictionary:
	# Load PuzzleRoom3D
	var scene = load("res://src/dungeon3d/PuzzleRoom3D.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load PuzzleRoom3D"}

	var room = scene.instantiate()
	if not room:
		return {"passed": false, "message": "Could not instantiate PuzzleRoom3D"}

	# Check that it extends Room3D functionality
	var has_spawn_puzzle = room.has_method("_spawn_puzzle")
	var has_puzzle_type = "puzzle_type" in room

	room.queue_free()

	return {
		"passed": has_spawn_puzzle and has_puzzle_type,
		"message": "PuzzleRoom3D can spawn puzzles"
	}


# === Project Configuration Tests ===

func test_project_has_required_autoloads() -> Dictionary:
	var project_path = "res://project.godot"
	if not FileAccess.file_exists(project_path):
		return {"passed": false, "message": "project.godot not found"}

	var file = FileAccess.open(project_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var has_game_manager = "GameManager" in content
	var has_network_manager = "NetworkManager" in content
	var has_audio_manager = "AudioManager" in content

	var passed = has_game_manager and has_network_manager and has_audio_manager
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


func test_project_has_input_actions() -> Dictionary:
	# Check that essential input actions are defined
	var required_actions = ["move_up", "move_down", "move_left", "move_right", "jump", "interact"]
	var missing_actions: Array[String] = []

	for action in required_actions:
		if not InputMap.has_action(action):
			missing_actions.append(action)

	return {
		"passed": missing_actions.is_empty(),
		"message": "All input actions defined" if missing_actions.is_empty() else "Missing: %s" % ", ".join(missing_actions)
	}
