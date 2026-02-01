extends Room3D
class_name PuzzleRoom3D
## PuzzleRoom3D - 3D room variant that spawns and manages a puzzle
## Door is locked until the puzzle is solved

# Default 3D puzzle panel used for all puzzle types until specialized versions are created
const DEFAULT_3D_PUZZLE: String = "res://src/puzzles3d/InteractivePuzzlePanel.tscn"

# Puzzle scene paths (extend as more 3D puzzles are created)
const PUZZLE_SCENES_3D: Dictionary = {
	"sliding_tile": "res://src/puzzles3d/InteractivePuzzlePanel.tscn",
	"pattern_match": "res://src/puzzles3d/InteractivePuzzlePanel.tscn",
	"wire_connect": "res://src/puzzles3d/InteractivePuzzlePanel.tscn",
	"sequence_memory": "res://src/puzzles3d/InteractivePuzzlePanel.tscn",
	"lock_pick": "res://src/puzzles3d/InteractivePuzzlePanel.tscn"
}

# Fallback to 2D puzzles rendered on a viewport (if 3D version doesn't exist)
# Note: Maps puzzle_type names from DungeonGenerator to actual scene files
const PUZZLE_SCENES_2D_FALLBACK: Dictionary = {
	"sliding_tile": "res://src/puzzles/logic/SlidingTilePuzzle.tscn",
	"pattern_match": "res://src/puzzles/logic/PatternSequencePuzzle.tscn",  # Use PatternSequence for pattern_match
	"wire_connect": "res://src/puzzles/logic/WireConnectPuzzle.tscn",
	"sequence_memory": "res://src/puzzles/logic/PatternSequencePuzzle.tscn",  # Use PatternSequence as fallback
	"lock_pick": "res://src/puzzles/logic/SlidingTilePuzzle.tscn"  # Use SlidingTile as fallback
}

# Puzzle state
var puzzle_active: bool = false


func _ready() -> void:
	# Force room type to PUZZLE
	room_type = RoomType.PUZZLE
	super._ready()


## Override puzzle spawning for 3D puzzles
func _spawn_puzzle() -> void:
	# Don't spawn if puzzle_type isn't set yet (will be called again from initialize_from_data)
	if puzzle_type.is_empty():
		print("[PuzzleRoom3D %d] Waiting for puzzle_type to be set..." % room_index)
		return

	# Don't spawn twice
	if current_puzzle != null:
		print("[PuzzleRoom3D %d] Puzzle already spawned" % room_index)
		return

	print("[PuzzleRoom3D %d] Spawning puzzle type: %s" % [room_index, puzzle_type])

	# Always use the default 3D puzzle panel
	var puzzle_scene_path = DEFAULT_3D_PUZZLE

	# Check if the scene exists
	if not ResourceLoader.exists(puzzle_scene_path):
		push_error("[PuzzleRoom3D %d] Puzzle scene not found: %s" % [room_index, puzzle_scene_path])
		set_door_locked("right", false)
		return

	var puzzle_scene = load(puzzle_scene_path)
	if not puzzle_scene:
		push_error("[PuzzleRoom3D %d] Failed to load puzzle scene: %s" % [room_index, puzzle_scene_path])
		set_door_locked("right", false)
		return

	current_puzzle = puzzle_scene.instantiate()
	if not current_puzzle:
		push_error("[PuzzleRoom3D %d] Failed to instantiate puzzle" % room_index)
		set_door_locked("right", false)
		return

	# Position puzzle in the center of the room, facing the player spawn
	# Player spawns at (-3, 1, 0), so puzzle should be at center facing that direction
	current_puzzle.position = Vector3(0, 1.5, 0)  # Center of room, at eye level
	current_puzzle.rotation.y = deg_to_rad(180)  # Face toward the left side where player spawns

	# Initialize puzzle with room seed
	var puzzle_seed_value = room_seed
	if GameManager:
		puzzle_seed_value = GameManager.get_match_seed() + room_seed

	add_child(current_puzzle)
	print("[PuzzleRoom3D %d] Puzzle added to scene tree" % room_index)

	# Initialize puzzle if it has the method
	if current_puzzle.has_method("initialize"):
		current_puzzle.initialize(puzzle_seed_value, difficulty)
		print("[PuzzleRoom3D %d] Puzzle initialized with seed %d, difficulty %d" % [room_index, puzzle_seed_value, difficulty])

	# Connect puzzle signals
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.puzzle_solved.connect(_on_puzzle_solved)
		print("[PuzzleRoom3D %d] Connected puzzle_solved signal" % room_index)
	if current_puzzle.has_signal("puzzle_failed"):
		current_puzzle.puzzle_failed.connect(_on_puzzle_failed)

	puzzle_spawned.emit(current_puzzle)
	print("[PuzzleRoom3D %d] Spawned puzzle: %s at position %s" % [room_index, puzzle_type, current_puzzle.position])


## Override activate to start puzzle
func activate() -> void:
	print("[PuzzleRoom3D %d] Activated" % room_index)

	if current_puzzle and not puzzle_active:
		puzzle_active = true
		if current_puzzle.has_method("start_puzzle"):
			current_puzzle.start_puzzle()


## Override player enter to start puzzle
func on_player_enter(player_id: int) -> void:
	super.on_player_enter(player_id)

	# Auto-start puzzle when first player enters
	if current_puzzle and not puzzle_active:
		puzzle_active = true
		if current_puzzle.has_method("start_puzzle"):
			current_puzzle.start_puzzle()


## Get the current puzzle instance
func get_puzzle() -> Node3D:
	return current_puzzle


## Check if the puzzle is active
func is_puzzle_active() -> bool:
	return puzzle_active


## Force complete the puzzle (for debug/testing)
func debug_complete_puzzle() -> void:
	if current_puzzle and current_puzzle.has_method("force_complete"):
		current_puzzle.force_complete()
	else:
		complete_room()
