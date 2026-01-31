extends BasePuzzle3D
class_name SlidingPuzzle3D
## SlidingPuzzle3D - 3D sliding tile puzzle implementation
## Players look at and click tiles to slide them into the correct positions

# Configuration
@export var grid_size: int = 3  # 3x3 default
@export var tile_size: float = 0.4  # Size of each cube tile
@export var tile_spacing: float = 0.05  # Gap between tiles
@export var tile_depth: float = 0.15  # Depth of the cube tiles

# Visual configuration
@export var board_material: StandardMaterial3D = null
@export var tile_material: StandardMaterial3D = null
@export_group("Tile Colors")
@export var tile_color_default: Color = Color(0.3, 0.4, 0.6)
@export var tile_color_correct: Color = Color(0.3, 0.6, 0.4)
@export var tile_color_wrong: Color = Color(0.5, 0.3, 0.3)

# Puzzle state
var tiles: Array[SlidingTile3D] = []
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

# Components
var board_mesh: MeshInstance3D = null
var tiles_container: Node3D = null

# Animation state
var is_animating: bool = false


func _ready() -> void:
	puzzle_id = "sliding_puzzle_3d_%d" % get_instance_id()
	super._ready()


func _setup_puzzle() -> void:
	_clear_existing_tiles()
	_create_board()
	_create_tiles()
	_shuffle_tiles()
	move_count = 0


func _clear_existing_tiles() -> void:
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()
	grid.clear()

	if tiles_container:
		tiles_container.queue_free()
		tiles_container = null


func _create_board() -> void:
	# Create board mesh if not exists
	if not board_mesh:
		board_mesh = MeshInstance3D.new()
		board_mesh.name = "BoardMesh"
		add_child(board_mesh)

	# Calculate board size
	var board_size = grid_size * tile_size + (grid_size + 1) * tile_spacing
	var board_thickness = 0.1

	# Create board mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(board_size, board_thickness, board_size)
	board_mesh.mesh = box_mesh

	# Position board slightly behind tiles
	board_mesh.position = Vector3(0, -board_thickness / 2 - tile_depth / 2, 0)

	# Create or use board material
	if not board_material:
		board_material = StandardMaterial3D.new()
		board_material.albedo_color = Color(0.15, 0.15, 0.2)
	board_mesh.set_surface_override_material(0, board_material)

	# Create tiles container
	tiles_container = Node3D.new()
	tiles_container.name = "TilesContainer"
	add_child(tiles_container)


func _create_tiles() -> void:
	# Initialize grid array
	grid.resize(grid_size)
	for i in grid_size:
		grid[i] = []
		grid[i].resize(grid_size)

	# Calculate offset to center the grid
	var total_size = grid_size * tile_size + (grid_size - 1) * tile_spacing
	var offset = -total_size / 2 + tile_size / 2

	# Create tiles
	var tile_index = 1
	for row in grid_size:
		for col in grid_size:
			var grid_pos = Vector2i(col, row)
			var tile = _create_tile(tile_index, grid_pos)
			tiles.append(tile)
			grid[row][col] = tile
			tiles_container.add_child(tile)

			# Position tile
			tile.position = _grid_to_world(grid_pos)

			# Last tile is empty
			if row == grid_size - 1 and col == grid_size - 1:
				tile.setup(0, grid_pos, grid_pos, true)
				empty_position = grid_pos
			else:
				var correct_pos = Vector2i((tile_index - 1) % grid_size, (tile_index - 1) / grid_size)
				tile.setup(tile_index, grid_pos, correct_pos, false)
				tile_index += 1


func _create_tile(value: int, grid_pos: Vector2i) -> SlidingTile3D:
	var tile = SlidingTile3D.new()
	tile.name = "Tile_%d" % value
	tile.tile_size = tile_size
	tile.tile_depth = tile_depth

	# Create material for tile
	var mat = StandardMaterial3D.new()
	mat.albedo_color = tile_color_default
	tile.tile_material = mat

	# Connect activation signal
	tile.element_activated.connect(_on_tile_activated)

	return tile


func _grid_to_world(grid_pos: Vector2i) -> Vector3:
	var total_size = grid_size * tile_size + (grid_size - 1) * tile_spacing
	var offset = -total_size / 2 + tile_size / 2

	return Vector3(
		offset + grid_pos.x * (tile_size + tile_spacing),
		0,
		offset + grid_pos.y * (tile_size + tile_spacing)
	)


func _shuffle_tiles() -> void:
	var shuffle_count = MIN_SHUFFLES.get(difficulty, 50)

	print("[%s] Shuffling with %d moves (difficulty: %d)" % [puzzle_id, shuffle_count, difficulty])

	var last_move = Vector2i.ZERO
	for i in shuffle_count:
		var valid_moves = _get_valid_moves()

		# Avoid immediately undoing the last move
		if valid_moves.size() > 1 and last_move != Vector2i.ZERO:
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
	if tile1.is_empty_tile:
		empty_position = pos2
	elif tile2.is_empty_tile:
		empty_position = pos1

	# Update visual positions instantly
	tile1.position = _grid_to_world(pos2)
	tile2.position = _grid_to_world(pos1)


func _on_tile_activated(element: PuzzleElement3D) -> void:
	if not is_active or is_solved or is_animating:
		return

	var tile = element as SlidingTile3D
	if not tile or tile.is_empty_tile:
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


func _slide_tile(tile: SlidingTile3D) -> void:
	is_animating = true
	move_count += 1

	var tile_pos = tile.grid_position
	var target_pos = empty_position

	# Get the empty tile
	var empty_tile = grid[empty_position.y][empty_position.x] as SlidingTile3D

	# Swap in grid data
	grid[tile_pos.y][tile_pos.x] = empty_tile
	grid[target_pos.y][target_pos.x] = tile

	# Update grid positions
	empty_tile.set_grid_position(tile_pos)
	tile.set_grid_position(target_pos)

	# Update empty position tracking
	empty_position = tile_pos

	# Animate the tile sliding
	tile.slide_to(_grid_to_world(target_pos), _on_slide_animation_complete)

	# Move empty tile instantly (it's invisible anyway)
	empty_tile.position = _grid_to_world(tile_pos)

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


func _reset_puzzle() -> void:
	is_animating = false
	move_count = 0
	_setup_puzzle()


func _on_puzzle_started() -> void:
	pass


func _on_puzzle_solved() -> void:
	# Celebration animation
	for tile in tiles:
		if not tile.is_empty_tile:
			tile.celebrate()

	print("[%s] Solved in %d moves!" % [puzzle_id, move_count])


func _on_puzzle_failed() -> void:
	pass


## Get the current move count
func get_move_count() -> int:
	return move_count


## Set custom grid size (must be called before _ready or use initialize)
func set_grid_size(new_size: int) -> void:
	grid_size = clampi(new_size, 2, 6)


## Set custom tile size
func set_tile_size(new_size: float) -> void:
	tile_size = new_size


# Inner class for 3D sliding tiles
class SlidingTile3D extends PuzzleElement3D:
	## SlidingTile3D - Individual 3D tile for sliding puzzle

	signal slide_completed(tile: SlidingTile3D)

	# Tile configuration
	var tile_size: float = 0.4
	var tile_depth: float = 0.15
	var tile_material: StandardMaterial3D = null

	# Tile data
	var tile_value: int = 0
	var grid_position: Vector2i = Vector2i.ZERO
	var correct_position: Vector2i = Vector2i.ZERO
	var is_empty_tile: bool = false
	var is_in_correct_position: bool = false

	# Animation
	var slide_tween: Tween = null
	const SLIDE_DURATION: float = 0.15

	# Visual components
	var label_3d: Label3D = null

	# Colors
	var color_default: Color = Color(0.3, 0.4, 0.6)
	var color_correct: Color = Color(0.3, 0.6, 0.4)


	func _ready() -> void:
		super._ready()
		_create_visuals()


	func _create_visuals() -> void:
		# Create cube mesh for tile
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(tile_size * 0.95, tile_depth, tile_size * 0.95)

		if not mesh_instance:
			mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "TileMesh"
			add_child(mesh_instance)

		mesh_instance.mesh = box_mesh

		# Apply material
		if tile_material:
			mesh_instance.set_surface_override_material(0, tile_material)
		_setup_materials()

		# Create collision shape
		if not collision_shape:
			collision_shape = CollisionShape3D.new()
			collision_shape.name = "TileCollision"
			add_child(collision_shape)

		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(tile_size * 0.95, tile_depth, tile_size * 0.95)
		collision_shape.shape = box_shape

		# Create 3D label for tile number
		if not label_3d:
			label_3d = Label3D.new()
			label_3d.name = "TileLabel"
			add_child(label_3d)

		label_3d.position = Vector3(0, tile_depth / 2 + 0.01, 0)
		label_3d.rotation_degrees = Vector3(-90, 0, 0)
		label_3d.pixel_size = 0.005
		label_3d.font_size = 48
		label_3d.outline_size = 4
		label_3d.modulate = Color.WHITE
		label_3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED

		_update_visual_state()


	func setup(value: int, grid_pos: Vector2i, correct_pos: Vector2i, empty: bool) -> void:
		tile_value = value
		grid_position = grid_pos
		correct_position = correct_pos
		is_empty_tile = empty
		element_value = value

		_update_correct_state()
		_update_visual_state()


	func set_grid_position(new_pos: Vector2i) -> void:
		grid_position = new_pos
		_update_correct_state()


	func _update_correct_state() -> void:
		is_in_correct_position = (grid_position == correct_position)


	func _update_visual_state() -> void:
		if not is_inside_tree():
			return

		# Update label
		if label_3d:
			if is_empty_tile:
				label_3d.text = ""
			else:
				label_3d.text = str(tile_value)

		# Update color based on state
		if _original_material and _original_material is StandardMaterial3D:
			var mat = _original_material as StandardMaterial3D
			if is_empty_tile:
				mat.albedo_color = Color(0.1, 0.1, 0.1, 0.0)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			elif is_in_correct_position:
				mat.albedo_color = color_correct
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			else:
				mat.albedo_color = color_default
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

		# Update visibility
		visible = not is_empty_tile

		# Update interactability
		is_interactable = not is_empty_tile


	func slide_to(target_position: Vector3, on_complete: Callable = Callable()) -> void:
		if is_animating:
			return

		is_animating = true

		# Cancel any existing tween
		if slide_tween and slide_tween.is_valid():
			slide_tween.kill()

		# Create new tween for smooth animation
		slide_tween = create_tween()
		slide_tween.set_ease(Tween.EASE_OUT)
		slide_tween.set_trans(Tween.TRANS_QUAD)

		slide_tween.tween_property(self, "position", target_position, SLIDE_DURATION)
		slide_tween.tween_callback(_on_slide_complete.bind(on_complete))


	func _on_slide_complete(callback: Callable) -> void:
		is_animating = false
		slide_completed.emit(self)

		if callback.is_valid():
			callback.call()
