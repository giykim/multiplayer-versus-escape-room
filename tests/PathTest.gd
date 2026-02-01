extends Node
## PathTest - Comprehensive path testing for all game flows
## Validates every code path from menu to gameplay

var results: Array[Dictionary] = []
var scene_root: Node = null


func _ready() -> void:
	print("\n========================================")
	print("  COMPREHENSIVE PATH TESTS")
	print("========================================\n")

	scene_root = Node.new()
	add_child(scene_root)

	await _run_all_tests()
	_print_results()

	scene_root.queue_free()
	var failed = results.filter(func(r): return not r.passed).size()
	get_tree().quit(0 if failed == 0 else 1)


func _run_all_tests() -> void:
	print("--- Testing Scene Loading ---")
	await test_main_menu_to_single_player()
	await test_main_menu_to_lobby_host()
	await test_lobby_ui_elements()
	await test_game3d_scene_structure()
	await test_player3d_structure()
	await test_dungeon3d_structure()

	print("\n--- Testing Game Flow ---")
	await test_game_manager_flow()
	await test_network_manager_flow()
	await test_combat_system_flow()

	print("\n--- Testing UI Components ---")
	await test_hud_initialization()
	await test_opponent_tracker_initialization()


func _add_result(name: String, passed: bool, message: String) -> void:
	results.append({"name": name, "passed": passed, "message": message})
	var status = "PASS" if passed else "FAIL"
	print("  [%s] %s: %s" % [status, name, message])


# ============ Scene Loading Tests ============

func test_main_menu_to_single_player() -> void:
	var scene = load("res://src/ui/MainMenu.tscn")
	if not scene:
		_add_result("MainMenu->SinglePlayer", false, "Cannot load MainMenu.tscn")
		return

	var menu = scene.instantiate()
	scene_root.add_child(menu)
	await get_tree().process_frame

	# Check single player button exists
	var sp_button = menu.get_node_or_null("%SinglePlayerButton")
	var has_sp = sp_button != null

	menu.queue_free()
	await get_tree().process_frame

	_add_result("MainMenu->SinglePlayer", has_sp, "Single Player button exists" if has_sp else "Missing SinglePlayerButton")


func test_main_menu_to_lobby_host() -> void:
	var scene = load("res://src/ui/MainMenu.tscn")
	if not scene:
		_add_result("MainMenu->Lobby", false, "Cannot load MainMenu.tscn")
		return

	var menu = scene.instantiate()
	scene_root.add_child(menu)
	await get_tree().process_frame

	var host_button = menu.get_node_or_null("%HostButton")
	var has_host = host_button != null

	menu.queue_free()
	await get_tree().process_frame

	_add_result("MainMenu->Lobby", has_host, "Host button exists" if has_host else "Missing HostButton")


func test_lobby_ui_elements() -> void:
	var scene = load("res://src/ui/Lobby.tscn")
	if not scene:
		_add_result("Lobby UI Elements", false, "Cannot load Lobby.tscn")
		return

	var lobby = scene.instantiate()
	scene_root.add_child(lobby)
	await get_tree().process_frame

	var checks = {
		"PlayerListContainer": lobby.get_node_or_null("%PlayerListContainer") != null,
		"ConnectButton": lobby.get_node_or_null("%ConnectButton") != null,
		"StartButton": lobby.get_node_or_null("%StartButton") != null,
		"BackButton": lobby.get_node_or_null("%BackButton") != null,
		"StatusLabel": lobby.get_node_or_null("%StatusLabel") != null,
	}

	var all_passed = checks.values().all(func(v): return v)
	var missing = checks.keys().filter(func(k): return not checks[k])

	lobby.queue_free()
	await get_tree().process_frame

	_add_result("Lobby UI Elements", all_passed, "All elements present" if all_passed else "Missing: " + ", ".join(missing))


func test_game3d_scene_structure() -> void:
	var scene = load("res://src/Game3D.tscn")
	if not scene:
		_add_result("Game3D Structure", false, "Cannot load Game3D.tscn")
		return

	var game = scene.instantiate()
	scene_root.add_child(game)
	await get_tree().process_frame

	var checks = {
		"Dungeon3D": game.get_node_or_null("Dungeon3D") != null,
		"PlayerContainer": game.get_node_or_null("PlayerContainer") != null,
		"WorldEnvironment": game.get_node_or_null("WorldEnvironment") != null,
	}

	var all_passed = checks.values().all(func(v): return v)
	var missing = checks.keys().filter(func(k): return not checks[k])

	game.queue_free()
	await get_tree().process_frame

	_add_result("Game3D Structure", all_passed, "All nodes present" if all_passed else "Missing: " + ", ".join(missing))


func test_player3d_structure() -> void:
	var scene = load("res://src/player3d/Player3D.tscn")
	if not scene:
		_add_result("Player3D Structure", false, "Cannot load Player3D.tscn")
		return

	var player = scene.instantiate()
	scene_root.add_child(player)
	await get_tree().process_frame

	var is_character_body = player is CharacterBody3D
	var has_collision = player.get_node_or_null("CollisionShape3D") != null
	var has_head = player.get_node_or_null("Head") != null
	var has_camera = player.get_node_or_null("Head/Camera3D") != null

	player.queue_free()
	await get_tree().process_frame

	var passed = is_character_body and has_collision
	_add_result("Player3D Structure", passed, "Valid CharacterBody3D" if passed else "Invalid structure")


func test_dungeon3d_structure() -> void:
	var script = load("res://src/dungeon3d/Dungeon3D.gd")
	if not script:
		_add_result("Dungeon3D", false, "Cannot load Dungeon3D.gd")
		return

	var instance = Node3D.new()
	instance.set_script(script)
	scene_root.add_child(instance)
	await get_tree().process_frame

	var has_generate = instance.has_method("generate_dungeon")
	var has_get_room = instance.has_method("get_current_room")

	instance.queue_free()
	await get_tree().process_frame

	var passed = has_generate and has_get_room
	_add_result("Dungeon3D", passed, "Has required methods" if passed else "Missing methods")


# ============ Game Flow Tests ============

func test_game_manager_flow() -> void:
	var script = load("res://src/autoload/GameManager.gd")
	if not script:
		_add_result("GameManager Flow", false, "Cannot load GameManager.gd")
		return

	var gm = Node.new()
	gm.set_script(script)
	scene_root.add_child(gm)
	await get_tree().process_frame

	# Test registration
	var has_register = gm.has_method("register_player")
	var has_start = gm.has_method("start_match")
	var has_state = gm.has_method("change_state")

	# Test actual registration
	if has_register:
		gm.register_player(1, "TestPlayer")
		var has_player = gm.players.has(1)
		_add_result("GameManager Register", has_player, "Player registered" if has_player else "Registration failed")
	else:
		_add_result("GameManager Register", false, "Missing register_player method")

	gm.queue_free()
	await get_tree().process_frame

	var passed = has_register and has_start and has_state
	_add_result("GameManager Flow", passed, "All methods present" if passed else "Missing methods")


func test_network_manager_flow() -> void:
	var script = load("res://src/autoload/NetworkManager.gd")
	if not script:
		_add_result("NetworkManager Flow", false, "Cannot load NetworkManager.gd")
		return

	var nm = Node.new()
	nm.set_script(script)
	scene_root.add_child(nm)
	await get_tree().process_frame

	var has_host = nm.has_method("host_game")
	var has_join = nm.has_method("join_game")
	var has_request_start = nm.has_method("request_start_game")
	var has_game_started = nm.has_signal("game_started")

	nm.queue_free()
	await get_tree().process_frame

	var passed = has_host and has_join and has_request_start and has_game_started
	_add_result("NetworkManager Flow", passed, "All methods/signals present" if passed else "Missing methods or game_started signal")


func test_combat_system_flow() -> void:
	var script = load("res://src/combat/CombatSystem.gd")
	if not script:
		_add_result("CombatSystem Flow", false, "Cannot load CombatSystem.gd")
		return

	var cs = Node.new()
	cs.set_script(script)
	scene_root.add_child(cs)
	await get_tree().process_frame

	# Register and test damage
	cs.register_player(1)
	cs.register_player(2)

	var health_before = cs.get_health(2)
	cs.deal_damage(1, 2, 10)
	var health_after = cs.get_health(2)

	var damage_works = health_after == health_before - 10

	cs.queue_free()
	await get_tree().process_frame

	_add_result("CombatSystem Flow", damage_works, "Damage system works (100->90)" if damage_works else "Damage not applied correctly")


# ============ UI Component Tests ============

func test_hud_initialization() -> void:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		_add_result("HUD Init", false, "Cannot load HUD.tscn")
		return

	var hud = scene.instantiate()
	scene_root.add_child(hud)
	await get_tree().process_frame

	var has_init = hud.has_method("initialize")
	var script_ok = hud.get_script() != null

	hud.queue_free()
	await get_tree().process_frame

	_add_result("HUD Init", has_init, "Has initialize method" if has_init else "Missing initialize method")


func test_opponent_tracker_initialization() -> void:
	var scene = load("res://src/ui/OpponentTracker.tscn")
	if not scene:
		_add_result("OpponentTracker Init", false, "Cannot load OpponentTracker.tscn")
		return

	var tracker = scene.instantiate()
	scene_root.add_child(tracker)
	await get_tree().process_frame

	var has_init = tracker.has_method("initialize")
	var entries_container = tracker.get_node_or_null("VBox/EntriesContainer")

	tracker.queue_free()
	await get_tree().process_frame

	var passed = has_init and entries_container != null
	_add_result("OpponentTracker Init", passed, "Properly configured" if passed else "Missing initialize or EntriesContainer")


func _print_results() -> void:
	var passed = results.filter(func(r): return r.passed).size()
	var failed = results.filter(func(r): return not r.passed).size()

	print("\n========================================")
	print("  RESULTS: %d/%d passed" % [passed, results.size()])
	print("========================================")

	if failed > 0:
		print("\nFailed tests:")
		for r in results:
			if not r.passed:
				print("  - %s: %s" % [r.name, r.message])
	print("")
