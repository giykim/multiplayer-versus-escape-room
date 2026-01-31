extends Node
class_name PlayerInput
## PlayerInput - Handles input processing for local player
## Processes movement and interaction input, emits signals for Player to consume

signal movement_input_changed(direction: Vector2)
signal interact_pressed()
signal interact_released()

## Only process input if this is the local player
var is_local_player: bool = true

## Current movement direction (normalized)
var movement_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Input processing is enabled by default for local player
	set_process_input(is_local_player)
	set_physics_process(is_local_player)


func set_local_player(is_local: bool) -> void:
	is_local_player = is_local
	set_process_input(is_local)
	set_physics_process(is_local)

	if not is_local:
		movement_direction = Vector2.ZERO
		movement_input_changed.emit(movement_direction)


func _physics_process(_delta: float) -> void:
	if not is_local_player:
		return

	_process_movement_input()


func _process_movement_input() -> void:
	var new_direction = Vector2.ZERO

	# Get input from defined actions
	new_direction.x = Input.get_axis("move_left", "move_right")
	new_direction.y = Input.get_axis("move_up", "move_down")

	# Normalize diagonal movement to prevent faster diagonal speed
	if new_direction.length() > 1.0:
		new_direction = new_direction.normalized()

	# Only emit if direction changed to avoid unnecessary signals
	if new_direction != movement_direction:
		movement_direction = new_direction
		movement_input_changed.emit(movement_direction)


func _input(event: InputEvent) -> void:
	if not is_local_player:
		return

	# Handle interact button
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	elif event.is_action_released("interact"):
		interact_released.emit()


func get_movement_direction() -> Vector2:
	return movement_direction


func is_moving() -> bool:
	return movement_direction.length_squared() > 0.01
