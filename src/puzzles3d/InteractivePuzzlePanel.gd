extends Node3D
class_name InteractivePuzzlePanel
## InteractivePuzzlePanel - Simple 3D puzzle that player can interact with
## Shows a panel with buttons that must be pressed in sequence

signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_started()

@export var puzzle_id: String = "panel_puzzle"
@export var difficulty: int = 1  # 1-5, affects sequence length
@export var panel_color: Color = Color(0.2, 0.3, 0.5)
@export var active_color: Color = Color(0.3, 0.8, 0.3)
@export var error_color: Color = Color(0.8, 0.3, 0.3)

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0

# Sequence puzzle state
var target_sequence: Array[int] = []
var current_input: Array[int] = []
var sequence_length: int = 3
var current_display_index: int = -1
var is_showing_sequence: bool = false

# Node references
var panel_mesh: MeshInstance3D
var buttons: Array[MeshInstance3D] = []
var status_label: Label3D
var interaction_area: Area3D

# Button configuration
const BUTTON_COUNT: int = 4
const BUTTON_SIZE: float = 0.3
const BUTTON_SPACING: float = 0.4


func _ready() -> void:
	_create_panel()
	_create_buttons()
	_create_status_label()
	_create_interaction_area()

	# Set sequence length based on difficulty
	sequence_length = 2 + difficulty  # 3-7 based on difficulty 1-5

	add_to_group("interactable")
	add_to_group("puzzle")


func _create_panel() -> void:
	panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"

	var box = BoxMesh.new()
	box.size = Vector3(2.0, 1.5, 0.1)
	panel_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = panel_color
	material.metallic = 0.3
	material.roughness = 0.7
	panel_mesh.material_override = material

	add_child(panel_mesh)


func _create_buttons() -> void:
	var button_container = Node3D.new()
	button_container.name = "Buttons"
	button_container.position = Vector3(0, 0, 0.06)
	add_child(button_container)

	var positions = [
		Vector3(-0.4, 0.2, 0),   # Top-left
		Vector3(0.4, 0.2, 0),    # Top-right
		Vector3(-0.4, -0.2, 0),  # Bottom-left
		Vector3(0.4, -0.2, 0),   # Bottom-right
	]

	var button_colors = [
		Color(0.8, 0.2, 0.2),  # Red
		Color(0.2, 0.8, 0.2),  # Green
		Color(0.2, 0.2, 0.8),  # Blue
		Color(0.8, 0.8, 0.2),  # Yellow
	]

	for i in BUTTON_COUNT:
		var button = MeshInstance3D.new()
		button.name = "Button_%d" % i

		var cylinder = CylinderMesh.new()
		cylinder.top_radius = BUTTON_SIZE / 2
		cylinder.bottom_radius = BUTTON_SIZE / 2
		cylinder.height = 0.05
		button.mesh = cylinder

		# Rotate to face forward
		button.rotation.x = deg_to_rad(90)
		button.position = positions[i]

		var mat = StandardMaterial3D.new()
		mat.albedo_color = button_colors[i]
		mat.emission_enabled = true
		mat.emission = button_colors[i] * 0.3
		mat.emission_energy_multiplier = 0.5
		button.material_override = mat
		button.set_meta("button_index", i)
		button.set_meta("base_color", button_colors[i])

		button_container.add_child(button)
		buttons.append(button)


func _create_status_label() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "Press E to Start"
	status_label.font_size = 32
	status_label.position = Vector3(0, 0.55, 0.06)
	status_label.modulate = Color.WHITE
	add_child(status_label)


func _create_interaction_area() -> void:
	interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	interaction_area.collision_layer = 8  # Interactables layer
	interaction_area.collision_mask = 0

	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.5, 2.0, 1.0)
	shape.shape = box_shape
	shape.position = Vector3(0, 0, 0.5)

	interaction_area.add_child(shape)
	add_child(interaction_area)


func initialize(seed_value: int, puzzle_difficulty: int) -> void:
	difficulty = puzzle_difficulty
	sequence_length = 2 + difficulty

	# Generate random sequence
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value

	target_sequence.clear()
	for i in sequence_length:
		target_sequence.append(rng.randi_range(0, BUTTON_COUNT - 1))

	print("[InteractivePuzzlePanel] Initialized with sequence: %s" % str(target_sequence))


func start_puzzle() -> void:
	if is_active or is_solved:
		return

	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	current_input.clear()

	puzzle_started.emit()
	print("[InteractivePuzzlePanel] Puzzle started")

	# Show the sequence to memorize
	_show_sequence()


func _show_sequence() -> void:
	is_showing_sequence = true
	status_label.text = "Watch..."
	current_display_index = 0

	# Start showing sequence with a timer
	_show_next_in_sequence()


func _show_next_in_sequence() -> void:
	if current_display_index >= target_sequence.size():
		# Done showing sequence
		is_showing_sequence = false
		status_label.text = "Your turn!"
		_reset_button_colors()
		return

	# Highlight current button
	var button_index = target_sequence[current_display_index]
	_highlight_button(button_index)

	# Schedule next
	await get_tree().create_timer(0.6).timeout
	_reset_button_colors()
	await get_tree().create_timer(0.2).timeout

	current_display_index += 1
	_show_next_in_sequence()


func _highlight_button(index: int) -> void:
	if index < 0 or index >= buttons.size():
		return

	var button = buttons[index]
	var mat = button.material_override as StandardMaterial3D
	if mat:
		mat.emission_energy_multiplier = 2.0


func _reset_button_colors() -> void:
	for button in buttons:
		var mat = button.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.5


func interact(player: Node3D) -> void:
	if is_solved:
		return

	if not is_active:
		start_puzzle()
		return

	if is_showing_sequence:
		return

	# Player is trying to input - use raycast to determine which button
	var camera = player.get_node_or_null("Head/Camera3D")
	if not camera:
		# Fallback: just press the next expected button (for testing)
		_press_button(target_sequence[current_input.size()] if current_input.size() < target_sequence.size() else 0)
		return

	# Raycast from camera
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + -camera.global_transform.basis.z * 5.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 8
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		# No hit, press first button as fallback for testing
		_press_button(current_input.size() % BUTTON_COUNT)
	else:
		# Find which button was hit
		var hit_pos = result.position
		var local_pos = to_local(hit_pos)

		# Determine button from position
		var button_index = _get_button_from_position(local_pos)
		if button_index >= 0:
			_press_button(button_index)


func _get_button_from_position(local_pos: Vector3) -> int:
	# Simple quadrant detection
	if local_pos.x < 0:
		return 0 if local_pos.y > 0 else 2
	else:
		return 1 if local_pos.y > 0 else 3


func _press_button(index: int) -> void:
	if index < 0 or index >= BUTTON_COUNT:
		return

	current_input.append(index)
	_highlight_button(index)

	# Check if input matches so far
	var input_index = current_input.size() - 1
	if current_input[input_index] != target_sequence[input_index]:
		# Wrong button!
		_on_wrong_input()
		return

	# Flash button
	await get_tree().create_timer(0.2).timeout
	_reset_button_colors()

	# Check if complete
	if current_input.size() == target_sequence.size():
		_on_puzzle_complete()


func _on_wrong_input() -> void:
	# Flash red
	for button in buttons:
		var mat = button.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = error_color
			mat.emission = error_color

	status_label.text = "Wrong! Try again..."

	await get_tree().create_timer(0.5).timeout

	# Reset and show sequence again
	current_input.clear()
	for i in buttons.size():
		var button = buttons[i]
		var mat = button.material_override as StandardMaterial3D
		if mat:
			var base_color = button.get_meta("base_color", Color.WHITE)
			mat.albedo_color = base_color
			mat.emission = base_color * 0.3

	_show_sequence()


func _on_puzzle_complete() -> void:
	is_solved = true
	is_active = false

	var time_taken = (Time.get_ticks_msec() / 1000.0) - start_time

	# Flash green
	for button in buttons:
		var mat = button.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = active_color
			mat.emission = active_color
			mat.emission_energy_multiplier = 2.0

	status_label.text = "SOLVED!"
	status_label.modulate = active_color

	print("[InteractivePuzzlePanel] Puzzle solved in %.2fs" % time_taken)
	puzzle_solved.emit(puzzle_id, time_taken)


func force_complete() -> void:
	if not is_solved:
		_on_puzzle_complete()


func on_interact(player: Node3D) -> void:
	interact(player)
