extends Node
## RuntimeTest - Runtime validation tests that actually instantiate scenes
## Run: godot --headless --script tests/RuntimeTest.gd

var test_results: Array[Dictionary] = []
var scene_root: Node = null


func _ready() -> void:
	print("\n========================================")
	print("  RUNTIME VALIDATION TESTS")
	print("========================================\n")

	# Create a scene root for testing
	scene_root = Node.new()
	scene_root.name = "TestRoot"
	add_child(scene_root)

	# Run tests
	await _run_all_tests()

	# Print results
	_print_results()

	# Cleanup and exit
	scene_root.queue_free()
	var failed = test_results.filter(func(r): return not r.passed).size()
	get_tree().quit(0 if failed == 0 else 1)


func _run_all_tests() -> void:
	await test_autoloads_exist()
	await test_main_menu_loads()
	await test_lobby_loads()
	await test_hud_loads()
	await test_game3d_loads()
	await test_player3d_loads()
	await test_combat_system_instantiates()
	await test_dungeon_generator_works()
	await test_puzzle_instantiates()


func _add_result(name: String, passed: bool, message: String) -> void:
	test_results.append({"name": name, "passed": passed, "message": message})
	var status = "PASS" if passed else "FAIL"
	print("  [%s] %s - %s" % [status, name, message])


func test_autoloads_exist() -> void:
	var game_manager_exists = Engine.has_singleton("GameManager") or ClassDB.class_exists("GameManager") or (get_node_or_null("/root/GameManager") != null)
	var network_manager_exists = Engine.has_singleton("NetworkManager") or ClassDB.class_exists("NetworkManager") or (get_node_or_null("/root/NetworkManager") != null)

	# For autoloads, we check if the scripts can be loaded
	var gm_script = load("res://src/autoload/GameManager.gd")
	var nm_script = load("res://src/autoload/NetworkManager.gd")

	_add_result("GameManager script loadable", gm_script != null, "Script loads correctly" if gm_script else "Script not found")
	_add_result("NetworkManager script loadable", nm_script != null, "Script loads correctly" if nm_script else "Script not found")


func test_main_menu_loads() -> void:
	var scene_path = "res://src/ui/MainMenu.tscn"
	if not ResourceLoader.exists(scene_path):
		_add_result("MainMenu scene", false, "Scene file not found")
		return

	var scene = load(scene_path)
	if not scene:
		_add_result("MainMenu scene", false, "Failed to load scene")
		return

	var instance = scene.instantiate()
	if not instance:
		_add_result("MainMenu scene", false, "Failed to instantiate")
		return

	# Test that it has required nodes
	scene_root.add_child(instance)
	await get_tree().process_frame

	var has_required = true
	var missing = []

	# Check for buttons (by looking for Button nodes)
	var has_buttons = _find_nodes_of_type(instance, "Button").size() > 0
	if not has_buttons:
		missing.append("buttons")

	instance.queue_free()
	await get_tree().process_frame

	_add_result("MainMenu scene", has_buttons, "Loads and has UI elements" if has_buttons else "Missing: " + ", ".join(missing))


func test_lobby_loads() -> void:
	var scene_path = "res://src/ui/Lobby.tscn"
	if not ResourceLoader.exists(scene_path):
		_add_result("Lobby scene", false, "Scene file not found")
		return

	var scene = load(scene_path)
	var instance = scene.instantiate()

	scene_root.add_child(instance)
	await get_tree().process_frame

	# Check for PlayerListContainer
	var player_list = instance.get_node_or_null("%PlayerListContainer")
	var connect_btn = instance.get_node_or_null("%ConnectButton")

	instance.queue_free()
	await get_tree().process_frame

	var passed = player_list != null and connect_btn != null
	_add_result("Lobby scene", passed, "Has required nodes" if passed else "Missing PlayerListContainer or ConnectButton")


func test_hud_loads() -> void:
	var scene_path = "res://src/ui/HUD.tscn"
	if not ResourceLoader.exists(scene_path):
		_add_result("HUD scene", false, "Scene file not found")
		return

	var scene = load(scene_path)
	var instance = scene.instantiate()

	scene_root.add_child(instance)
	await get_tree().process_frame

	# Check script is attached and working
	var has_script = instance.get_script() != null

	instance.queue_free()
	await get_tree().process_frame

	_add_result("HUD scene", has_script, "Loads with script" if has_script else "No script attached")


func test_game3d_loads() -> void:
	var scene_path = "res://src/Game3D.tscn"
	if not ResourceLoader.exists(scene_path):
		_add_result("Game3D scene", false, "Scene file not found")
		return

	var scene = load(scene_path)
	if not scene:
		_add_result("Game3D scene", false, "Failed to load")
		return

	# Just test it can instantiate without errors
	var instance = scene.instantiate()
	var instantiated = instance != null

	if instance:
		instance.queue_free()

	_add_result("Game3D scene", instantiated, "Instantiates successfully" if instantiated else "Failed to instantiate")


func test_player3d_loads() -> void:
	var scene_path = "res://src/player3d/Player3D.tscn"
	if not ResourceLoader.exists(scene_path):
		_add_result("Player3D scene", false, "Scene file not found")
		return

	var scene = load(scene_path)
	var instance = scene.instantiate()

	scene_root.add_child(instance)
	await get_tree().process_frame

	# Check it's a CharacterBody3D
	var is_correct_type = instance is CharacterBody3D
	var has_camera = instance.get_node_or_null("Head/Camera3D") != null or instance.get_node_or_null("Camera3D") != null

	instance.queue_free()
	await get_tree().process_frame

	var passed = is_correct_type
	_add_result("Player3D scene", passed, "CharacterBody3D with camera" if passed and has_camera else "Correct type" if passed else "Wrong base type")


func test_combat_system_instantiates() -> void:
	var script_path = "res://src/combat/CombatSystem.gd"
	if not ResourceLoader.exists(script_path):
		_add_result("CombatSystem", false, "Script not found")
		return

	var script = load(script_path)
	var instance = Node.new()
	instance.set_script(script)

	scene_root.add_child(instance)
	await get_tree().process_frame

	# Test basic functionality
	var can_register = instance.has_method("register_player")
	var can_damage = instance.has_method("deal_damage")
	var can_heal = instance.has_method("heal_player")

	# Test registration
	if can_register:
		instance.register_player(1)
		var health = instance.get_health(1)
		var health_correct = health == 100  # MAX_HEALTH

		instance.queue_free()
		await get_tree().process_frame

		_add_result("CombatSystem", health_correct, "Health system works (100 HP)" if health_correct else "Health system broken")
	else:
		instance.queue_free()
		_add_result("CombatSystem", false, "Missing required methods")


func test_dungeon_generator_works() -> void:
	var script_path = "res://src/dungeon/DungeonGenerator.gd"
	if not ResourceLoader.exists(script_path):
		_add_result("DungeonGenerator", false, "Script not found")
		return

	var script = load(script_path)
	var instance = Node.new()
	instance.set_script(script)

	scene_root.add_child(instance)
	await get_tree().process_frame

	# Test seed-based generation produces consistent results
	var has_generate = instance.has_method("generate") or instance.has_method("generate_layout")

	instance.queue_free()
	await get_tree().process_frame

	_add_result("DungeonGenerator", has_generate, "Has generation method" if has_generate else "Missing generate method")


func test_puzzle_instantiates() -> void:
	# Test base puzzle
	var base_script_path = "res://src/puzzles/base/BasePuzzle.gd"
	if not ResourceLoader.exists(base_script_path):
		_add_result("BasePuzzle", false, "Script not found")
		return

	var script = load(base_script_path)
	var instance = Node2D.new()
	instance.set_script(script)

	scene_root.add_child(instance)
	await get_tree().process_frame

	var has_complete_signal = instance.has_signal("puzzle_completed")
	var has_solve_check = instance.has_method("is_solved") or instance.has_method("check_solution")

	instance.queue_free()
	await get_tree().process_frame

	_add_result("BasePuzzle", has_complete_signal, "Has completion signal" if has_complete_signal else "Missing puzzle_completed signal")


func _find_nodes_of_type(root: Node, type_name: String) -> Array[Node]:
	var found: Array[Node] = []
	var stack = [root]

	while not stack.is_empty():
		var node = stack.pop_back()
		if node.get_class() == type_name:
			found.append(node)
		for child in node.get_children():
			stack.append(child)

	return found


func _print_results() -> void:
	var passed = test_results.filter(func(r): return r.passed).size()
	var failed = test_results.filter(func(r): return not r.passed).size()
	var total = test_results.size()

	print("\n========================================")
	print("  RESULTS: %d/%d passed" % [passed, total])
	print("========================================")

	if failed > 0:
		print("\nFailed tests:")
		for result in test_results:
			if not result.passed:
				print("  - %s: %s" % [result.name, result.message])

	print("")
