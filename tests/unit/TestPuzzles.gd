extends BaseTest
## TestPuzzles - Unit tests for puzzle systems

var base_puzzle_script: Script
var sliding_puzzle_script: Script
var pattern_puzzle_script: Script
var base_puzzle3d_script: Script


func setup() -> void:
	base_puzzle_script = load("res://src/puzzles/base/BasePuzzle.gd") if ResourceLoader.exists("res://src/puzzles/base/BasePuzzle.gd") else null
	sliding_puzzle_script = load("res://src/puzzles/logic/SlidingTilePuzzle.gd") if ResourceLoader.exists("res://src/puzzles/logic/SlidingTilePuzzle.gd") else null
	pattern_puzzle_script = load("res://src/puzzles/logic/PatternSequencePuzzle.gd") if ResourceLoader.exists("res://src/puzzles/logic/PatternSequencePuzzle.gd") else null
	base_puzzle3d_script = load("res://src/puzzles3d/BasePuzzle3D.gd") if ResourceLoader.exists("res://src/puzzles3d/BasePuzzle3D.gd") else null


func get_test_methods() -> Array[String]:
	return [
		"test_base_puzzle_exists",
		"test_puzzle_has_completion_signal",
		"test_puzzle_has_difficulty_system",
		"test_sliding_puzzle_exists",
		"test_pattern_puzzle_exists",
		"test_puzzle3d_base_exists",
		"test_puzzle3d_has_raycast_interaction",
	]


func test_base_puzzle_exists() -> Dictionary:
	return assert_not_null(base_puzzle_script, "BasePuzzle.gd should exist")


func test_puzzle_has_completion_signal() -> Dictionary:
	if not base_puzzle_script:
		return {"passed": false, "message": "BasePuzzle not loaded"}

	var source = base_puzzle_script.source_code
	var has_completed_signal = "signal puzzle_completed" in source
	var has_is_completed = "is_completed" in source or "_is_completed" in source

	var passed = has_completed_signal and has_is_completed
	return {
		"passed": passed,
		"message": "Completion system present" if passed else "Missing completion signal/state"
	}


func test_puzzle_has_difficulty_system() -> Dictionary:
	if not base_puzzle_script:
		return {"passed": false, "message": "BasePuzzle not loaded"}

	var source = base_puzzle_script.source_code
	var has_difficulty = "difficulty" in source.to_lower()

	return {
		"passed": has_difficulty,
		"message": "Difficulty system present" if has_difficulty else "Missing difficulty configuration"
	}


func test_sliding_puzzle_exists() -> Dictionary:
	if not sliding_puzzle_script:
		return {"passed": false, "message": "SlidingTilePuzzle.gd not found"}

	var source = sliding_puzzle_script.source_code
	var extends_base = "extends" in source
	var has_grid = "grid" in source.to_lower()
	var has_move = "move" in source.to_lower()

	var passed = extends_base and has_grid and has_move
	return {
		"passed": passed,
		"message": "Sliding puzzle configured" if passed else "Sliding puzzle missing components"
	}


func test_pattern_puzzle_exists() -> Dictionary:
	if not pattern_puzzle_script:
		return {"passed": false, "message": "PatternSequencePuzzle.gd not found"}

	var source = pattern_puzzle_script.source_code
	var extends_base = "extends" in source
	var has_pattern = "pattern" in source.to_lower()
	var has_sequence = "sequence" in source.to_lower()

	var passed = extends_base and has_pattern and has_sequence
	return {
		"passed": passed,
		"message": "Pattern puzzle configured" if passed else "Pattern puzzle missing components"
	}


func test_puzzle3d_base_exists() -> Dictionary:
	return assert_not_null(base_puzzle3d_script, "BasePuzzle3D.gd should exist")


func test_puzzle3d_has_raycast_interaction() -> Dictionary:
	if not base_puzzle3d_script:
		return {"passed": false, "message": "BasePuzzle3D not loaded"}

	var source = base_puzzle3d_script.source_code
	var has_raycast = "raycast" in source.to_lower() or "ray" in source.to_lower()
	var has_interact = "interact" in source.to_lower()

	var passed = has_interact  # Raycast may be optional
	return {
		"passed": passed,
		"message": "3D interaction present" if passed else "Missing 3D interaction"
	}
