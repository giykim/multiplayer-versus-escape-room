extends Node3D
class_name WireConnectPuzzle3D
## WireConnectPuzzle3D - Connect matching colored wire endpoints
## Player must select pairs of matching colored endpoints to connect them

signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_started()

@export var puzzle_id: String = "wire_puzzle"
@export var difficulty: int = 1  # Affects number of wire pairs

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0
var presses_needed: int = 3

# Wire configuration
var wire_pairs: Array[Dictionary] = []  # [{color, left_index, right_index, connected}]
var selected_endpoint: Dictionary = {}  # {side: "left"/"right", index: int}
var connections_made: int = 0

# Node references
var panel_mesh: MeshInstance3D
var left_endpoints: Array[MeshInstance3D] = []
var right_endpoints: Array[MeshInstance3D] = []
var endpoint_areas: Array[Area3D] = []
var connection_lines: Array[MeshInstance3D] = []
var status_label: Label3D
var progress_label: Label3D

# Wire colors
const WIRE_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.6, 0.9),   # Blue
	Color(0.2, 0.9, 0.3),   # Green
	Color(0.9, 0.9, 0.2),   # Yellow
	Color(0.9, 0.4, 0.9),   # Purple
	Color(0.9, 0.6, 0.2),   # Orange
]
const COLOR_OFF = Color(0.3, 0.3, 0.3)
const COLOR_SELECTED = Color(1.0, 1.0, 1.0)


func _ready() -> void:
	_create_panel()
	_create_labels()

	add_to_group("interactable")
	add_to_group("puzzle")

	print("[WireConnectPuzzle3D] Ready - difficulty %d" % difficulty)


func _create_panel() -> void:
	panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"

	var box = BoxMesh.new()
	box.size = Vector3(2.5, 2.0, 0.1)
	panel_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.15, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.15, 0.2) * 0.2
	material.emission_energy_multiplier = 0.3
	panel_mesh.material_override = material

	add_child(panel_mesh)


func _create_labels() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "Connect the Wires!"
	status_label.font_size = 40
	status_label.pixel_size = 0.008
	status_label.position = Vector3(0, 0.85, 0.12)
	status_label.modulate = Color.WHITE
	status_label.outline_size = 12
	status_label.outline_modulate = Color.BLACK
	add_child(status_label)

	progress_label = Label3D.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = ""
	progress_label.font_size = 32
	progress_label.pixel_size = 0.008
	progress_label.position = Vector3(0, -0.85, 0.12)
	progress_label.modulate = Color.WHITE
	progress_label.outline_size = 8
	progress_label.outline_modulate = Color.BLACK
	add_child(progress_label)


func initialize(seed_value: int, puzzle_difficulty: int) -> void:
	difficulty = puzzle_difficulty
	_generate_wire_pairs(seed_value)
	_create_endpoints()
	presses_needed = wire_pairs.size()
	_update_progress()
	print("[WireConnectPuzzle3D] Initialized: %d wire pairs" % wire_pairs.size())


func _generate_wire_pairs(seed_value: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value + puzzle_id.hash()

	# Number of pairs based on difficulty (2-5)
	var pair_count = 1 + difficulty
	pair_count = mini(pair_count, WIRE_COLORS.size())

	wire_pairs.clear()

	# Create pairs with shuffled positions on each side
	var left_positions: Array[int] = []
	var right_positions: Array[int] = []
	for i in range(pair_count):
		left_positions.append(i)
		right_positions.append(i)

	# Shuffle right positions
	for i in range(right_positions.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = right_positions[i]
		right_positions[i] = right_positions[j]
		right_positions[j] = temp

	# Create wire pair data
	for i in range(pair_count):
		wire_pairs.append({
			"color": WIRE_COLORS[i],
			"left_index": left_positions[i],
			"right_index": right_positions[i],
			"connected": false
		})


func _create_endpoints() -> void:
	# Clear existing
	for ep in left_endpoints:
		ep.queue_free()
	for ep in right_endpoints:
		ep.queue_free()
	for area in endpoint_areas:
		area.queue_free()

	left_endpoints.clear()
	right_endpoints.clear()
	endpoint_areas.clear()

	var pair_count = wire_pairs.size()
	var spacing = 1.4 / float(pair_count)
	var start_y = (pair_count - 1) * spacing / 2.0

	for pair in wire_pairs:
		var color = pair.color

		# Left endpoint
		var left_y = start_y - pair.left_index * spacing
		var left_ep = _create_endpoint(Vector3(-0.9, left_y, 0.08), color, "left", pair.left_index)
		left_endpoints.append(left_ep)

		# Right endpoint
		var right_y = start_y - pair.right_index * spacing
		var right_ep = _create_endpoint(Vector3(0.9, right_y, 0.08), color, "right", pair.right_index)
		right_endpoints.append(right_ep)


func _create_endpoint(pos: Vector3, color: Color, side: String, index: int) -> MeshInstance3D:
	var endpoint = MeshInstance3D.new()
	endpoint.name = "%s_endpoint_%d" % [side, index]

	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	endpoint.mesh = sphere
	endpoint.position = pos

	_set_endpoint_color(endpoint, color)

	add_child(endpoint)

	# Create interaction area
	var area = Area3D.new()
	area.name = "%s_area_%d" % [side, index]
	area.collision_layer = 32
	area.collision_mask = 0
	area.set_meta("puzzle_parent", self)
	area.set_meta("side", side)
	area.set_meta("index", index)
	area.add_to_group("interactable")

	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.15
	shape.shape = sphere_shape
	shape.position = pos

	area.add_child(shape)
	add_child(area)
	endpoint_areas.append(area)

	return endpoint


func _set_endpoint_color(endpoint: MeshInstance3D, color: Color) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.0
	endpoint.material_override = mat


func start_puzzle() -> void:
	if is_active or is_solved:
		return

	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	connections_made = 0
	selected_endpoint = {}

	puzzle_started.emit()
	status_label.text = "Select matching endpoints"
	_update_progress()

	print("[WireConnectPuzzle3D] Puzzle started!")


func interact(player: Node3D) -> void:
	if is_solved:
		return

	if not is_active:
		start_puzzle()
		return

	# Find which endpoint was selected
	var endpoint_info = _get_aimed_endpoint(player)
	if endpoint_info.is_empty():
		return

	_on_endpoint_selected(endpoint_info.side, endpoint_info.index)


func _get_aimed_endpoint(player: Node3D) -> Dictionary:
	var ray = player.get_node_or_null("Head/InteractionRay")
	if ray and ray is RayCast3D and ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.has_meta("side"):
			return {
				"side": collider.get_meta("side"),
				"index": collider.get_meta("index")
			}
	return {}


func _on_endpoint_selected(side: String, index: int) -> void:
	# Find which wire pair this belongs to
	var pair_index = -1
	for i in range(wire_pairs.size()):
		var pair = wire_pairs[i]
		if side == "left" and pair.left_index == index:
			pair_index = i
			break
		elif side == "right" and pair.right_index == index:
			pair_index = i
			break

	if pair_index < 0:
		return

	var pair = wire_pairs[pair_index]
	if pair.connected:
		return  # Already connected

	if selected_endpoint.is_empty():
		# First selection
		selected_endpoint = {"side": side, "index": index, "pair_index": pair_index}
		_highlight_endpoint(side, index, true)
		status_label.text = "Select matching color"
	else:
		# Second selection
		if selected_endpoint.side == side:
			# Same side - deselect
			_highlight_endpoint(selected_endpoint.side, selected_endpoint.index, false)
			selected_endpoint = {}
			status_label.text = "Select matching endpoints"
		elif selected_endpoint.pair_index == pair_index:
			# Correct match!
			_highlight_endpoint(selected_endpoint.side, selected_endpoint.index, false)
			pair.connected = true
			connections_made += 1
			_draw_connection_line(pair_index)
			_update_progress()
			selected_endpoint = {}

			print("[WireConnectPuzzle3D] Correct connection! %d/%d" % [connections_made, wire_pairs.size()])

			if connections_made >= wire_pairs.size():
				_on_puzzle_complete()
			else:
				status_label.text = "Good! Keep connecting"
		else:
			# Wrong match
			_highlight_endpoint(selected_endpoint.side, selected_endpoint.index, false)
			selected_endpoint = {}
			status_label.text = "Wrong! Try again"
			print("[WireConnectPuzzle3D] Wrong match")


func _highlight_endpoint(side: String, index: int, highlight: bool) -> void:
	var endpoints = left_endpoints if side == "left" else right_endpoints

	for i in range(wire_pairs.size()):
		var pair = wire_pairs[i]
		var ep_index = pair.left_index if side == "left" else pair.right_index
		if ep_index == index:
			var color = COLOR_SELECTED if highlight else pair.color
			_set_endpoint_color(endpoints[i], color)
			break


func _draw_connection_line(pair_index: int) -> void:
	var pair = wire_pairs[pair_index]
	var pair_count = wire_pairs.size()
	var spacing = 1.4 / float(pair_count)
	var start_y = (pair_count - 1) * spacing / 2.0

	var left_y = start_y - pair.left_index * spacing
	var right_y = start_y - pair.right_index * spacing

	# Create line mesh
	var line = MeshInstance3D.new()
	var box = BoxMesh.new()

	var mid_y = (left_y + right_y) / 2.0
	var length = 1.8  # Horizontal distance

	box.size = Vector3(length, 0.03, 0.03)
	line.mesh = box
	line.position = Vector3(0, mid_y, 0.06)

	# Rotate to connect endpoints
	var angle = atan2(right_y - left_y, length)
	line.rotation.z = angle

	var mat = StandardMaterial3D.new()
	mat.albedo_color = pair.color
	mat.emission_enabled = true
	mat.emission = pair.color
	mat.emission_energy_multiplier = 0.8
	line.material_override = mat

	add_child(line)
	connection_lines.append(line)


func _update_progress() -> void:
	if progress_label:
		progress_label.text = "Connected: %d / %d" % [connections_made, wire_pairs.size()]


func _on_puzzle_complete() -> void:
	is_solved = true
	is_active = false

	var time_taken = (Time.get_ticks_msec() / 1000.0) - start_time

	status_label.text = "CONNECTED!"
	status_label.modulate = Color(0.3, 1.0, 0.3)

	print("[WireConnectPuzzle3D] Puzzle solved in %.2fs!" % time_taken)
	puzzle_solved.emit(puzzle_id, time_taken)


func on_interact(player: Node3D) -> void:
	interact(player)


func force_complete() -> void:
	if not is_solved:
		_on_puzzle_complete()
