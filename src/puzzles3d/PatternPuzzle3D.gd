extends BasePuzzle3D
class_name PatternPuzzle3D
## PatternPuzzle3D - 3D Simon-says pattern matching puzzle
## Watch the sequence of lit buttons, then repeat it by looking and clicking

# Configuration
@export var button_count: int = 4
@export var button_radius: float = 0.15
@export var button_height: float = 0.08
@export var button_spacing: float = 0.5
@export var sequence_show_delay: float = 0.5  # Time between sequence steps
@export var button_light_duration: float = 0.4  # How long each button stays lit

# Button colors
@export var button_colors: Array[Color] = [
	Color(1.0, 0.2, 0.2),  # Red
	Color(0.2, 1.0, 0.2),  # Green
	Color(0.2, 0.2, 1.0),  # Blue
	Color(1.0, 1.0, 0.2)   # Yellow
]

# Difficulty settings (sequence length per difficulty)
const SEQUENCE_LENGTH: Dictionary = {
	1: 3,   # Very easy
	2: 5,   # Easy
	3: 7,   # Medium
	4: 10,  # Hard
	5: 15   # Expert
}

# Puzzle state
var buttons: Array[PatternButton3D] = []
var target_sequence: Array[int] = []
var player_sequence: Array[int] = []
var current_sequence_index: int = 0
var is_showing_sequence: bool = false
var is_player_turn: bool = false
var sequence_length: int = 5

# Components
var panel_mesh: MeshInstance3D = null
var buttons_container: Node3D = null


func _ready() -> void:
	puzzle_id = "pattern_puzzle_3d_%d" % get_instance_id()
	super._ready()


func _setup_puzzle() -> void:
	_clear_existing_buttons()
	_create_panel()
	_create_buttons()
	_generate_sequence()


func _clear_existing_buttons() -> void:
	for button in buttons:
		if is_instance_valid(button):
			button.queue_free()
	buttons.clear()

	if buttons_container:
		buttons_container.queue_free()
		buttons_container = null


func _create_panel() -> void:
	# Create panel mesh if not exists
	if not panel_mesh:
		panel_mesh = MeshInstance3D.new()
		panel_mesh.name = "PanelMesh"
		add_child(panel_mesh)

	# Calculate panel size based on button layout
	var panel_size = button_spacing * 2 + button_radius * 4
	var panel_thickness = 0.1

	# Create panel mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(panel_size, panel_thickness, panel_size)
	panel_mesh.mesh = box_mesh

	# Position panel behind buttons
	panel_mesh.position = Vector3(0, -panel_thickness / 2 - button_height / 2, 0)

	# Create panel material
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.1, 0.1, 0.15)
	panel_mesh.set_surface_override_material(0, panel_mat)

	# Create buttons container
	buttons_container = Node3D.new()
	buttons_container.name = "ButtonsContainer"
	add_child(buttons_container)


func _create_buttons() -> void:
	# Create 4 buttons in a 2x2 grid layout
	var positions = [
		Vector3(-button_spacing / 2, 0, -button_spacing / 2),  # Top-left
		Vector3(button_spacing / 2, 0, -button_spacing / 2),   # Top-right
		Vector3(-button_spacing / 2, 0, button_spacing / 2),   # Bottom-left
		Vector3(button_spacing / 2, 0, button_spacing / 2)     # Bottom-right
	]

	for i in min(button_count, 4):
		var button = _create_button(i)
		buttons.append(button)
		buttons_container.add_child(button)
		button.position = positions[i]


func _create_button(index: int) -> PatternButton3D:
	var button = PatternButton3D.new()
	button.name = "PatternButton_%d" % index
	button.button_index = index
	button.button_radius = button_radius
	button.button_height = button_height

	# Set color
	if index < button_colors.size():
		button.button_color = button_colors[index]
	else:
		button.button_color = Color.WHITE

	# Connect signals
	button.element_activated.connect(_on_button_activated)
	button.button_pressed.connect(_on_button_pressed)

	return button


func _generate_sequence() -> void:
	target_sequence.clear()
	player_sequence.clear()
	current_sequence_index = 0

	sequence_length = SEQUENCE_LENGTH.get(difficulty, 5)

	print("[%s] Generating sequence of length %d (difficulty: %d)" % [puzzle_id, sequence_length, difficulty])

	for i in sequence_length:
		var button_index = get_seeded_randi_range(0, buttons.size() - 1)
		target_sequence.append(button_index)


func _on_puzzle_started() -> void:
	# Start showing the sequence
	_show_sequence()


func _show_sequence() -> void:
	is_showing_sequence = true
	is_player_turn = false
	current_sequence_index = 0

	# Disable button interaction during sequence display
	for button in buttons:
		button.set_interactable(false)

	# Start the sequence display
	_show_next_in_sequence()


func _show_next_in_sequence() -> void:
	if current_sequence_index >= target_sequence.size():
		# Sequence complete, player's turn
		_start_player_turn()
		return

	var button_index = target_sequence[current_sequence_index]
	var button = buttons[button_index]

	# Light up the button
	button.light_up(button_light_duration)

	current_sequence_index += 1

	# Schedule next button in sequence
	var timer = get_tree().create_timer(button_light_duration + sequence_show_delay)
	timer.timeout.connect(_show_next_in_sequence)


func _start_player_turn() -> void:
	is_showing_sequence = false
	is_player_turn = true
	player_sequence.clear()

	print("[%s] Player's turn - repeat the sequence!" % puzzle_id)

	# Enable button interaction
	for button in buttons:
		button.set_interactable(true)


func _on_button_activated(element: PuzzleElement3D) -> void:
	# This is called when player looks at and clicks a button
	pass


func _on_button_pressed(button: PatternButton3D) -> void:
	if not is_active or is_solved or is_showing_sequence or not is_player_turn:
		return

	var pressed_index = button.button_index
	var expected_index = target_sequence[player_sequence.size()]

	# Visual feedback - light up the pressed button
	button.light_up(0.2)

	if pressed_index == expected_index:
		# Correct button
		player_sequence.append(pressed_index)
		button.flash_valid()

		print("[%s] Correct! %d/%d" % [puzzle_id, player_sequence.size(), target_sequence.size()])

		# Check if sequence complete
		if player_sequence.size() >= target_sequence.size():
			solve_puzzle()
	else:
		# Wrong button
		button.flash_invalid()
		print("[%s] Wrong! Expected %d, got %d" % [puzzle_id, expected_index, pressed_index])

		# Flash all buttons red
		for b in buttons:
			b.flash_invalid()

		# Restart the sequence
		await get_tree().create_timer(0.5).timeout
		player_sequence.clear()
		_show_sequence()


func _on_puzzle_solved() -> void:
	# Celebration animation
	for button in buttons:
		button.celebrate()
		button.light_up(1.0)

	print("[%s] Pattern matched successfully!" % puzzle_id)


func _on_puzzle_failed() -> void:
	pass


func _reset_puzzle() -> void:
	is_showing_sequence = false
	is_player_turn = false
	player_sequence.clear()
	target_sequence.clear()
	_setup_puzzle()


## Get the current player progress
func get_progress() -> Dictionary:
	return {
		"current": player_sequence.size(),
		"total": target_sequence.size()
	}


# Inner class for pattern buttons
class PatternButton3D extends PuzzleElement3D:
	## PatternButton3D - Colored button that lights up for pattern puzzle

	signal button_pressed(button: PatternButton3D)

	# Button configuration
	var button_index: int = 0
	var button_radius: float = 0.15
	var button_height: float = 0.08
	var button_color: Color = Color.RED

	# Visual state
	var is_lit: bool = false
	var light_tween: Tween = null

	# Materials
	var button_material: StandardMaterial3D = null
	var lit_emission_energy: float = 2.0


	func _ready() -> void:
		super._ready()
		_create_visuals()


	func _create_visuals() -> void:
		# Create cylinder mesh for button
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = button_radius
		cylinder_mesh.bottom_radius = button_radius * 1.1
		cylinder_mesh.height = button_height

		if not mesh_instance:
			mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "ButtonMesh"
			add_child(mesh_instance)

		mesh_instance.mesh = cylinder_mesh

		# Create button material
		button_material = StandardMaterial3D.new()
		button_material.albedo_color = button_color
		button_material.emission_enabled = true
		button_material.emission = button_color
		button_material.emission_energy_multiplier = 0.2  # Dim by default
		mesh_instance.set_surface_override_material(0, button_material)

		# Update base class materials
		_original_material = button_material.duplicate()
		_highlight_material = button_material.duplicate()

		# Create collision shape
		if not collision_shape:
			collision_shape = CollisionShape3D.new()
			collision_shape.name = "ButtonCollision"
			add_child(collision_shape)

		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.radius = button_radius
		cylinder_shape.height = button_height
		collision_shape.shape = cylinder_shape


	func _on_activated() -> void:
		# Called when player clicks on this button
		button_pressed.emit(self)


	func light_up(duration: float) -> void:
		if light_tween and light_tween.is_valid():
			light_tween.kill()

		is_lit = true

		# Bright emission
		if button_material:
			button_material.emission_energy_multiplier = lit_emission_energy

		# Create tween to dim back down
		light_tween = create_tween()
		light_tween.tween_interval(duration)
		light_tween.tween_callback(_dim_button)


	func _dim_button() -> void:
		is_lit = false
		if button_material:
			button_material.emission_energy_multiplier = 0.2


	func set_highlighted(highlighted: bool, color: Color = Color.WHITE, intensity: float = 0.5) -> void:
		if not is_interactable:
			return

		is_highlighted = highlighted

		if button_material:
			if highlighted and not is_lit:
				# Increase emission slightly when highlighted
				button_material.emission_energy_multiplier = 0.6
			elif not is_lit:
				button_material.emission_energy_multiplier = 0.2

		element_highlighted.emit(self, highlighted)


	func flash_invalid() -> void:
		if light_tween and light_tween.is_valid():
			light_tween.kill()

		var original_color = button_color

		light_tween = create_tween()
		light_tween.tween_property(button_material, "emission", Color.RED, 0.1)
		light_tween.tween_property(button_material, "emission", original_color, 0.1)


	func flash_valid() -> void:
		if light_tween and light_tween.is_valid():
			light_tween.kill()

		var original_color = button_color

		light_tween = create_tween()
		light_tween.tween_property(button_material, "emission", Color.WHITE, 0.1)
		light_tween.tween_property(button_material, "emission", original_color, 0.1)
