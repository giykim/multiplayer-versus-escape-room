extends Node2D
class_name BasePuzzle
## BasePuzzle - Abstract base class for all puzzle types
## Provides common functionality for puzzle lifecycle, timing, and synchronization

# Signals for puzzle lifecycle events
signal puzzle_started(puzzle_id: String)
signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_reset(puzzle_id: String)

# Puzzle identification and configuration
@export var puzzle_id: String = ""
@export var difficulty: int = 1  # 1-5 scale
@export var time_limit: float = 0.0  # 0 = no limit

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0
var elapsed_time: float = 0.0

# Seed for deterministic generation (synced across network)
var puzzle_seed: int = 0

# Random number generator with seed for deterministic puzzles
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# Generate puzzle_id if not set
	if puzzle_id.is_empty():
		puzzle_id = "puzzle_%d" % get_instance_id()

	# Default seed from GameManager if available
	if GameManager:
		puzzle_seed = GameManager.get_match_seed()

	_setup_puzzle()


func _process(delta: float) -> void:
	if is_active and not is_solved:
		elapsed_time = (Time.get_ticks_msec() / 1000.0) - start_time

		# Check time limit if set
		if time_limit > 0.0 and elapsed_time >= time_limit:
			_on_time_expired()


## Initialize the puzzle with a specific seed for deterministic generation
func initialize(seed_value: int, puzzle_difficulty: int = 1) -> void:
	puzzle_seed = seed_value
	difficulty = puzzle_difficulty
	_rng.seed = puzzle_seed

	print("[%s] Initializing with seed: %d, difficulty: %d" % [puzzle_id, puzzle_seed, difficulty])
	_setup_puzzle()


## Start the puzzle - begins timing and enables interaction
func start_puzzle() -> void:
	if is_active:
		return

	is_active = true
	is_solved = false
	start_time = Time.get_ticks_msec() / 1000.0
	elapsed_time = 0.0

	print("[%s] Puzzle started" % puzzle_id)
	puzzle_started.emit(puzzle_id)

	_on_puzzle_started()


## Called when puzzle is successfully solved
func solve_puzzle() -> void:
	if not is_active or is_solved:
		return

	is_solved = true
	is_active = false
	var time_taken = elapsed_time

	print("[%s] Puzzle solved in %.2f seconds" % [puzzle_id, time_taken])
	puzzle_solved.emit(puzzle_id, time_taken)

	# Notify NetworkManager if in multiplayer
	if NetworkManager and NetworkManager.is_multiplayer_active():
		NetworkManager.notify_puzzle_completed.rpc(puzzle_id, time_taken)
	elif GameManager:
		# Single player mode - directly notify GameManager
		var player_id = 1  # Default single player ID
		if NetworkManager:
			player_id = NetworkManager.get_local_player_id()
		GameManager.on_puzzle_solved(player_id, puzzle_id, time_taken)

	_on_puzzle_solved()


## Called when puzzle fails (time limit, too many wrong attempts, etc.)
func fail_puzzle() -> void:
	if not is_active or is_solved:
		return

	is_active = false

	print("[%s] Puzzle failed" % puzzle_id)
	puzzle_failed.emit(puzzle_id)

	_on_puzzle_failed()


## Reset the puzzle to initial state
func reset_puzzle() -> void:
	is_active = false
	is_solved = false
	start_time = 0.0
	elapsed_time = 0.0

	# Re-seed the RNG for consistent regeneration
	_rng.seed = puzzle_seed

	print("[%s] Puzzle reset" % puzzle_id)
	puzzle_reset.emit(puzzle_id)

	_reset_puzzle()


## Get the current elapsed time
func get_elapsed_time() -> float:
	if is_active:
		return (Time.get_ticks_msec() / 1000.0) - start_time
	return elapsed_time


## Get formatted time string (MM:SS.mm)
func get_time_string() -> String:
	var time = get_elapsed_time()
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


## Get a random integer using the seeded RNG (for deterministic generation)
func get_seeded_randi() -> int:
	return _rng.randi()


## Get a random integer in range using the seeded RNG
func get_seeded_randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Get a random float using the seeded RNG
func get_seeded_randf() -> float:
	return _rng.randf()


# === Virtual Methods (Override in subclasses) ===

## Setup the puzzle state and visuals - called on _ready and after reset
func _setup_puzzle() -> void:
	pass


## Check if the current state is a valid solution
func _check_solution() -> bool:
	return false


## Reset puzzle-specific state - called by reset_puzzle()
func _reset_puzzle() -> void:
	pass


## Called when puzzle starts (after signals)
func _on_puzzle_started() -> void:
	pass


## Called when puzzle is solved (after signals)
func _on_puzzle_solved() -> void:
	pass


## Called when puzzle fails (after signals)
func _on_puzzle_failed() -> void:
	pass


## Called when time limit expires
func _on_time_expired() -> void:
	fail_puzzle()
