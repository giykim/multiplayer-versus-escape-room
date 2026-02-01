extends Node3D
class_name InteractivePuzzlePanel
## InteractivePuzzlePanel - Color memorization puzzle
## Watch the sequence of colors, then repeat it by pressing E when each color lights up

signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_started()

@export var puzzle_id: String = "panel_puzzle"
@export var difficulty: int = 1  # 1-5, affects sequence length

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var is_showing_sequence: bool = false
var start_time: float = 0.0
var presses_needed: int = 3  # For test compatibility - equals sequence length

# Color memorization puzzle
var sequence: Array[int] = []  # The pattern to memorize (0-3 for each button)
var player_input: Array[int] = []  # Player's input so far
var current_show_index: int = 0
var current_input_index: int = 0

# Node references
var panel_mesh: MeshInstance3D
var buttons: Array[MeshInstance3D] = []
var button_areas: Array[Area3D] = []
var status_label: Label3D
var progress_label: Label3D
var interaction_area: Area3D

# Button configuration
const BUTTON_COUNT: int = 4
const BUTTON_POSITIONS: Array[Vector3] = [
	Vector3(-0.5, 0.3, 0.1),   # Top-left
	Vector3(0.5, 0.3, 0.1),    # Top-right
	Vector3(-0.5, -0.3, 0.1),  # Bottom-left
	Vector3(0.5, -0.3, 0.1)    # Bottom-right
]

# Colors for each button
const BUTTON_COLORS: Array[Color] = [
	Color(0.8, 0.2, 0.2),  # Red
	Color(0.2, 0.6, 0.8),  # Blue
	Color(0.8, 0.8, 0.2),  # Yellow
	Color(0.2, 0.8, 0.2)   # Green
]
const COLOR_OFF = Color(0.3, 0.3, 0.3)
const COLOR_SUCCESS = Color(0.3, 1.0, 0.3)


func _ready() -> void:
	_create_panel()
	_create_buttons()
	_create_labels()
	_create_interaction_area()

	# Set default presses_needed based on difficulty
	presses_needed = 2 + difficulty

	add_to_group("interactable")
	add_to_group("puzzle")

	print("[InteractivePuzzlePanel] Ready - difficulty %d" % difficulty)


func _create_panel() -> void:
	panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"

	var box = BoxMesh.new()
	box.size = Vector3(2.0, 1.5, 0.1)
	panel_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.2, 0.3)
	material.emission_enabled = true
	material.emission = Color(0.15, 0.2, 0.3) * 0.3
	material.emission_energy_multiplier = 0.5
	panel_mesh.material_override = material

	add_child(panel_mesh)


func _create_buttons() -> void:
	for i in range(BUTTON_COUNT):
		# Create button mesh
		var button = MeshInstance3D.new()
		button.name = "Button_%d" % i

		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.25
		cylinder.bottom_radius = 0.25
		cylinder.height = 0.08
		button.mesh = cylinder

		# Rotate to face forward and position
		button.rotation.x = deg_to_rad(90)
		button.position = BUTTON_POSITIONS[i]

		_set_button_color(button, COLOR_OFF)
		add_child(button)
		buttons.append(button)

		# Create clickable area for each button
		var area = Area3D.new()
		area.name = "ButtonArea_%d" % i
		area.collision_layer = 32  # Layer 6 = Interactables
		area.collision_mask = 0
		area.set_meta("puzzle_parent", self)
		area.set_meta("button_index", i)
		area.add_to_group("interactable")

		var shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.5, 0.5, 0.3)
		shape.shape = box_shape
		shape.position = BUTTON_POSITIONS[i]

		area.add_child(shape)
		add_child(area)
		button_areas.append(area)


func _set_button_color(button: MeshInstance3D, color: Color) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5 if color != COLOR_OFF else 0.3
	button.material_override = mat


func _create_labels() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "Press E to Start"
	status_label.font_size = 48
	status_label.pixel_size = 0.008
	status_label.position = Vector3(0, 0.65, 0.12)
	status_label.modulate = Color.WHITE
	status_label.outline_size = 12
	status_label.outline_modulate = Color.BLACK
	add_child(status_label)

	progress_label = Label3D.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = ""
	progress_label.font_size = 36
	progress_label.pixel_size = 0.008
	progress_label.position = Vector3(0, -0.6, 0.12)
	progress_label.modulate = Color.WHITE
	progress_label.outline_size = 8
	progress_label.outline_modulate = Color.BLACK
	add_child(progress_label)


func _create_interaction_area() -> void:
	interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	interaction_area.collision_layer = 32  # Layer 6 = Interactables
	interaction_area.collision_mask = 0
	interaction_area.set_meta("puzzle_parent", self)
	interaction_area.add_to_group("interactable")

	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 2.5, 2.0)
	shape.shape = box_shape
	shape.position = Vector3(0, 0, 1.0)

	interaction_area.add_child(shape)
	add_child(interaction_area)


func initialize(seed_value: int, puzzle_difficulty: int) -> void:
	difficulty = puzzle_difficulty
	_generate_sequence(seed_value)
	presses_needed = sequence.size()  # For test compatibility
	_update_progress()
	print("[InteractivePuzzlePanel] Initialized: difficulty=%d, sequence length=%d" % [difficulty, sequence.size()])


func _generate_sequence(seed_value: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value + puzzle_id.hash()

	# Sequence length based on difficulty (3-7)
	var length = 2 + difficulty
	sequence.clear()

	for i in range(length):
		sequence.append(rng.randi_range(0, BUTTON_COUNT - 1))


func start_puzzle() -> void:
	if is_active or is_solved:
		return

	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	player_input.clear()
	current_input_index = 0

	puzzle_started.emit()
	print("[InteractivePuzzlePanel] Puzzle started! Sequence: %s" % str(sequence))

	# Show the sequence to memorize
	_show_sequence()


func _show_sequence() -> void:
	is_showing_sequence = true
	status_label.text = "Watch..."
	_update_progress()

	# Reset all buttons
	for button in buttons:
		_set_button_color(button, COLOR_OFF)

	current_show_index = 0
	_show_next_in_sequence()


func _show_next_in_sequence() -> void:
	if current_show_index >= sequence.size():
		# Done showing sequence
		is_showing_sequence = false
		status_label.text = "Your turn!"
		_update_progress()
		return

	# Light up the current button
	var button_index = sequence[current_show_index]
	_set_button_color(buttons[button_index], BUTTON_COLORS[button_index])

	# Wait, then turn off and show next
	await get_tree().create_timer(0.6).timeout

	if is_active and not is_solved:
		_set_button_color(buttons[button_index], COLOR_OFF)

		await get_tree().create_timer(0.3).timeout

		if is_active and not is_solved:
			current_show_index += 1
			_show_next_in_sequence()


func interact(player: Node3D) -> void:
	if is_solved:
		return

	if not is_active:
		start_puzzle()
		return

	if is_showing_sequence:
		# Can't input while sequence is showing
		return

	# Find which button was pressed based on raycast
	var button_index = _get_aimed_button(player)
	if button_index < 0:
		return

	_on_button_pressed(button_index)


func _get_aimed_button(player: Node3D) -> int:
	# Check if player has a raycast we can use
	var ray = player.get_node_or_null("Head/InteractionRay")
	if ray and ray is RayCast3D and ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.has_meta("button_index"):
			return collider.get_meta("button_index")

	# Fallback: find closest button to aim direction
	var camera = player.get_node_or_null("Head/Camera3D")
	if not camera:
		return -1

	var from = camera.global_position
	var dir = -camera.global_transform.basis.z

	var best_index = -1
	var best_dot = 0.5  # Minimum threshold

	for i in range(BUTTON_COUNT):
		var button_pos = buttons[i].global_position
		var to_button = (button_pos - from).normalized()
		var dot = dir.dot(to_button)

		if dot > best_dot:
			best_dot = dot
			best_index = i

	return best_index


func _on_button_pressed(button_index: int) -> void:
	# Flash the button
	_set_button_color(buttons[button_index], BUTTON_COLORS[button_index])

	# Check if correct
	if button_index == sequence[current_input_index]:
		# Correct!
		player_input.append(button_index)
		current_input_index += 1
		_update_progress()

		print("[InteractivePuzzlePanel] Correct! %d/%d" % [current_input_index, sequence.size()])

		if current_input_index >= sequence.size():
			# Puzzle complete!
			_on_puzzle_complete()
		else:
			# Turn off button after short delay
			await get_tree().create_timer(0.3).timeout
			if is_active and not is_solved:
				_set_button_color(buttons[button_index], COLOR_OFF)
	else:
		# Wrong! Show error and restart sequence
		print("[InteractivePuzzlePanel] Wrong! Expected %d, got %d" % [sequence[current_input_index], button_index])
		status_label.text = "Wrong! Watch again..."
		_set_button_color(buttons[button_index], Color(0.8, 0.2, 0.2))

		await get_tree().create_timer(1.0).timeout

		if is_active and not is_solved:
			player_input.clear()
			current_input_index = 0
			_show_sequence()


func _update_progress() -> void:
	if progress_label:
		if is_showing_sequence:
			progress_label.text = "Memorize: %d colors" % sequence.size()
		else:
			progress_label.text = "Input: %d / %d" % [current_input_index, sequence.size()]


func _on_puzzle_complete() -> void:
	is_solved = true
	is_active = false
	is_showing_sequence = false

	var time_taken = (Time.get_ticks_msec() / 1000.0) - start_time

	# Light up all buttons green
	for button in buttons:
		_set_button_color(button, COLOR_SUCCESS)

	status_label.text = "SOLVED!"
	status_label.modulate = COLOR_SUCCESS

	print("[InteractivePuzzlePanel] Puzzle solved in %.2fs!" % time_taken)
	puzzle_solved.emit(puzzle_id, time_taken)


func on_interact(player: Node3D) -> void:
	interact(player)


func force_complete() -> void:
	if not is_solved:
		_on_puzzle_complete()
