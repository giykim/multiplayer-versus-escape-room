extends Node3D
class_name SymbolMatchPuzzle3D
## SymbolMatchPuzzle3D - Memory matching game with symbols
## Flip cards to find matching pairs

signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_started()

@export var puzzle_id: String = "symbol_puzzle"
@export var difficulty: int = 1  # Affects number of pairs

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0
var presses_needed: int = 4
var is_checking: bool = false  # Prevent interaction during check

# Card configuration
var card_count: int = 8  # Always even
var cards: Array[Dictionary] = []  # [{symbol, flipped, matched}]
var card_meshes: Array[MeshInstance3D] = []
var card_areas: Array[Area3D] = []
var first_flipped: int = -1
var second_flipped: int = -1
var matches_found: int = 0

# Symbols (simple shapes represented by colors and patterns)
const SYMBOLS: Array[Dictionary] = [
	{"name": "Circle", "color": Color(0.9, 0.2, 0.2), "shape": "circle"},
	{"name": "Square", "color": Color(0.2, 0.6, 0.9), "shape": "square"},
	{"name": "Triangle", "color": Color(0.2, 0.9, 0.3), "shape": "triangle"},
	{"name": "Star", "color": Color(0.9, 0.9, 0.2), "shape": "star"},
	{"name": "Diamond", "color": Color(0.9, 0.4, 0.9), "shape": "diamond"},
	{"name": "Heart", "color": Color(0.9, 0.3, 0.5), "shape": "heart"},
	{"name": "Cross", "color": Color(0.9, 0.6, 0.2), "shape": "cross"},
	{"name": "Moon", "color": Color(0.5, 0.5, 0.9), "shape": "moon"},
]

const CARD_BACK_COLOR = Color(0.2, 0.25, 0.35)
const CARD_MATCHED_COLOR = Color(0.2, 0.5, 0.3)

# Node references
var panel_mesh: MeshInstance3D
var status_label: Label3D
var progress_label: Label3D


func _ready() -> void:
	_create_panel()
	_create_labels()

	add_to_group("interactable")
	add_to_group("puzzle")

	print("[SymbolMatchPuzzle3D] Ready - difficulty %d" % difficulty)


func _create_panel() -> void:
	panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"

	var box = BoxMesh.new()
	box.size = Vector3(3.0, 2.5, 0.1)
	panel_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.12, 0.18)
	material.emission_enabled = true
	material.emission = Color(0.12, 0.12, 0.18) * 0.2
	panel_mesh.material_override = material

	add_child(panel_mesh)


func _create_labels() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "Find Matching Pairs!"
	status_label.font_size = 36
	status_label.pixel_size = 0.008
	status_label.position = Vector3(0, 1.05, 0.12)
	status_label.modulate = Color.WHITE
	status_label.outline_size = 12
	status_label.outline_modulate = Color.BLACK
	add_child(status_label)

	progress_label = Label3D.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = ""
	progress_label.font_size = 28
	progress_label.pixel_size = 0.008
	progress_label.position = Vector3(0, -1.05, 0.12)
	progress_label.modulate = Color.WHITE
	progress_label.outline_size = 8
	progress_label.outline_modulate = Color.BLACK
	add_child(progress_label)


func initialize(seed_value: int, puzzle_difficulty: int) -> void:
	difficulty = puzzle_difficulty

	# Card count based on difficulty (4-12 pairs = 8-24 cards)
	var pair_count = 2 + difficulty * 2
	pair_count = mini(pair_count, SYMBOLS.size())
	card_count = pair_count * 2
	presses_needed = pair_count

	_generate_cards(seed_value)
	_create_card_visuals()
	_update_progress()

	print("[SymbolMatchPuzzle3D] Initialized: %d pairs (%d cards)" % [pair_count, card_count])


func _generate_cards(seed_value: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value + puzzle_id.hash()

	var pair_count = card_count / 2
	cards.clear()

	# Create pairs
	for i in range(pair_count):
		var symbol = SYMBOLS[i % SYMBOLS.size()]
		# Add two cards with same symbol
		cards.append({"symbol": symbol, "flipped": false, "matched": false})
		cards.append({"symbol": symbol, "flipped": false, "matched": false})

	# Shuffle cards
	for i in range(cards.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = cards[i]
		cards[i] = cards[j]
		cards[j] = temp


func _create_card_visuals() -> void:
	# Clear existing
	for mesh in card_meshes:
		mesh.queue_free()
	for area in card_areas:
		area.queue_free()

	card_meshes.clear()
	card_areas.clear()

	# Calculate grid layout
	var cols = ceili(sqrt(float(card_count)))
	var rows = ceili(float(card_count) / float(cols))

	var card_width = 2.4 / float(cols)
	var card_height = 1.8 / float(rows)
	var card_size = minf(card_width, card_height) * 0.85

	var start_x = -(cols - 1) * card_width / 2.0
	var start_y = (rows - 1) * card_height / 2.0

	for i in range(cards.size()):
		var row = i / cols
		var col = i % cols

		var x = start_x + col * card_width
		var y = start_y - row * card_height
		var pos = Vector3(x, y, 0.08)

		var card = _create_card_mesh(pos, card_size, i)
		card_meshes.append(card)

		var area = _create_card_area(pos, card_size, i)
		card_areas.append(area)


func _create_card_mesh(pos: Vector3, size: float, index: int) -> MeshInstance3D:
	var card = MeshInstance3D.new()
	card.name = "Card_%d" % index

	var box = BoxMesh.new()
	box.size = Vector3(size, size * 1.2, 0.05)
	card.mesh = box
	card.position = pos

	_set_card_appearance(card, index, false)

	add_child(card)
	return card


func _create_card_area(pos: Vector3, size: float, index: int) -> Area3D:
	var area = Area3D.new()
	area.name = "CardArea_%d" % index
	area.collision_layer = 32
	area.collision_mask = 0
	area.set_meta("puzzle_parent", self)
	area.set_meta("card_index", index)
	area.add_to_group("interactable")

	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(size, size * 1.2, 0.2)
	shape.shape = box_shape
	shape.position = pos

	area.add_child(shape)
	add_child(area)

	return area


func _set_card_appearance(card: MeshInstance3D, index: int, show_symbol: bool) -> void:
	var card_data = cards[index]

	# Remove old symbol mesh if exists
	var old_symbol = card.get_node_or_null("Symbol")
	if old_symbol:
		old_symbol.queue_free()

	var mat = StandardMaterial3D.new()

	if card_data.matched:
		mat.albedo_color = CARD_MATCHED_COLOR
		mat.emission_enabled = true
		mat.emission = CARD_MATCHED_COLOR * 0.5
		mat.emission_energy_multiplier = 0.3
	elif show_symbol:
		mat.albedo_color = card_data.symbol.color
		mat.emission_enabled = true
		mat.emission = card_data.symbol.color * 0.5
		mat.emission_energy_multiplier = 0.5

		# Add symbol label
		var symbol_label = Label3D.new()
		symbol_label.name = "Symbol"
		symbol_label.text = _get_symbol_char(card_data.symbol.shape)
		symbol_label.font_size = 48
		symbol_label.pixel_size = 0.008
		symbol_label.position = Vector3(0, 0, 0.04)
		symbol_label.modulate = Color.WHITE
		symbol_label.outline_size = 4
		symbol_label.outline_modulate = Color.BLACK
		card.add_child(symbol_label)
	else:
		mat.albedo_color = CARD_BACK_COLOR
		mat.emission_enabled = true
		mat.emission = CARD_BACK_COLOR * 0.3
		mat.emission_energy_multiplier = 0.2

	card.material_override = mat


func _get_symbol_char(shape: String) -> String:
	match shape:
		"circle": return "O"
		"square": return "#"
		"triangle": return "^"
		"star": return "*"
		"diamond": return "<>"
		"heart": return "<3"
		"cross": return "+"
		"moon": return ")"
	return "?"


func start_puzzle() -> void:
	if is_active or is_solved:
		return

	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	matches_found = 0
	first_flipped = -1
	second_flipped = -1

	puzzle_started.emit()
	status_label.text = "Flip cards to match"
	_update_progress()

	print("[SymbolMatchPuzzle3D] Puzzle started!")


func interact(player: Node3D) -> void:
	if is_solved or is_checking:
		return

	if not is_active:
		start_puzzle()
		return

	var card_index = _get_aimed_card(player)
	if card_index < 0:
		return

	_on_card_clicked(card_index)


func _get_aimed_card(player: Node3D) -> int:
	var ray = player.get_node_or_null("Head/InteractionRay")
	if ray and ray is RayCast3D and ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.has_meta("card_index"):
			return collider.get_meta("card_index")
	return -1


func _on_card_clicked(card_index: int) -> void:
	var card_data = cards[card_index]

	# Skip if already matched or flipped
	if card_data.matched or card_data.flipped:
		return

	# Flip the card
	card_data.flipped = true
	_animate_flip(card_index, true)

	if first_flipped < 0:
		# First card
		first_flipped = card_index
	else:
		# Second card
		second_flipped = card_index
		is_checking = true

		# Check for match after a delay
		await get_tree().create_timer(0.8).timeout

		_check_match()


func _animate_flip(card_index: int, show_symbol: bool) -> void:
	var mesh = card_meshes[card_index]
	if not mesh:
		return

	# Simple scale animation to simulate flip
	var tween = create_tween()
	tween.tween_property(mesh, "scale:x", 0.0, 0.1)
	tween.tween_callback(_set_card_appearance.bind(mesh, card_index, show_symbol))
	tween.tween_property(mesh, "scale:x", 1.0, 0.1)


func _check_match() -> void:
	if first_flipped < 0 or second_flipped < 0:
		is_checking = false
		return

	var first_data = cards[first_flipped]
	var second_data = cards[second_flipped]

	if first_data.symbol.name == second_data.symbol.name:
		# Match found!
		first_data.matched = true
		second_data.matched = true
		matches_found += 1

		_set_card_appearance(card_meshes[first_flipped], first_flipped, true)
		_set_card_appearance(card_meshes[second_flipped], second_flipped, true)

		print("[SymbolMatchPuzzle3D] Match found! %d/%d" % [matches_found, card_count / 2])

		if matches_found >= card_count / 2:
			_on_puzzle_complete()
	else:
		# No match - flip back
		first_data.flipped = false
		second_data.flipped = false
		_animate_flip(first_flipped, false)
		_animate_flip(second_flipped, false)

	first_flipped = -1
	second_flipped = -1
	is_checking = false
	_update_progress()


func _update_progress() -> void:
	if progress_label:
		progress_label.text = "Matches: %d / %d" % [matches_found, card_count / 2]


func _on_puzzle_complete() -> void:
	is_solved = true
	is_active = false

	var time_taken = (Time.get_ticks_msec() / 1000.0) - start_time

	status_label.text = "ALL MATCHED!"
	status_label.modulate = Color(0.3, 1.0, 0.3)

	print("[SymbolMatchPuzzle3D] Puzzle solved in %.2fs!" % time_taken)
	puzzle_solved.emit(puzzle_id, time_taken)


func on_interact(player: Node3D) -> void:
	interact(player)


func force_complete() -> void:
	if not is_solved:
		_on_puzzle_complete()
