extends Node3D
class_name SlidingTilePuzzle3D
## SlidingTilePuzzle3D - Slide numbered tiles to put them in order
## Classic 15-puzzle style: one empty space, slide tiles to solve

signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_started()

@export var puzzle_id: String = "sliding_puzzle"
@export var difficulty: int = 1  # 1=3x3, 2=4x4, 3+=5x5

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0
var presses_needed: int = 9
var move_count: int = 0

# Grid configuration
var grid_size: int = 3
var tiles: Array[int] = []  # Current tile positions (0 = empty)
var tile_meshes: Array[MeshInstance3D] = []
var tile_areas: Array[Area3D] = []
var empty_pos: int = 0  # Index of empty tile

# Node references
var panel_mesh: MeshInstance3D
var status_label: Label3D
var progress_label: Label3D

const TILE_COLOR = Color(0.3, 0.5, 0.7)
const TILE_HOVER = Color(0.4, 0.6, 0.8)
const TILE_CORRECT = Color(0.3, 0.7, 0.4)


func _ready() -> void:
	_create_panel()
	_create_labels()

	add_to_group("interactable")
	add_to_group("puzzle")

	print("[SlidingTilePuzzle3D] Ready - difficulty %d" % difficulty)


func _create_panel() -> void:
	panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"

	var box = BoxMesh.new()
	box.size = Vector3(2.5, 2.5, 0.1)
	panel_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.15, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.15, 0.15, 0.2) * 0.2
	panel_mesh.material_override = material

	add_child(panel_mesh)


func _create_labels() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "Slide Tiles in Order!"
	status_label.font_size = 36
	status_label.pixel_size = 0.008
	status_label.position = Vector3(0, 1.1, 0.12)
	status_label.modulate = Color.WHITE
	status_label.outline_size = 12
	status_label.outline_modulate = Color.BLACK
	add_child(status_label)

	progress_label = Label3D.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = ""
	progress_label.font_size = 28
	progress_label.pixel_size = 0.008
	progress_label.position = Vector3(0, -1.1, 0.12)
	progress_label.modulate = Color.WHITE
	progress_label.outline_size = 8
	progress_label.outline_modulate = Color.BLACK
	add_child(progress_label)


func initialize(seed_value: int, puzzle_difficulty: int) -> void:
	difficulty = puzzle_difficulty

	# Grid size based on difficulty
	if difficulty <= 1:
		grid_size = 3  # 8-puzzle
	elif difficulty == 2:
		grid_size = 3  # Still 3x3 but more shuffles
	else:
		grid_size = 4  # 15-puzzle

	presses_needed = grid_size * grid_size - 1
	_generate_puzzle(seed_value)
	_create_tiles()
	_update_progress()

	print("[SlidingTilePuzzle3D] Initialized: %dx%d grid" % [grid_size, grid_size])


func _generate_puzzle(seed_value: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value + puzzle_id.hash()

	var total_tiles = grid_size * grid_size

	# Start with solved state
	tiles.clear()
	for i in range(total_tiles - 1):
		tiles.append(i + 1)  # 1 to N-1
	tiles.append(0)  # Empty at the end
	empty_pos = total_tiles - 1

	# Shuffle by making valid moves (ensures solvability)
	var shuffle_count = 10 + difficulty * 20
	for i in range(shuffle_count):
		var valid_moves = _get_valid_moves()
		if valid_moves.size() > 0:
			var move_pos = valid_moves[rng.randi() % valid_moves.size()]
			_swap_tiles(move_pos, empty_pos)
			empty_pos = move_pos


func _get_valid_moves() -> Array[int]:
	var moves: Array[int] = []
	var row = empty_pos / grid_size
	var col = empty_pos % grid_size

	# Up
	if row > 0:
		moves.append(empty_pos - grid_size)
	# Down
	if row < grid_size - 1:
		moves.append(empty_pos + grid_size)
	# Left
	if col > 0:
		moves.append(empty_pos - 1)
	# Right
	if col < grid_size - 1:
		moves.append(empty_pos + 1)

	return moves


func _swap_tiles(pos1: int, pos2: int) -> void:
	var temp = tiles[pos1]
	tiles[pos1] = tiles[pos2]
	tiles[pos2] = temp


func _create_tiles() -> void:
	# Clear existing
	for mesh in tile_meshes:
		mesh.queue_free()
	for area in tile_areas:
		area.queue_free()

	tile_meshes.clear()
	tile_areas.clear()

	var tile_size = 2.0 / float(grid_size)
	var offset = (grid_size - 1) * tile_size / 2.0

	for i in range(tiles.size()):
		var row = i / grid_size
		var col = i % grid_size

		var x = col * tile_size - offset
		var y = offset - row * tile_size  # Flip Y for visual
		var pos = Vector3(x, y, 0.08)

		if tiles[i] == 0:
			# Empty space - just create invisible area
			var area = _create_tile_area(pos, tile_size, i)
			tile_areas.append(area)
			tile_meshes.append(null)
		else:
			var tile = _create_tile_mesh(pos, tile_size, tiles[i], i)
			tile_meshes.append(tile)

			var area = _create_tile_area(pos, tile_size, i)
			tile_areas.append(area)


func _create_tile_mesh(pos: Vector3, size: float, number: int, index: int) -> MeshInstance3D:
	var tile = MeshInstance3D.new()
	tile.name = "Tile_%d" % number

	var box = BoxMesh.new()
	box.size = Vector3(size * 0.9, size * 0.9, 0.08)
	tile.mesh = box
	tile.position = pos

	var is_correct = (tiles[index] == index + 1)
	_set_tile_color(tile, TILE_CORRECT if is_correct else TILE_COLOR)

	add_child(tile)

	# Add number label
	var label = Label3D.new()
	label.text = str(number)
	label.font_size = int(120 / grid_size)
	label.pixel_size = 0.008
	label.position = Vector3(0, 0, 0.05)
	label.modulate = Color.WHITE
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	tile.add_child(label)

	return tile


func _create_tile_area(pos: Vector3, size: float, index: int) -> Area3D:
	var area = Area3D.new()
	area.name = "TileArea_%d" % index
	area.collision_layer = 32
	area.collision_mask = 0
	area.set_meta("puzzle_parent", self)
	area.set_meta("tile_index", index)
	area.add_to_group("interactable")

	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(size * 0.9, size * 0.9, 0.2)
	shape.shape = box_shape
	shape.position = pos

	area.add_child(shape)
	add_child(area)

	return area


func _set_tile_color(tile: MeshInstance3D, color: Color) -> void:
	if not tile:
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.3
	mat.emission_energy_multiplier = 0.5
	tile.material_override = mat


func start_puzzle() -> void:
	if is_active or is_solved:
		return

	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	move_count = 0

	puzzle_started.emit()
	status_label.text = "Click tiles to slide"
	_update_progress()

	print("[SlidingTilePuzzle3D] Puzzle started!")


func interact(player: Node3D) -> void:
	if is_solved:
		return

	if not is_active:
		start_puzzle()
		return

	# Find which tile was clicked
	var tile_index = _get_aimed_tile(player)
	if tile_index < 0:
		return

	_on_tile_clicked(tile_index)


func _get_aimed_tile(player: Node3D) -> int:
	var ray = player.get_node_or_null("Head/InteractionRay")
	if ray and ray is RayCast3D and ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.has_meta("tile_index"):
			return collider.get_meta("tile_index")
	return -1


func _on_tile_clicked(tile_index: int) -> void:
	if tiles[tile_index] == 0:
		return  # Clicked empty space

	# Check if adjacent to empty
	var valid_moves = _get_valid_moves()
	if not valid_moves.has(tile_index):
		return  # Not adjacent to empty

	# Move tile
	_animate_tile_move(tile_index, empty_pos)
	_swap_tiles(tile_index, empty_pos)
	empty_pos = tile_index
	move_count += 1

	_update_tile_colors()
	_update_progress()

	# Check if solved
	if _check_solved():
		_on_puzzle_complete()


func _animate_tile_move(from_index: int, to_index: int) -> void:
	# Find the mesh at from_index
	var mesh = tile_meshes[from_index]
	if not mesh:
		return

	# Calculate new position
	var tile_size = 2.0 / float(grid_size)
	var offset = (grid_size - 1) * tile_size / 2.0
	var to_row = to_index / grid_size
	var to_col = to_index % grid_size
	var new_x = to_col * tile_size - offset
	var new_y = offset - to_row * tile_size
	var new_pos = Vector3(new_x, new_y, 0.08)

	# Animate
	var tween = create_tween()
	tween.tween_property(mesh, "position", new_pos, 0.15)

	# Update mesh array
	tile_meshes[to_index] = mesh
	tile_meshes[from_index] = null

	# Update area metadata
	if tile_areas[from_index]:
		tile_areas[from_index].set_meta("tile_index", from_index)
	if tile_areas[to_index]:
		tile_areas[to_index].set_meta("tile_index", to_index)


func _update_tile_colors() -> void:
	for i in range(tiles.size()):
		if tiles[i] == 0:
			continue
		var mesh = tile_meshes[i]
		if mesh:
			var is_correct = (tiles[i] == i + 1)
			_set_tile_color(mesh, TILE_CORRECT if is_correct else TILE_COLOR)


func _check_solved() -> bool:
	for i in range(tiles.size() - 1):
		if tiles[i] != i + 1:
			return false
	return tiles[tiles.size() - 1] == 0


func _update_progress() -> void:
	if progress_label:
		var correct = 0
		for i in range(tiles.size() - 1):
			if tiles[i] == i + 1:
				correct += 1
		progress_label.text = "Correct: %d/%d  Moves: %d" % [correct, tiles.size() - 1, move_count]


func _on_puzzle_complete() -> void:
	is_solved = true
	is_active = false

	var time_taken = (Time.get_ticks_msec() / 1000.0) - start_time

	status_label.text = "SOLVED!"
	status_label.modulate = Color(0.3, 1.0, 0.3)

	print("[SlidingTilePuzzle3D] Puzzle solved in %.2fs with %d moves!" % [time_taken, move_count])
	puzzle_solved.emit(puzzle_id, time_taken)


func on_interact(player: Node3D) -> void:
	interact(player)


func force_complete() -> void:
	if not is_solved:
		_on_puzzle_complete()
