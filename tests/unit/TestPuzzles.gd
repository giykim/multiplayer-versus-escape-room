extends BaseTest
## TestPuzzles - Comprehensive unit tests for puzzle systems


func get_test_methods() -> Array[String]:
	return [
		# Scene tests
		"test_puzzle_panel_scene_exists",
		"test_puzzle_panel_instantiates",

		# Signal tests
		"test_puzzle_has_solved_signal",
		"test_puzzle_has_started_signal",
		"test_puzzle_has_failed_signal",

		# Method tests
		"test_puzzle_has_interact_method",
		"test_puzzle_has_start_method",
		"test_puzzle_has_initialize_method",

		# State tests
		"test_puzzle_initial_state_inactive",
		"test_puzzle_initial_state_unsolved",

		# Configuration tests
		"test_puzzle_has_difficulty",
		"test_puzzle_difficulty_affects_presses",

		# 2D puzzle tests
		"test_sliding_puzzle_exists",
		"test_pattern_puzzle_exists",
	]


func test_puzzle_panel_scene_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	return assert_true(exists, "InteractivePuzzlePanel.tscn should exist")


func test_puzzle_panel_instantiates() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var valid = puzzle != null

	if puzzle:
		puzzle.queue_free()

	return assert_true(valid, "Puzzle should instantiate successfully")


func test_puzzle_has_solved_signal() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_signal = puzzle.has_signal("puzzle_solved")
	puzzle.queue_free()

	return assert_true(has_signal, "Puzzle should have puzzle_solved signal")


func test_puzzle_has_started_signal() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_signal = puzzle.has_signal("puzzle_started")
	puzzle.queue_free()

	return assert_true(has_signal, "Puzzle should have puzzle_started signal")


func test_puzzle_has_failed_signal() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_signal = puzzle.has_signal("puzzle_failed")
	puzzle.queue_free()

	return assert_true(has_signal, "Puzzle should have puzzle_failed signal")


func test_puzzle_has_interact_method() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_method = puzzle.has_method("interact")
	puzzle.queue_free()

	return assert_true(has_method, "Puzzle should have interact() method")


func test_puzzle_has_start_method() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_method = puzzle.has_method("start_puzzle")
	puzzle.queue_free()

	return assert_true(has_method, "Puzzle should have start_puzzle() method")


func test_puzzle_has_initialize_method() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_method = puzzle.has_method("initialize")
	puzzle.queue_free()

	return assert_true(has_method, "Puzzle should have initialize() method")


func test_puzzle_initial_state_inactive() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var is_inactive = puzzle.is_active == false
	puzzle.queue_free()

	return assert_true(is_inactive, "Puzzle should start inactive")


func test_puzzle_initial_state_unsolved() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var is_unsolved = puzzle.is_solved == false
	puzzle.queue_free()

	return assert_true(is_unsolved, "Puzzle should start unsolved")


func test_puzzle_has_difficulty() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_difficulty = "difficulty" in puzzle
	puzzle.queue_free()

	return assert_true(has_difficulty, "Puzzle should have difficulty property")


func test_puzzle_difficulty_affects_presses() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle1 = scene.instantiate()
	puzzle1.initialize(12345, 1)  # Low difficulty
	var presses1 = puzzle1.presses_needed
	puzzle1.queue_free()

	var puzzle2 = scene.instantiate()
	puzzle2.initialize(12345, 5)  # High difficulty
	var presses2 = puzzle2.presses_needed
	puzzle2.queue_free()

	var harder = presses2 > presses1
	return {
		"passed": harder,
		"message": "Difficulty 1: %d presses, Difficulty 5: %d presses" % [presses1, presses2]
	}


func test_sliding_puzzle_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/puzzles/logic/SlidingTilePuzzle.tscn")
	return assert_true(exists, "SlidingTilePuzzle.tscn should exist")


func test_pattern_puzzle_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/puzzles/logic/PatternSequencePuzzle.tscn")
	return assert_true(exists, "PatternSequencePuzzle.tscn should exist")
