extends Control
class_name PatternButton
## PatternButton - Individual button for pattern sequence puzzle
## Handles click detection, light-up animations, and feedback states

# Signals
signal button_pressed(button: PatternButton)

# Button identity
var button_index: int = 0  # 0-3 for the four buttons
var button_color: Color = Color.WHITE

# Visual state
var is_lit: bool = false
var is_disabled: bool = true
var is_hovering: bool = false

# Animation
var light_tween: Tween = null
var feedback_tween: Tween = null
const LIGHT_UP_DURATION: float = 0.4
const FEEDBACK_DURATION: float = 0.2

# Visual components
var background_panel: Panel = null
var highlight_overlay: ColorRect = null
var symbol_label: Label = null

# Color presets for the four buttons
const BUTTON_COLORS: Array[Color] = [
	Color(0.8, 0.2, 0.2),   # Red
	Color(0.2, 0.6, 0.8),   # Blue
	Color(0.2, 0.7, 0.3),   # Green
	Color(0.8, 0.7, 0.2)    # Yellow
]

# Symbols for the buttons (optional visual aid)
const BUTTON_SYMBOLS: Array[String] = [
	"^",  # Triangle/Up
	"O",  # Circle
	"#",  # Square
	"*"   # Star
]

# Lit color multiplier
const LIT_BRIGHTNESS: float = 1.5
const DIM_BRIGHTNESS: float = 0.5


func _ready() -> void:
	_setup_visuals()
	_update_visual_state()

	# Connect input signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _setup_visuals() -> void:
	# Create background panel
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_panel)

	# Create symbol label
	symbol_label = Label.new()
	symbol_label.name = "SymbolLabel"
	symbol_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol_label.add_theme_font_size_override("font_size", 48)
	add_child(symbol_label)

	# Create highlight overlay for lit state
	highlight_overlay = ColorRect.new()
	highlight_overlay.name = "HighlightOverlay"
	highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_overlay.color = Color.TRANSPARENT
	highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight_overlay)

	# Make sure we can receive input
	mouse_filter = Control.MOUSE_FILTER_STOP


## Initialize the button with an index (0-3)
func setup(index: int) -> void:
	button_index = index
	button_color = BUTTON_COLORS[index] if index < BUTTON_COLORS.size() else Color.WHITE

	if symbol_label and index < BUTTON_SYMBOLS.size():
		symbol_label.text = BUTTON_SYMBOLS[index]

	_update_visual_state()


## Enable or disable button interaction
func set_button_disabled(disabled: bool) -> void:
	is_disabled = disabled
	_update_visual_state()


## Light up the button (during sequence display)
func light_up(duration: float = LIGHT_UP_DURATION) -> void:
	is_lit = true
	_update_visual_state()

	# Cancel existing tween
	if light_tween and light_tween.is_valid():
		light_tween.kill()

	light_tween = create_tween()
	light_tween.tween_interval(duration)
	light_tween.tween_callback(_on_light_complete)


func _on_light_complete() -> void:
	is_lit = false
	_update_visual_state()


## Show correct feedback
func flash_correct() -> void:
	_flash_feedback(Color.WHITE, 1.3)


## Show incorrect feedback
func flash_incorrect() -> void:
	_flash_feedback(Color.RED, 0.5)


func _flash_feedback(tint: Color, scale_factor: float) -> void:
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()

	feedback_tween = create_tween()
	feedback_tween.set_parallel(true)
	feedback_tween.tween_property(self, "modulate", tint, FEEDBACK_DURATION * 0.5)
	feedback_tween.tween_property(self, "scale", Vector2(scale_factor, scale_factor), FEEDBACK_DURATION * 0.5)

	feedback_tween.chain()
	feedback_tween.set_parallel(true)
	feedback_tween.tween_property(self, "modulate", Color.WHITE, FEEDBACK_DURATION * 0.5)
	feedback_tween.tween_property(self, "scale", Vector2.ONE, FEEDBACK_DURATION * 0.5)


## Quick light up for player input feedback
func pulse() -> void:
	is_lit = true
	_update_visual_state()

	if light_tween and light_tween.is_valid():
		light_tween.kill()

	light_tween = create_tween()
	light_tween.tween_interval(0.15)
	light_tween.tween_callback(_on_light_complete)


## Update all visual elements based on current state
func _update_visual_state() -> void:
	if not is_inside_tree():
		return

	_update_background_color()

	# Update symbol visibility based on disabled state
	if symbol_label:
		symbol_label.modulate.a = 0.3 if is_disabled else 1.0

	# Highlight overlay for lit state
	if highlight_overlay:
		highlight_overlay.color = Color(1, 1, 1, 0.4) if is_lit else Color.TRANSPARENT


func _update_background_color() -> void:
	if not background_panel:
		return

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16

	# Calculate color based on state
	var display_color = button_color

	if is_lit:
		display_color = button_color * LIT_BRIGHTNESS
		display_color.a = 1.0
	elif is_disabled:
		display_color = button_color * DIM_BRIGHTNESS
		display_color.a = 1.0
	elif is_hovering:
		display_color = button_color.lightened(0.2)

	style.bg_color = display_color

	# Add border
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = display_color.lightened(0.4) if is_lit else display_color.darkened(0.2)

	# Add shadow for depth
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4 if is_lit else 2
	style.shadow_offset = Vector2(2, 2)

	background_panel.add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if is_disabled:
		return

	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			pulse()
			button_pressed.emit(self)
			accept_event()


func _on_mouse_entered() -> void:
	if not is_disabled:
		is_hovering = true
		_update_visual_state()


func _on_mouse_exited() -> void:
	is_hovering = false
	_update_visual_state()


## Celebration animation when puzzle is solved
func celebrate() -> void:
	var celebrate_tween = create_tween()
	celebrate_tween.set_loops(3)
	celebrate_tween.tween_property(self, "modulate", button_color.lightened(0.5), 0.2)
	celebrate_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
