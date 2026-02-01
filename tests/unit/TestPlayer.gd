extends BaseTest
## TestPlayer - Unit tests for Player and Player3D systems

var player_script: Script
var player3d_script: Script


func setup() -> void:
	player_script = load("res://src/player/Player.gd") if ResourceLoader.exists("res://src/player/Player.gd") else null
	player3d_script = load("res://src/player3d/Player3D.gd") if ResourceLoader.exists("res://src/player3d/Player3D.gd") else null


func get_test_methods() -> Array[String]:
	return [
		"test_player_script_exists",
		"test_player3d_script_exists",
		"test_player_has_required_signals",
		"test_player_has_movement_properties",
		"test_player_has_interaction_system",
		"test_player3d_has_first_person_properties",
		"test_player_multiplayer_null_safety",
	]


func test_player_script_exists() -> Dictionary:
	return assert_not_null(player_script, "Player.gd script should exist")


func test_player3d_script_exists() -> Dictionary:
	return assert_not_null(player3d_script, "Player3D.gd script should exist")


func test_player_has_required_signals() -> Dictionary:
	if not player_script:
		return {"passed": false, "message": "Player script not loaded"}

	# Check script text for signal definitions
	var source = player_script.source_code
	var has_interaction_started = "signal interaction_started" in source
	var has_movement_started = "signal movement_started" in source
	var has_player_ready = "signal player_ready" in source

	var passed = has_interaction_started and has_movement_started and has_player_ready
	return {
		"passed": passed,
		"message": "Player has required signals" if passed else "Missing signals in Player"
	}


func test_player_has_movement_properties() -> Dictionary:
	if not player_script:
		return {"passed": false, "message": "Player script not loaded"}

	var source = player_script.source_code
	var has_speed = "move_speed" in source
	var has_acceleration = "acceleration" in source
	var has_friction = "friction" in source

	var passed = has_speed and has_acceleration and has_friction
	return {
		"passed": passed,
		"message": "Movement properties present" if passed else "Missing movement properties"
	}


func test_player_has_interaction_system() -> Dictionary:
	if not player_script:
		return {"passed": false, "message": "Player script not loaded"}

	var source = player_script.source_code
	var has_interact = "_try_interact" in source
	var has_interactables = "_nearby_interactables" in source
	var has_interaction_area = "interaction_area" in source

	var passed = has_interact and has_interactables and has_interaction_area
	return {
		"passed": passed,
		"message": "Interaction system present" if passed else "Missing interaction components"
	}


func test_player3d_has_first_person_properties() -> Dictionary:
	if not player3d_script:
		return {"passed": false, "message": "Player3D script not loaded"}

	var source = player3d_script.source_code
	var has_mouse_sensitivity = "mouse_sensitivity" in source
	var has_head_node = "head" in source or "camera" in source
	var has_fov = "fov" in source or "camera" in source

	var passed = has_mouse_sensitivity and has_head_node
	return {
		"passed": passed,
		"message": "First-person properties present" if passed else "Missing FPS properties"
	}


func test_player_multiplayer_null_safety() -> Dictionary:
	if not player_script:
		return {"passed": false, "message": "Player script not loaded"}

	var source = player_script.source_code

	# Check for null-safe multiplayer checks
	var has_null_check = "if multiplayer and multiplayer.has_multiplayer_peer()" in source

	return {
		"passed": has_null_check,
		"message": "Multiplayer null safety present" if has_null_check else "Missing multiplayer null checks"
	}
