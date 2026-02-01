extends BaseTest
## TestHUD - Unit tests for HUD display and updates

func get_test_methods() -> Array[String]:
	return [
		# Scene existence
		"test_hud_scene_exists",
		"test_hud_instantiates",

		# UI elements
		"test_hud_has_coin_label",
		"test_hud_has_timer_label",
		"test_hud_has_puzzle_progress",
		"test_hud_has_room_progress",
		"test_hud_has_crosshair",
		"test_hud_has_interaction_prompt",

		# State tracking
		"test_hud_timer_state",
		"test_hud_room_tracking",

		# Methods
		"test_hud_has_update_coins",
		"test_hud_has_update_timer",
		"test_hud_has_update_room_progress",
		"test_hud_has_connect_to_dungeon",
		"test_hud_has_interaction_prompt_methods",

		# Groups
		"test_hud_in_hud_group",
	]


func test_hud_scene_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/ui/HUD.tscn")
	return assert_true(exists, "HUD.tscn should exist")


func test_hud_instantiates() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var valid = hud != null and hud is CanvasLayer

	if hud:
		hud.queue_free()

	return assert_true(valid, "HUD should instantiate as CanvasLayer")


func test_hud_has_coin_label() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	# Wait a frame for @onready
	var coin_label = hud.get_node_or_null("MarginContainer/TopBar/CoinContainer/CoinLabel")

	hud.queue_free()
	return assert_not_null(coin_label, "HUD should have CoinLabel")


func test_hud_has_timer_label() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var timer_label = hud.get_node_or_null("MarginContainer/TopBar/TimerContainer/TimerLabel")

	hud.queue_free()
	return assert_not_null(timer_label, "HUD should have TimerLabel")


func test_hud_has_puzzle_progress() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var puzzle_progress = hud.get_node_or_null("MarginContainer/TopBar/TimerContainer/PuzzleProgress")

	hud.queue_free()
	return assert_not_null(puzzle_progress, "HUD should have PuzzleProgress label")


func test_hud_has_room_progress() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var room_progress = hud.get_node_or_null("MarginContainer/TopBar/TimerContainer/RoomProgress")

	hud.queue_free()
	return assert_not_null(room_progress, "HUD should have RoomProgress label")


func test_hud_has_crosshair() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var crosshair = hud.get_node_or_null("Crosshair")
	var horizontal = hud.get_node_or_null("Crosshair/Horizontal")
	var vertical = hud.get_node_or_null("Crosshair/Vertical")

	hud.queue_free()
	return assert_true(crosshair != null and horizontal != null and vertical != null, "HUD should have Crosshair with Horizontal and Vertical bars")


func test_hud_has_interaction_prompt() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var prompt = hud.get_node_or_null("InteractionPrompt")

	hud.queue_free()
	return assert_not_null(prompt, "HUD should have InteractionPrompt")


func test_hud_timer_state() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_match_time = "match_time" in hud
	var has_timer_running = "timer_running" in hud

	hud.queue_free()
	return assert_true(has_match_time and has_timer_running, "HUD should have timer state variables")


func test_hud_room_tracking() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_current = "current_room" in hud
	var has_total = "total_rooms" in hud

	hud.queue_free()
	return assert_true(has_current and has_total, "HUD should have room tracking variables")


func test_hud_has_update_coins() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_method = hud.has_method("_update_coins")

	hud.queue_free()
	return assert_true(has_method, "HUD should have _update_coins method")


func test_hud_has_update_timer() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_method = hud.has_method("_update_timer")

	hud.queue_free()
	return assert_true(has_method, "HUD should have _update_timer method")


func test_hud_has_update_room_progress() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_method = hud.has_method("_update_room_progress")

	hud.queue_free()
	return assert_true(has_method, "HUD should have _update_room_progress method")


func test_hud_has_connect_to_dungeon() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_method = hud.has_method("connect_to_dungeon")

	hud.queue_free()
	return assert_true(has_method, "HUD should have connect_to_dungeon method")


func test_hud_has_interaction_prompt_methods() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()
	var has_show = hud.has_method("show_interaction_prompt")
	var has_hide = hud.has_method("hide_interaction_prompt")

	hud.queue_free()
	return assert_true(has_show and has_hide, "HUD should have show/hide interaction prompt methods")


func test_hud_in_hud_group() -> Dictionary:
	var scene = load("res://src/ui/HUD.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var hud = scene.instantiate()

	# Need to add to tree for groups to work
	var temp = Node.new()
	temp.add_child(hud)

	# Trigger _ready
	var in_group = hud.is_in_group("hud")

	temp.queue_free()
	return assert_true(in_group, "HUD should be in 'hud' group")
