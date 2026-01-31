extends BasePuzzle
class_name SlidingTilePuzzle
## SlidingTilePuzzle - Classic sliding tile puzzle implementation
## Players slide tiles to arrange them in numerical order

# Configuration
@export var grid_size: int = 3  # 3x3 default, can be 4x4 or 5x5 for harder puzzles
@export var tile_size: Vector2 = Vector2(100, 100)
@export var tile_spacing: float = 4.0

# Puzzle state
var tiles: Array[PuzzleTile] = []
var grid: Array = []  # 2D array of tile references
var empty_position: Vector2i = Vector2i.ZERO
var move_count: int = 0

# Difficulty affects shuffle intensity
const MIN_SHUFFLES: Dictionary = {
	1: 10,   # Very easy
	2: 25,   # Easy
	3: 50,   # Medium
	4: 100,  # Hard
	5: 200   # Expert
}

# UI components
var container: Control = null
var move_counter_label: Label = null
var timer_label: Label = null

# Animation state
var is_animating: bool = false


func _ready() -> void:
	puzzle_id = "sliding_tile_%d" % get_instance_id()
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)

	# Update timer display
	if timer_label and is_active:
		timer_label.text = "Time: %s" % get_time_string()


func _setup_puzzle() -> void:
	_clear_existing_tiles()
	_create_grid_container()
	_create_tiles()
	_shuffle_tiles()
	_update_tile_visuals()
	move_count = 0
	_update_move_counter()


func _clear_existing_tiles() -> void:
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()
	grid.clear()


func _create_grid_container() -> void:
	# Create main container if not exists
	if not container:
		container = Control.new()
		container.name = "TileContainer"
		add_child(container)

	# Calculate total size
	var total_size = Vector2(
		grid_size * tile_size.x + (grid_size - 1) * tile_spacing,
		grid_size * tile_size.y + (grid_size - 1) * tile_spacing
	)

	# Center the container
	container.position = -total_size / 2
	container.size = total_size

	# Create timer label if not exists
	if not timer_label:
		timer_label = Label.new()
		timer_label.name = "TimerLabel"
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.position = Vector2(-100, -total_size.y / 2 - 40)
		timer_label.size = Vector2(200, 30)
		timer_label.add_theme_font_size_override("font_size", 20)
		add_child(timer_label)

	# Create move counter label if not exists
	if not move_counter_label:
		move_counter_label = Label.new()
		move_counter_label.name = "MoveCounterLabel"
		move_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		move_counter_label.position = Vector2(-100, total_size.y / 2 + 10)
		move_counter_label.size = Vector2(200, 30)
		move_counter_label.add_theme_font_size_override("font_size", 18)
		add_child(move_counter_label)


func _create_tiles() -> void:
	# Initialize grid array
	grid.resize(grid_size)
	for i in grid_size:
		grid[i] = []
		grid[i].resize(grid_size)

	# Create tiles
	var tile_index = 1
	for row in grid_size:
		for col in grid_size:
			var tile = _create_tile(tile_index, Vector2i(col, row))
			tiles.append(tile)
			grid[row][col] = tile
			container.add_child(tile)

			# Last tile is empty
			if row == grid_size - 1 and col == grid_size - 1:
				tile.setup(0, Vector2i(col, row), Vector2i(col, row))
				empty_position = Vector2i(col, row)
			else:
				# Correct position is where the tile should end up
				# Tile 1 at (0,0), tile 2 at (1,0), etc.
				var correct_pos = Vector2i((tile_index - 1) % grid_size, (tile_index - 1) / grid_size)
				tile.setup(tile_index, Vector2i(col, row), correct_pos)
				tile_index += 1


func _create_tile(value: int, grid_pos: Vector2i) -> PuzzleTile:
	var tile = PuzzleTile.new()
	tile.name = "Tile_%d" % value
	tile.custom_minimum_size = tile_size
	tile.size = tile_size
	tile.position = _grid_to_pixel(grid_pos)

	# Connect click signal
	tile.tile_clicked.connect(_on_tile_clicked)

	return tile


func _grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * (tile_size.x + tile_spacing),
		grid_pos.y * (tile_size.y + tile_spacing)
	)


func _shuffle_tiles() -> void:
	# Use seeded RNG for deterministic shuffling
	var shuffle_count = MIN_SHUFFLES.get(difficulty, 50)

	print("[%s] Shuffling with %d moves (difficulty: %d)" % [puzzle_id, shuffle_count, difficulty])

	# Perform valid moves to ensure puzzle is solvable
	var last_move = Vector2i.ZERO
	for i in shuffle_count:
		var valid_moves = _get_valid_moves()

		# Avoid immediately undoing the last move
		if valid_moves.size() > 1 and last_move != Vector2i.ZERO:
			var reverse_move = empty_position + (empty_position - (empty_position + last_move))
			valid_moves.erase(-last_move)

		if valid_moves.is_empty():
			continue

		# Pick a random valid move using seeded RNG
		var move_index = get_seeded_randi_range(0, valid_moves.size() - 1)
		var move_dir = valid_moves[move_index]

		# Make the move (swap tile with empty)
		var tile_pos = empty_position + move_dir
		_swap_tiles_instant(tile_pos, empty_position)
		last_move = move_dir


func _get_valid_moves() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	for dir in directions:
		var new_pos = empty_position + dir
		if _is_valid_position(new_pos):
			moves.append(dir)

	return moves


func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size


func _swap_tiles_instant(pos1: Vector2i, pos2: Vector2i) -> void:
	var tile1 = grid[pos1.y][pos1.x]
	var tile2 = grid[pos2.y][pos2.x]

	# Swap in grid
	grid[pos1.y][pos1.x] = tile2
	grid[pos2.y][pos2.x] = tile1

	# Update tile positions
	tile1.set_grid_position(pos2)
	tile2.set_grid_position(pos1)

	# Update empty position
	if tile1.is_empty:
		empty_position = pos2
	elif tile2.is_empty:
		empty_position = pos1

	# Update visual positions instantly
	tile1.position = _grid_to_pixel(pos2)
	tile2.position = _grid_to_pixel(pos1)


func _on_tile_clicked(tile: PuzzleTile) -> void:
	if not is_active or is_solved or is_animating:
		return

	# Check if tile is adjacent to empty space
	var tile_pos = tile.grid_position
	var diff = tile_pos - empty_position

	if abs(diff.x) + abs(diff.y) != 1:
		# Not adjacent - invalid move
		tile.flash_invalid()
		return

	# Valid move - slide the tile
	_slide_tile(tile)


func _slide_tile(tile: PuzzleTile) -> void:
	is_animating = true
	move_count += 1
	_update_move_counter()

	var tile_pos = tile.grid_position
	var target_pos = empty_position

	# Get the empty tile
	var empty_tile = grid[empty_position.y][empty_position.x]

	# Swap in grid data
	grid[tile_pos.y][tile_pos.x] = empty_tile
	grid[target_pos.y][target_pos.x] = tile

	# Update grid positions
	empty_tile.set_grid_position(tile_pos)
	tile.set_grid_position(target_pos)

	# Update empty position tracking
	empty_position = tile_pos

	# Animate the tile sliding
	tile.slide_to(_grid_to_pixel(target_pos), _on_slide_animation_complete)

	# Move empty tile instantly (it's invisible anyway)
	empty_tile.position = _grid_to_pixel(tile_pos)

	# Visual feedback
	tile.flash_valid()


func _on_slide_animation_complete() -> void:
	is_animating = false
	_update_tile_visuals()

	# Check if puzzle is solved
	if _check_solution():
		solve_puzzle()


func _check_solution() -> bool:
	for tile in tiles:
		if not tile.is_in_correct_position:
			return false
	return true


func _update_tile_visuals() -> void:
	for tile in tiles:
		tile._update_correct_state()
		tile._update_visual_state()


func _update_move_counter() -> void:
	if move_counter_label:
		move_counter_label.text = "Moves: %d" % move_count


func _reset_puzzle() -> void:
	is_animating = false
	move_count = 0
	_setup_puzzle()


func _on_puzzle_started() -> void:
	# Could add start animation here
	pass


func _on_puzzle_solved() -> void:
	# Celebration animation
	for tile in tiles:
		if not tile.is_empty:
			tile.celebrate()

	print("[%s] Solved in %d moves!" % [puzzle_id, move_count])


func _on_puzzle_failed() -> void:
	# Could add failure animation here
	pass


## Get the current move count
func get_move_count() -> int:
	return move_count


## Check if the puzzle is in a solvable state (always true with our shuffle method)
func is_solvable() -> bool:
	# Our shuffle method only makes valid moves, so puzzle is always solvable
	return true


## Set custom grid size (must be called before _ready or use initialize)
func set_grid_size(new_size: int) -> void:
	grid_size = clampi(new_size, 2, 6)


## Set custom tile size
func set_tile_size(new_size: Vector2) -> void:
	tile_size = new_size
