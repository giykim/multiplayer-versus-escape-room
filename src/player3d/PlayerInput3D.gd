extends Node
class_name PlayerInput3D
## PlayerInput3D - Handles first-person input processing for local player
## Processes movement, mouse look, and interaction input

# Input signals
signal movement_input_changed(direction: Vector3)
signal look_input(mouse_motion: Vector2)
signal interact_pressed()
signal interact_released()
signal jump_pressed()
signal sprint_started()
signal sprint_ended()

## Only process input if this is the local player
var is_local_player: bool = true

## Current movement direction (normalized, in local space)
var movement_direction: Vector3 = Vector3.ZERO

## Sprint state
var is_sprinting: bool = false

## Mouse sensitivity
@export var mouse_sensitivity: float = 0.002


func _ready() -> void:
	# Input processing is enabled by default for local player
	set_process_input(is_local_player)
	set_physics_process(is_local_player)


func set_local_player(is_local: bool) -> void:
	is_local_player = is_local
	set_process_input(is_local)
	set_physics_process(is_local)

	if is_local:
		# Capture mouse for FPS controls
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		movement_direction = Vector3.ZERO
		is_sprinting = false
		movement_input_changed.emit(movement_direction)


func _physics_process(_delta: float) -> void:
	if not is_local_player:
		return

	_process_movement_input()
	_process_sprint_input()


func _process_movement_input() -> void:
	var new_direction = Vector3.ZERO

	# Get input from defined actions (WASD/arrows)
	# Forward/back on Z axis, left/right on X axis
	new_direction.x = Input.get_axis("move_left", "move_right")
	new_direction.z = Input.get_axis("move_up", "move_down")

	# Normalize diagonal movement to prevent faster diagonal speed
	if new_direction.length() > 1.0:
		new_direction = new_direction.normalized()

	# Only emit if direction changed to avoid unnecessary signals
	if new_direction != movement_direction:
		movement_direction = new_direction
		movement_input_changed.emit(movement_direction)


func _process_sprint_input() -> void:
	var sprint_pressed = Input.is_action_pressed("sprint")

	if sprint_pressed and not is_sprinting:
		is_sprinting = true
		sprint_started.emit()
	elif not sprint_pressed and is_sprinting:
		is_sprinting = false
		sprint_ended.emit()


func _input(event: InputEvent) -> void:
	if not is_local_player:
		return

	# Handle mouse motion for look
	if event is InputEventMouseMotion:
		look_input.emit(event.relative * mouse_sensitivity)

	# Handle interact button
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	elif event.is_action_released("interact"):
		interact_released.emit()

	# Handle jump button
	if event.is_action_pressed("jump"):
		jump_pressed.emit()

	# Handle escape to release mouse (for debugging/menu access)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func get_movement_direction() -> Vector3:
	return movement_direction


func is_moving() -> bool:
	return movement_direction.length_squared() > 0.01


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func is_mouse_captured() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
