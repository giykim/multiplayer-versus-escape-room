extends BasePuzzle
class_name PatternSequencePuzzle
## PatternSequencePuzzle - Simon Says style memory game
## Players watch a sequence of colors/symbols and must repeat it correctly
## Sequence length increases with difficulty

# Configuration
@export var button_count: int = 4  # Number of pattern buttons
@export var button_size: Vector2 = Vector2(120, 120)
@export var button_spacing: float = 20.0
@export var sequence_display_speed: float = 0.6  # Time between each pattern in sequence
@export var max_wrong_attempts: int = 3  # Failures before puzzle fails

# Difficulty-based sequence lengths
const SEQUENCE_LENGTHS: Dictionary = {
	1: 3,   # Very easy - 3 items
	2: 4,   # Easy - 4 items
	3: 5,   # Medium - 5 items
	4: 6,   # Hard - 6 items
	5: 7    # Expert - 7 items
}

# Puzzle state
var pattern_sequence: Array[int] = []  # The pattern to repeat
var player_input_index: int = 0  # Current position in player's input
var wrong_attempts: int = 0
var is_displaying_sequence: bool = false
var is_accepting_input: bool = false

# Pattern buttons
var buttons: Array[PatternButton] = []

# UI components
var container: Control = null
var timer_label: Label = null
var progress_label: Label = null
var status_label: Label = null
var display_area: Control = null
var sequence_indicators: Array[ColorRect] = []

# Animation state
var display_tween: Tween = null


func _ready() -> void:
	puzzle_id = "pattern_sequence_%d" % get_instance_id()
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)

	# Update timer display
	if timer_label and is_active:
		timer_label.text = "Time: %s" % get_time_string()


func _setup_puzzle() -> void:
	_clear_existing_elements()
	_create_container()
	_create_display_area()
	_create_buttons()
	_create_ui_labels()
	_generate_pattern()
	_update_progress_display()

	# Reset state
	player_input_index = 0
	wrong_attempts = 0
	is_displaying_sequence = false
	is_accepting_input = false

	# Disable buttons initially
	_set_buttons_disabled(true)


func _clear_existing_elements() -> void:
	for button in buttons:
		if is_instance_valid(button):
			button.queue_free()
	buttons.clear()

	for indicator in sequence_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	sequence_indicators.clear()

	if container and is_instance_valid(container):
		container.queue_free()
		container = null


func _create_container() -> void:
	container = Control.new()
	container.name = "PatternContainer"
	add_child(container)


func _create_display_area() -> void:
	# Create display area above buttons for sequence indicators
	display_area = Control.new()
	display_area.name = "DisplayArea"
	display_area.size = Vector2(400, 60)
	display_area.position = Vector2(-200, -180)
	container.add_child(display_area)

	# Create sequence indicators (dots/squares showing progress)
	var sequence_length = _get_sequence_length()
	var indicator_size = mini(30, int(380.0 / sequence_length))
	var total_width = sequence_length * indicator_size + (sequence_length - 1) * 5
	var start_x = (400 - total_width) / 2

	for i in sequence_length:
		var indicator = ColorRect.new()
		indicator.name = "Indicator_%d" % i
		indicator.size = Vector2(indicator_size - 4, indicator_size - 4)
		indicator.position = Vector2(start_x + i * (indicator_size + 5), 15)
		indicator.color = Color(0.3, 0.3, 0.3)
		display_area.add_child(indicator)
		sequence_indicators.append(indicator)


func _create_buttons() -> void:
	# Create pattern buttons in a 2x2 grid
	var grid_cols = 2
	var grid_rows = 2
	var total_width = grid_cols * button_size.x + (grid_cols - 1) * button_spacing
	var total_height = grid_rows * button_size.y + (grid_rows - 1) * button_spacing
	var start_pos = Vector2(-total_width / 2, -total_height / 2 + 20)

	for i in button_count:
		var button = PatternButton.new()
		button.name = "PatternButton_%d" % i
		button.custom_minimum_size = button_size
		button.size = button_size

		# Position in grid
		var col = i % grid_cols
		var row = i / grid_cols
		button.position = start_pos + Vector2(
			col * (button_size.x + button_spacing),
			row * (button_size.y + button_spacing)
		)

		# Set pivot for scaling animations
		button.pivot_offset = button_size / 2

		button.setup(i)
		button.button_pressed.connect(_on_button_pressed)
		container.add_child(button)
		buttons.append(button)


func _create_ui_labels() -> void:
	# Timer label
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(-100, -220)
	timer_label.size = Vector2(200, 30)
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.text = "Time: 00:00.00"
	container.add_child(timer_label)

	# Progress label
	progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.position = Vector2(-150, 160)
	progress_label.size = Vector2(300, 30)
	progress_label.add_theme_font_size_override("font_size", 18)
	container.add_child(progress_label)

	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-150, 190)
	status_label.size = Vector2(300, 30)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(status_label)


func _get_sequence_length() -> int:
	return SEQUENCE_LENGTHS.get(difficulty, 5)


func _generate_pattern() -> void:
	pattern_sequence.clear()
	var sequence_length = _get_sequence_length()

	print("[%s] Generating pattern with length %d (difficulty: %d)" % [puzzle_id, sequence_length, difficulty])

	for i in sequence_length:
		var next_button = get_seeded_randi_range(0, button_count - 1)
		pattern_sequence.append(next_button)

	print("[%s] Pattern: %s" % [puzzle_id, pattern_sequence])


func _set_buttons_disabled(disabled: bool) -> void:
	for button in buttons:
		button.set_button_disabled(disabled)


func _on_puzzle_started() -> void:
	# Start by displaying the sequence
	_display_sequence()


func _display_sequence() -> void:
	is_displaying_sequence = true
	is_accepting_input = false
	_set_buttons_disabled(true)
	_update_status("Watch the pattern...")

	# Cancel any existing display
	if display_tween and display_tween.is_valid():
		display_tween.kill()

	display_tween = create_tween()

	# Small delay before starting
	display_tween.tween_interval(0.5)

	# Light up each button in sequence
	for i in pattern_sequence.size():
		var button_index = pattern_sequence[i]
		display_tween.tween_callback(_light_up_button.bind(button_index, i))
		display_tween.tween_interval(sequence_display_speed)

	# After sequence, enable input
	display_tween.tween_callback(_on_sequence_display_complete)


func _light_up_button(button_index: int, sequence_index: int) -> void:
	if button_index < buttons.size():
		buttons[button_index].light_up(sequence_display_speed * 0.8)

		# Highlight the corresponding indicator
		if sequence_index < sequence_indicators.size():
			var indicator = sequence_indicators[sequence_index]
			var button_color = PatternButton.BUTTON_COLORS[button_index]
			indicator.color = button_color


func _on_sequence_display_complete() -> void:
	is_displaying_sequence = false
	is_accepting_input = true
	player_input_index = 0
	_set_buttons_disabled(false)
	_update_status("Your turn! Repeat the pattern")
	_update_progress_display()

	# Reset indicators to show progress
	_reset_indicators_for_input()


func _reset_indicators_for_input() -> void:
	for indicator in sequence_indicators:
		indicator.color = Color(0.3, 0.3, 0.3)


func _on_button_pressed(button: PatternButton) -> void:
	if not is_active or is_solved or not is_accepting_input or is_displaying_sequence:
		return

	var pressed_index = button.button_index
	var expected_index = pattern_sequence[player_input_index]

	if pressed_index == expected_index:
		# Correct input
		_on_correct_input(button)
	else:
		# Wrong input
		_on_wrong_input(button)


func _on_correct_input(button: PatternButton) -> void:
	button.flash_correct()

	# Update indicator
	if player_input_index < sequence_indicators.size():
		var indicator = sequence_indicators[player_input_index]
		indicator.color = PatternButton.BUTTON_COLORS[button.button_index]

	player_input_index += 1
	_update_progress_display()

	# Check if pattern is complete
	if player_input_index >= pattern_sequence.size():
		_on_pattern_complete()


func _on_wrong_input(button: PatternButton) -> void:
	button.flash_incorrect()
	wrong_attempts += 1

	# Flash the correct button to show the mistake
	var correct_index = pattern_sequence[player_input_index]
	if correct_index < buttons.size():
		await get_tree().create_timer(0.3).timeout
		buttons[correct_index].light_up(0.5)

	if wrong_attempts >= max_wrong_attempts:
		# Too many wrong attempts - fail
		_update_status("Too many mistakes!")
		await get_tree().create_timer(0.5).timeout
		fail_puzzle()
	else:
		# Reset and show sequence again
		var remaining = max_wrong_attempts - wrong_attempts
		_update_status("Wrong! %d attempts remaining" % remaining)
		await get_tree().create_timer(1.0).timeout
		player_input_index = 0
		_display_sequence()


func _on_pattern_complete() -> void:
	is_accepting_input = false
	_set_buttons_disabled(true)
	_update_status("Pattern complete!")
	solve_puzzle()


func _update_progress_display() -> void:
	if progress_label:
		var total = pattern_sequence.size()
		var current = player_input_index
		progress_label.text = "Progress: %d / %d" % [current, total]


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = message


func _check_solution() -> bool:
	return player_input_index >= pattern_sequence.size()


func _reset_puzzle() -> void:
	# Cancel any running animations
	if display_tween and display_tween.is_valid():
		display_tween.kill()

	is_displaying_sequence = false
	is_accepting_input = false
	player_input_index = 0
	wrong_attempts = 0

	_setup_puzzle()


func _on_puzzle_solved() -> void:
	# Celebration animation for all buttons
	for button in buttons:
		button.celebrate()

	_update_status("Solved! Great memory!")
	print("[%s] Solved with %d wrong attempts!" % [puzzle_id, wrong_attempts])


func _on_puzzle_failed() -> void:
	_set_buttons_disabled(true)
	_update_status("Failed! Pattern not completed")

	# Dim all buttons
	for button in buttons:
		button.modulate = Color(0.5, 0.5, 0.5)


## Get the current wrong attempt count
func get_wrong_attempts() -> int:
	return wrong_attempts


## Get the pattern length for current difficulty
func get_pattern_length() -> int:
	return _get_sequence_length()


## Replay the sequence (can be called externally if needed)
func replay_sequence() -> void:
	if is_active and not is_displaying_sequence and not is_solved:
		# Count as a wrong attempt for balance
		wrong_attempts += 1
		if wrong_attempts < max_wrong_attempts:
			player_input_index = 0
			_display_sequence()
