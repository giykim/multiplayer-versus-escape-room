extends Room
class_name PuzzleRoom
## PuzzleRoom - Room type specifically for puzzle challenges
## Extends base Room with puzzle-specific functionality

# Puzzle-specific signals
signal hint_requested(puzzle_id: String)
signal puzzle_progress_changed(progress: float)

# Puzzle configuration
@export var allow_hints: bool = true
@export var max_hints: int = 3
@export var hint_cost: int = 25  # Coins to use a hint

# Puzzle state
var hints_used: int = 0
var puzzle_progress: float = 0.0
var best_time: float = -1.0

# Time tracking
var puzzle_start_time: float = 0.0


func _ready() -> void:
	room_type = RoomType.PUZZLE
	super._ready()


func _initialize_room() -> void:
	# Set up puzzle room specific elements
	_setup_puzzle_ui()
	super._initialize_room()


## Setup puzzle-specific UI elements
func _setup_puzzle_ui() -> void:
	# Placeholder for puzzle UI (timer display, hint button, etc.)
	pass


## Override puzzle spawn to add additional setup
func _spawn_puzzle() -> void:
	super._spawn_puzzle()

	if current_puzzle:
		# Connect to additional puzzle signals if available
		if current_puzzle.has_signal("progress_changed"):
			current_puzzle.progress_changed.connect(_on_puzzle_progress_changed)


## Request a hint for the current puzzle
func request_hint() -> bool:
	if not allow_hints:
		print("[PuzzleRoom %d] Hints not allowed" % room_index)
		return false

	if hints_used >= max_hints:
		print("[PuzzleRoom %d] No hints remaining" % room_index)
		return false

	# Check if player has enough coins
	if GameManager:
		var player_id = _get_local_player_id()
		var player_coins = GameManager.player_coins.get(player_id, 0)
		if player_coins < hint_cost:
			print("[PuzzleRoom %d] Not enough coins for hint (need %d, have %d)" % [
				room_index, hint_cost, player_coins
			])
			return false

		# Deduct coins
		GameManager.player_coins[player_id] -= hint_cost

	hints_used += 1

	# Request hint from puzzle
	if current_puzzle and current_puzzle.has_method("show_hint"):
		current_puzzle.show_hint()

	hint_requested.emit(current_puzzle.puzzle_id if current_puzzle else "")
	print("[PuzzleRoom %d] Hint used (%d/%d remaining)" % [
		room_index, max_hints - hints_used, max_hints
	])

	return true


## Get remaining hints
func get_remaining_hints() -> int:
	return max_hints - hints_used


## Get puzzle progress (0.0 to 1.0)
func get_puzzle_progress() -> float:
	return puzzle_progress


## Get current puzzle elapsed time
func get_puzzle_time() -> float:
	if current_puzzle:
		return current_puzzle.get_elapsed_time()
	return 0.0


## Get formatted puzzle time string
func get_puzzle_time_string() -> String:
	if current_puzzle:
		return current_puzzle.get_time_string()
	return "00:00.00"


## Reset the puzzle room for retry
func reset_puzzle() -> void:
	hints_used = 0
	puzzle_progress = 0.0
	is_completed = false

	# Lock forward door again
	set_door_locked("right", true)

	# Reset the puzzle
	if current_puzzle:
		current_puzzle.reset_puzzle()

	print("[PuzzleRoom %d] Reset for retry" % room_index)


## Get local player ID helper
func _get_local_player_id() -> int:
	if NetworkManager and NetworkManager.has_method("get_local_player_id"):
		return NetworkManager.get_local_player_id()
	return 1  # Default single player ID


# === Signal Handlers ===

func _on_puzzle_progress_changed(progress: float) -> void:
	puzzle_progress = progress
	puzzle_progress_changed.emit(progress)


func _on_puzzle_solved(puzzle_id: String, time_taken: float) -> void:
	# Track best time
	if best_time < 0 or time_taken < best_time:
		best_time = time_taken

	# Calculate bonus based on performance
	var time_bonus = _calculate_time_bonus(time_taken)
	var hint_penalty = hints_used * 10

	var final_bonus = maxi(time_bonus - hint_penalty, 0)

	if GameManager and final_bonus > 0:
		var player_id = _get_local_player_id()
		GameManager.player_coins[player_id] = GameManager.player_coins.get(player_id, 0) + final_bonus
		print("[PuzzleRoom %d] Time bonus: +%d coins" % [room_index, final_bonus])

	super._on_puzzle_solved(puzzle_id, time_taken)


## Calculate time bonus based on completion speed
func _calculate_time_bonus(time_taken: float) -> int:
	# Bonus tiers based on difficulty and time
	var base_bonus = 50
	var expected_time = difficulty * 30.0  # 30 seconds per difficulty level

	if time_taken < expected_time * 0.5:
		return base_bonus * 2  # Double bonus for very fast
	elif time_taken < expected_time:
		return base_bonus  # Full bonus for under expected time
	elif time_taken < expected_time * 1.5:
		return base_bonus / 2  # Half bonus for slightly over
	else:
		return 0  # No bonus for slow completion
