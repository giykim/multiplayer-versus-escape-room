extends Node3D
class_name BasePuzzle3D
## BasePuzzle3D - Abstract base class for all 3D puzzle types
## Provides common functionality for puzzle lifecycle, timing, raycast interaction, and synchronization

# Signals for puzzle lifecycle events
signal puzzle_started(puzzle_id: String)
signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_reset(puzzle_id: String)

# Puzzle identification and configuration
@export var puzzle_id: String = ""
@export var difficulty: int = 1  # 1-5 scale
@export var time_limit: float = 0.0  # 0 = no limit

# Interaction settings
@export var interaction_distance: float = 3.0  # Max distance for raycast interaction
@export var highlight_color: Color = Color(1.0, 0.8, 0.2)  # Emission color when highlighted
@export var highlight_intensity: float = 0.5  # Emission energy when highlighted

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0
var elapsed_time: float = 0.0

# Seed for deterministic generation (synced across network)
var puzzle_seed: int = 0

# Random number generator with seed for deterministic puzzles
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Raycast interaction state
var _current_highlighted_element: PuzzleElement3D = null
var _player_camera: Camera3D = null


func _ready() -> void:
	# Generate puzzle_id if not set
	if puzzle_id.is_empty():
		puzzle_id = "puzzle3d_%d" % get_instance_id()

	# Default seed from GameManager if available
	if GameManager:
		puzzle_seed = GameManager.get_match_seed()

	# Try to find player camera
	_find_player_camera()

	_setup_puzzle()


func _process(delta: float) -> void:
	if is_active and not is_solved:
		elapsed_time = (Time.get_ticks_msec() / 1000.0) - start_time

		# Check time limit if set
		if time_limit > 0.0 and elapsed_time >= time_limit:
			_on_time_expired()

	# Handle raycast highlighting
	if is_active and not is_solved:
		_update_raycast_highlight()


func _input(event: InputEvent) -> void:
	if not is_active or is_solved:
		return

	# Handle interact/click input
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		if _current_highlighted_element:
			_current_highlighted_element.activate()


## Find the player's camera for raycast interaction
func _find_player_camera() -> void:
	# Try to get camera from the scene tree
	var cameras = get_tree().get_nodes_in_group("player_camera")
	if cameras.size() > 0:
		_player_camera = cameras[0] as Camera3D
	else:
		# Fallback: find any Camera3D that is current
		var viewport = get_viewport()
		if viewport:
			_player_camera = viewport.get_camera_3d()


## Update raycast highlighting based on player look direction
func _update_raycast_highlight() -> void:
	if not _player_camera:
		_find_player_camera()
		if not _player_camera:
			return

	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return

	# Cast ray from camera center
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2
	var ray_origin = _player_camera.project_ray_origin(screen_center)
	var ray_direction = _player_camera.project_ray_normal(screen_center)
	var ray_end = ray_origin + ray_direction * interaction_distance

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 4  # Collision layer 3 (bit 2)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	var new_highlighted: PuzzleElement3D = null

	if result:
		var collider = result.collider
		# Check if the collider is a PuzzleElement3D or parent is
		if collider is PuzzleElement3D:
			new_highlighted = collider
		elif collider.get_parent() is PuzzleElement3D:
			new_highlighted = collider.get_parent()

	# Update highlighting
	if new_highlighted != _current_highlighted_element:
		# Unhighlight previous
		if _current_highlighted_element:
			_current_highlighted_element.set_highlighted(false)

		# Highlight new
		if new_highlighted:
			new_highlighted.set_highlighted(true, highlight_color, highlight_intensity)

		_current_highlighted_element = new_highlighted


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

	# Clear any highlighting
	if _current_highlighted_element:
		_current_highlighted_element.set_highlighted(false)
		_current_highlighted_element = null

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

	# Clear any highlighting
	if _current_highlighted_element:
		_current_highlighted_element.set_highlighted(false)
		_current_highlighted_element = null

	print("[%s] Puzzle failed" % puzzle_id)
	puzzle_failed.emit(puzzle_id)

	_on_puzzle_failed()


## Reset the puzzle to initial state
func reset_puzzle() -> void:
	is_active = false
	is_solved = false
	start_time = 0.0
	elapsed_time = 0.0

	# Clear any highlighting
	if _current_highlighted_element:
		_current_highlighted_element.set_highlighted(false)
		_current_highlighted_element = null

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


## Set the player camera for raycast interaction
func set_player_camera(camera: Camera3D) -> void:
	_player_camera = camera


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
