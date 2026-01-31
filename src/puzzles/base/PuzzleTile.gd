extends Control
class_name PuzzleTile
## PuzzleTile - Individual tile component for sliding tile puzzle
## Handles click detection, visual states, and slide animations

# Signals
signal tile_clicked(tile: PuzzleTile)
signal slide_completed(tile: PuzzleTile)

# Tile data
var tile_value: int = 0  # The number/image this tile represents (0 = empty)
var grid_position: Vector2i = Vector2i.ZERO  # Current position in grid
var correct_position: Vector2i = Vector2i.ZERO  # Where this tile should be when solved

# Visual state
var is_empty: bool = false
var is_in_correct_position: bool = false
var is_sliding: bool = false
var is_hovering: bool = false

# Animation
var slide_tween: Tween = null
const SLIDE_DURATION: float = 0.15

# Visual components (created dynamically or assigned from scene)
var background_panel: Panel = null
var value_label: Label = null
var highlight_overlay: ColorRect = null

# Colors
const COLOR_DEFAULT: Color = Color(0.2, 0.3, 0.5)
const COLOR_CORRECT: Color = Color(0.2, 0.5, 0.3)
const COLOR_WRONG: Color = Color(0.5, 0.3, 0.2)
const COLOR_HOVER: Color = Color(0.3, 0.4, 0.6)
const COLOR_EMPTY: Color = Color(0.1, 0.1, 0.1, 0.3)
const COLOR_HIGHLIGHT: Color = Color(1.0, 1.0, 1.0, 0.2)


func _ready() -> void:
	_setup_visuals()
	_update_visual_state()

	# Connect input signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _setup_visuals() -> void:
	# Create background panel if not already a child
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_panel)

	# Create value label
	value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 32)
	add_child(value_label)

	# Create highlight overlay
	highlight_overlay = ColorRect.new()
	highlight_overlay.name = "HighlightOverlay"
	highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_overlay.color = Color.TRANSPARENT
	highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight_overlay)

	# Make sure we can receive input
	mouse_filter = Control.MOUSE_FILTER_STOP


## Initialize the tile with value and position
func setup(value: int, grid_pos: Vector2i, correct_pos: Vector2i) -> void:
	tile_value = value
	grid_position = grid_pos
	correct_position = correct_pos
	is_empty = (value == 0)

	_update_correct_state()
	_update_visual_state()


## Update grid position (called when tile slides)
func set_grid_position(new_pos: Vector2i) -> void:
	grid_position = new_pos
	_update_correct_state()
	_update_visual_state()


## Check if tile is in its correct solved position
func _update_correct_state() -> void:
	is_in_correct_position = (grid_position == correct_position)


## Animate sliding to a new visual position
func slide_to(target_position: Vector2, on_complete: Callable = Callable()) -> void:
	if is_sliding:
		return

	is_sliding = true

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
	is_sliding = false
	slide_completed.emit(self)

	if callback.is_valid():
		callback.call()


## Update all visual elements based on current state
func _update_visual_state() -> void:
	if not is_inside_tree():
		return

	# Update label text
	if value_label:
		if is_empty:
			value_label.text = ""
		else:
			value_label.text = str(tile_value)

	# Update background color
	_update_background_color()

	# Update visibility
	if highlight_overlay:
		highlight_overlay.color = COLOR_HIGHLIGHT if is_hovering and not is_empty else Color.TRANSPARENT

	# Empty tiles are less visible
	modulate.a = 0.0 if is_empty else 1.0


func _update_background_color() -> void:
	if not background_panel:
		return

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if is_empty:
		style.bg_color = COLOR_EMPTY
	elif is_hovering:
		style.bg_color = COLOR_HOVER
	elif is_in_correct_position:
		style.bg_color = COLOR_CORRECT
	else:
		style.bg_color = COLOR_DEFAULT

	# Add subtle border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = style.bg_color.lightened(0.3)

	background_panel.add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if is_empty or is_sliding:
		return

	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			tile_clicked.emit(self)
			accept_event()


func _on_mouse_entered() -> void:
	if not is_empty and not is_sliding:
		is_hovering = true
		_update_visual_state()


func _on_mouse_exited() -> void:
	is_hovering = false
	_update_visual_state()


## Flash feedback for invalid move
func flash_invalid() -> void:
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)


## Flash feedback for valid move
func flash_valid() -> void:
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.GREEN, 0.1)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)


## Celebratory animation when puzzle is solved
func celebrate() -> void:
	var celebrate_tween = create_tween()
	celebrate_tween.set_loops(2)
	celebrate_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
	celebrate_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
