extends Node3D
class_name InteractivePuzzlePanel
## InteractivePuzzlePanel - Simple 3D puzzle that player can interact with
## Press E to interact, solve by pressing E when buttons light up

signal puzzle_solved(puzzle_id: String, time_taken: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_started()

@export var puzzle_id: String = "panel_puzzle"
@export var difficulty: int = 1  # 1-5, affects number of presses needed

# Puzzle state
var is_active: bool = false
var is_solved: bool = false
var start_time: float = 0.0

# Simple puzzle: press E when the center button is green
var presses_needed: int = 3
var presses_done: int = 0
var current_button_lit: int = -1
var waiting_for_input: bool = false

# Node references
var panel_mesh: MeshInstance3D
var center_button: MeshInstance3D
var status_label: Label3D
var progress_label: Label3D
var interaction_area: Area3D

# Colors
const COLOR_PANEL = Color(0.15, 0.2, 0.3)
const COLOR_BUTTON_OFF = Color(0.3, 0.3, 0.3)
const COLOR_BUTTON_READY = Color(0.2, 0.8, 0.2)
const COLOR_BUTTON_SUCCESS = Color(0.3, 1.0, 0.3)
const COLOR_BUTTON_FAIL = Color(0.8, 0.2, 0.2)


func _ready() -> void:
	_create_panel()
	_create_button()
	_create_labels()
	_create_interaction_area()

	# Set presses needed based on difficulty
	presses_needed = 2 + difficulty  # 3-7 based on difficulty 1-5

	add_to_group("interactable")
	add_to_group("puzzle")

	print("[InteractivePuzzlePanel] Ready - need %d successful presses" % presses_needed)


func _create_panel() -> void:
	panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelMesh"

	var box = BoxMesh.new()
	box.size = Vector3(2.0, 1.5, 0.1)
	panel_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = COLOR_PANEL
	material.emission_enabled = true
	material.emission = COLOR_PANEL * 0.3
	material.emission_energy_multiplier = 0.5
	panel_mesh.material_override = material

	add_child(panel_mesh)


func _create_button() -> void:
	center_button = MeshInstance3D.new()
	center_button.name = "CenterButton"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.35
	cylinder.bottom_radius = 0.35
	cylinder.height = 0.08
	center_button.mesh = cylinder

	# Rotate to face forward
	center_button.rotation.x = deg_to_rad(90)
	center_button.position = Vector3(0, 0, 0.1)

	_set_button_color(COLOR_BUTTON_OFF)

	add_child(center_button)


func _set_button_color(color: Color) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	center_button.material_override = mat


func _create_labels() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "Press E to Start"
	status_label.font_size = 64
	status_label.pixel_size = 0.008
	status_label.position = Vector3(0, 0.55, 0.12)
	status_label.modulate = Color.WHITE
	status_label.outline_size = 12
	status_label.outline_modulate = Color.BLACK
	add_child(status_label)

	progress_label = Label3D.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = ""
	progress_label.font_size = 48
	progress_label.pixel_size = 0.008
	progress_label.position = Vector3(0, -0.5, 0.12)
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
	presses_needed = 2 + difficulty
	_update_progress()
	print("[InteractivePuzzlePanel] Initialized: difficulty=%d, presses_needed=%d" % [difficulty, presses_needed])


func start_puzzle() -> void:
	if is_active or is_solved:
		return

	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	presses_done = 0

	puzzle_started.emit()
	print("[InteractivePuzzlePanel] Puzzle started!")

	# Start the button lighting cycle
	_start_button_cycle()


func _start_button_cycle() -> void:
	status_label.text = "Press E when GREEN!"
	_update_progress()

	# Light up the button after a short delay
	await get_tree().create_timer(0.5).timeout
	if is_active and not is_solved:
		_light_button()


func _light_button() -> void:
	if not is_active or is_solved:
		return

	waiting_for_input = true
	_set_button_color(COLOR_BUTTON_READY)
	status_label.text = "NOW! Press E!"

	# Give player time to react, then turn off
	await get_tree().create_timer(1.5).timeout

	if waiting_for_input and is_active and not is_solved:
		# Player missed it
		waiting_for_input = false
		_set_button_color(COLOR_BUTTON_FAIL)
		status_label.text = "Missed! Try again..."

		await get_tree().create_timer(0.8).timeout
		if is_active and not is_solved:
			_set_button_color(COLOR_BUTTON_OFF)
			_start_button_cycle()


func interact(player: Node3D) -> void:
	print("[InteractivePuzzlePanel] interact() called, is_active=%s, is_solved=%s, waiting=%s" % [is_active, is_solved, waiting_for_input])

	if is_solved:
		return

	if not is_active:
		start_puzzle()
		return

	if waiting_for_input:
		# Player pressed at the right time!
		waiting_for_input = false
		presses_done += 1
		_update_progress()

		_set_button_color(COLOR_BUTTON_SUCCESS)
		status_label.text = "Good!"

		print("[InteractivePuzzlePanel] Correct press! %d/%d" % [presses_done, presses_needed])

		if presses_done >= presses_needed:
			_on_puzzle_complete()
		else:
			await get_tree().create_timer(0.5).timeout
			if is_active and not is_solved:
				_set_button_color(COLOR_BUTTON_OFF)
				_start_button_cycle()
	else:
		# Player pressed too early or button wasn't lit
		_set_button_color(COLOR_BUTTON_FAIL)
		status_label.text = "Wait for GREEN!"

		await get_tree().create_timer(0.5).timeout
		if is_active and not is_solved:
			_set_button_color(COLOR_BUTTON_OFF)


func _update_progress() -> void:
	progress_label.text = "%d / %d" % [presses_done, presses_needed]


func _on_puzzle_complete() -> void:
	is_solved = true
	is_active = false
	waiting_for_input = false

	var time_taken = (Time.get_ticks_msec() / 1000.0) - start_time

	_set_button_color(COLOR_BUTTON_SUCCESS)
	status_label.text = "SOLVED!"
	status_label.modulate = COLOR_BUTTON_SUCCESS

	print("[InteractivePuzzlePanel] Puzzle solved in %.2fs!" % time_taken)
	puzzle_solved.emit(puzzle_id, time_taken)


func on_interact(player: Node3D) -> void:
	interact(player)


func force_complete() -> void:
	if not is_solved:
		_on_puzzle_complete()
