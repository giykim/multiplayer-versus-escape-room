extends BaseTest
## TestColorPuzzle - Unit tests for InteractivePuzzlePanel color memorization puzzle

func get_test_methods() -> Array[String]:
	return [
		# Scene existence
		"test_puzzle_scene_exists",
		"test_puzzle_instantiates",

		# Node structure
		"test_puzzle_has_panel_mesh",
		"test_puzzle_has_buttons",
		"test_puzzle_has_labels",
		"test_puzzle_has_interaction_area",

		# Button configuration
		"test_puzzle_has_four_buttons",
		"test_button_areas_created",
		"test_button_colors_defined",

		# Puzzle state
		"test_puzzle_initial_state",
		"test_puzzle_difficulty_property",
		"test_puzzle_presses_needed_property",

		# Sequence generation
		"test_sequence_generated_on_init",
		"test_sequence_length_based_on_difficulty",
		"test_same_seed_same_sequence",

		# Signals
		"test_puzzle_has_solved_signal",
		"test_puzzle_has_started_signal",
		"test_puzzle_has_failed_signal",

		# Methods
		"test_puzzle_has_interact_method",
		"test_puzzle_has_start_method",
		"test_puzzle_has_initialize_method",
		"test_puzzle_has_force_complete",

		# Interaction area
		"test_interaction_area_collision_layer",
		"test_button_meta_puzzle_parent",
	]


func test_puzzle_scene_exists() -> Dictionary:
	var exists = ResourceLoader.exists("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	return assert_true(exists, "InteractivePuzzlePanel.tscn should exist")


func test_puzzle_instantiates() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var valid = puzzle != null and puzzle is Node3D

	if puzzle:
		puzzle.queue_free()

	return assert_true(valid, "Puzzle should instantiate as Node3D")


func test_puzzle_has_panel_mesh() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var panel = puzzle.get_node_or_null("PanelMesh")

	puzzle.queue_free()
	return assert_not_null(panel, "Puzzle should have PanelMesh")


func test_puzzle_has_buttons() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_buttons = puzzle.buttons.size() > 0

	puzzle.queue_free()
	return assert_true(has_buttons, "Puzzle should have button meshes")


func test_puzzle_has_labels() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var status = puzzle.get_node_or_null("StatusLabel")
	var progress = puzzle.get_node_or_null("ProgressLabel")

	puzzle.queue_free()
	return assert_true(status != null and progress != null, "Puzzle should have status and progress labels")


func test_puzzle_has_interaction_area() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var area = puzzle.get_node_or_null("InteractionArea")

	puzzle.queue_free()
	return assert_not_null(area, "Puzzle should have InteractionArea")


func test_puzzle_has_four_buttons() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var count = puzzle.buttons.size()

	puzzle.queue_free()
	return assert_equals(4, count, "Puzzle should have exactly 4 buttons")


func test_button_areas_created() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var area_count = puzzle.button_areas.size()

	puzzle.queue_free()
	return assert_equals(4, area_count, "Puzzle should have 4 button areas")


func test_button_colors_defined() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var colors = puzzle.BUTTON_COLORS
	var has_colors = colors.size() == 4

	puzzle.queue_free()
	return assert_true(has_colors, "Puzzle should have 4 button colors defined")


func test_puzzle_initial_state() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var not_active = not puzzle.is_active
	var not_solved = not puzzle.is_solved
	var not_showing = not puzzle.is_showing_sequence

	puzzle.queue_free()
	return assert_true(not_active and not_solved and not_showing, "Puzzle should start inactive, unsolved, not showing sequence")


func test_puzzle_difficulty_property() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_difficulty = "difficulty" in puzzle
	var valid_range = puzzle.difficulty >= 1 and puzzle.difficulty <= 5

	puzzle.queue_free()
	return assert_true(has_difficulty and valid_range, "Puzzle should have difficulty in range 1-5")


func test_puzzle_presses_needed_property() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_presses = "presses_needed" in puzzle

	puzzle.queue_free()
	return assert_true(has_presses, "Puzzle should have presses_needed property")


func test_sequence_generated_on_init() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	puzzle.initialize(12345, 3)

	var has_sequence = puzzle.sequence.size() > 0

	puzzle.queue_free()
	return assert_true(has_sequence, "Sequence should be generated after initialize()")


func test_sequence_length_based_on_difficulty() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle1 = scene.instantiate()
	puzzle1.initialize(12345, 1)
	var len1 = puzzle1.sequence.size()
	puzzle1.queue_free()

	var puzzle2 = scene.instantiate()
	puzzle2.initialize(12345, 5)
	var len2 = puzzle2.sequence.size()
	puzzle2.queue_free()

	var harder_is_longer = len2 > len1
	return {
		"passed": harder_is_longer,
		"message": "Difficulty 1: %d, Difficulty 5: %d" % [len1, len2]
	}


func test_same_seed_same_sequence() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle1 = scene.instantiate()
	puzzle1.initialize(99999, 3)
	var seq1 = puzzle1.sequence.duplicate()
	puzzle1.queue_free()

	var puzzle2 = scene.instantiate()
	puzzle2.initialize(99999, 3)
	var seq2 = puzzle2.sequence.duplicate()
	puzzle2.queue_free()

	var same = seq1 == seq2
	return assert_true(same, "Same seed should produce same sequence")


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


func test_puzzle_has_force_complete() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_method = puzzle.has_method("force_complete")

	puzzle.queue_free()
	return assert_true(has_method, "Puzzle should have force_complete() method")


func test_interaction_area_collision_layer() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var area = puzzle.get_node_or_null("InteractionArea")
	var layer = area.collision_layer if area else 0

	puzzle.queue_free()
	return assert_equals(32, layer, "InteractionArea should use collision layer 32 (Layer 6)")


func test_button_meta_puzzle_parent() -> Dictionary:
	var scene = load("res://src/puzzles3d/InteractivePuzzlePanel.tscn")
	if not scene:
		return {"passed": false, "message": "Could not load scene"}

	var puzzle = scene.instantiate()
	var has_meta = false
	if puzzle.button_areas.size() > 0:
		var first_area = puzzle.button_areas[0]
		has_meta = first_area.has_meta("puzzle_parent")

	puzzle.queue_free()
	return assert_true(has_meta, "Button areas should have puzzle_parent meta")
