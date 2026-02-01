extends Room3D
class_name PuzzleRoom3D
## PuzzleRoom3D - 3D room variant that spawns and manages a puzzle
## Door is locked until the puzzle is solved

# Puzzle scene paths (extend as more 3D puzzles are created)
const PUZZLE_SCENES_3D: Dictionary = {
	"sliding_tile": "res://src/puzzles/logic/SlidingTilePuzzle3D.tscn",
	"pattern_match": "res://src/puzzles/logic/PatternMatchPuzzle3D.tscn",
	"wire_connect": "res://src/puzzles/logic/WireConnectPuzzle3D.tscn",
	"sequence_memory": "res://src/puzzles/logic/SequenceMemoryPuzzle3D.tscn",
	"lock_pick": "res://src/puzzles/logic/LockPickPuzzle3D.tscn"
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
	if puzzle_type.is_empty():
		push_warning("[PuzzleRoom3D %d] No puzzle type specified" % room_index)
		return

	# Try to load 3D version first
	var puzzle_scene_path = PUZZLE_SCENES_3D.get(puzzle_type, "")
	var is_3d_puzzle = true

	# Check if 3D scene exists
	if puzzle_scene_path.is_empty() or not ResourceLoader.exists(puzzle_scene_path):
		# Fall back to 2D puzzle
		puzzle_scene_path = PUZZLE_SCENES_2D_FALLBACK.get(puzzle_type, "")
		is_3d_puzzle = false

		if puzzle_scene_path.is_empty() or not ResourceLoader.exists(puzzle_scene_path):
			push_warning("[PuzzleRoom3D %d] No puzzle scene found for: %s" % [room_index, puzzle_type])
			# Unlock the door if no puzzle can be spawned
			set_door_locked("right", false)
			return

	var puzzle_scene = load(puzzle_scene_path)
	if not puzzle_scene:
		push_warning("[PuzzleRoom3D %d] Failed to load puzzle scene: %s" % [room_index, puzzle_scene_path])
		set_door_locked("right", false)
		return

	current_puzzle = puzzle_scene.instantiate()
	if not current_puzzle:
		push_warning("[PuzzleRoom3D %d] Failed to instantiate puzzle" % room_index)
		set_door_locked("right", false)
		return

	# Position puzzle at spawn point
	if puzzle_spawn:
		if is_3d_puzzle:
			current_puzzle.position = puzzle_spawn.position
		else:
			# For 2D puzzles, we'd need a SubViewport setup
			# For now, position it in the center
			current_puzzle.position = puzzle_spawn.position
	else:
		current_puzzle.position = Vector3(0, 1, 0)  # Center of room, slightly elevated

	# Initialize puzzle with room seed
	var puzzle_seed_value = room_seed
	if GameManager:
		puzzle_seed_value = GameManager.get_match_seed() + room_seed

	add_child(current_puzzle)

	# Initialize puzzle if it has the method
	if current_puzzle.has_method("initialize"):
		current_puzzle.initialize(puzzle_seed_value, difficulty)

	# Connect puzzle signals
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.puzzle_solved.connect(_on_puzzle_solved)
	if current_puzzle.has_signal("puzzle_failed"):
		current_puzzle.puzzle_failed.connect(_on_puzzle_failed)

	puzzle_spawned.emit(current_puzzle)
	print("[PuzzleRoom3D %d] Spawned puzzle: %s (3D: %s)" % [room_index, puzzle_type, is_3d_puzzle])


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
