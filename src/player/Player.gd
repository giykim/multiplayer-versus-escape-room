extends CharacterBody2D
class_name Player
## Player - Character controller with movement, interaction, and network sync
## 2D top-down movement with smooth acceleration and interaction system

# Interaction signals
signal interaction_started(interactable: Node2D)
signal interaction_ended(interactable: Node2D)
signal interaction_triggered(interactable: Node2D)

# Movement signals
signal movement_started()
signal movement_stopped()

# Player state signals
signal player_ready()

## Movement Configuration
@export_group("Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

## Interaction Configuration
@export_group("Interaction")
@export var interaction_enabled: bool = true

## Network Configuration
@export_group("Network")
@export var player_id: int = 1

## Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var player_input: PlayerInput = $PlayerInput

## Internal state
var _current_velocity: Vector2 = Vector2.ZERO
var _input_direction: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _nearby_interactables: Array[Node2D] = []
var _current_interactable: Node2D = null
var _is_local_player: bool = true


func _ready() -> void:
	# Determine if this is the local player
	_setup_multiplayer_authority()

	# Connect input signals
	if player_input:
		player_input.movement_input_changed.connect(_on_movement_input_changed)
		player_input.interact_pressed.connect(_on_interact_pressed)

	# Connect interaction area signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)
		interaction_area.area_entered.connect(_on_interaction_area_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_area_exited)

	# Setup camera for local player only
	_setup_camera()

	# Apply player color if available from GameManager
	_apply_player_color()

	print("[Player] Initialized (ID: %d, Local: %s)" % [player_id, _is_local_player])
	player_ready.emit()


func _setup_multiplayer_authority() -> void:
	# Check if we're in a multiplayer context
	if multiplayer.has_multiplayer_peer():
		# Set multiplayer authority based on player_id
		set_multiplayer_authority(player_id)
		_is_local_player = is_multiplayer_authority()
	else:
		# Single player mode - always local
		_is_local_player = true

	# Configure input handler
	if player_input:
		player_input.set_local_player(_is_local_player)


func _setup_camera() -> void:
	if camera:
		# Only enable camera for local player
		camera.enabled = _is_local_player

		if _is_local_player:
			camera.make_current()


func _apply_player_color() -> void:
	# Try to get player color from GameManager
	if GameManager and GameManager.players.has(player_id):
		var player_data = GameManager.get_player_data(player_id)
		if player_data and sprite:
			sprite.modulate = player_data.color
	elif sprite:
		# Default color based on player ID
		var default_colors = [
			Color(0.2, 0.6, 1.0),   # Blue
			Color(1.0, 0.3, 0.3),   # Red
			Color(0.3, 1.0, 0.3),   # Green
			Color(1.0, 1.0, 0.3),   # Yellow
		]
		var color_index = (player_id - 1) % default_colors.size()
		sprite.modulate = default_colors[color_index]


func _physics_process(delta: float) -> void:
	# Only process movement for local player or if we're not in multiplayer
	if not _is_local_player and multiplayer.has_multiplayer_peer():
		return

	_process_movement(delta)
	move_and_slide()

	# Update moving state
	var was_moving = _is_moving
	_is_moving = velocity.length_squared() > 1.0

	if _is_moving and not was_moving:
		movement_started.emit()
	elif not _is_moving and was_moving:
		movement_stopped.emit()


func _process_movement(delta: float) -> void:
	var target_velocity = _input_direction * move_speed

	if _input_direction.length_squared() > 0.01:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _on_movement_input_changed(direction: Vector2) -> void:
	_input_direction = direction


func _on_interact_pressed() -> void:
	if not interaction_enabled:
		return

	_try_interact()


func _try_interact() -> void:
	# Find the best interactable (closest one)
	var best_interactable = _get_closest_interactable()

	if best_interactable:
		_current_interactable = best_interactable
		interaction_triggered.emit(best_interactable)

		# Call interact method if it exists on the interactable
		if best_interactable.has_method("interact"):
			best_interactable.interact(self)
		elif best_interactable.has_method("on_interact"):
			best_interactable.on_interact(self)


func _get_closest_interactable() -> Node2D:
	if _nearby_interactables.is_empty():
		return null

	var closest: Node2D = null
	var closest_distance: float = INF

	for interactable in _nearby_interactables:
		if not is_instance_valid(interactable):
			continue

		var distance = global_position.distance_to(interactable.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = interactable

	return closest


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if _is_interactable(body) and body not in _nearby_interactables:
		_nearby_interactables.append(body)
		interaction_started.emit(body)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body in _nearby_interactables:
		_nearby_interactables.erase(body)
		interaction_ended.emit(body)


func _on_interaction_area_area_entered(area: Area2D) -> void:
	# Also detect Area2D based interactables
	if _is_interactable(area) and area not in _nearby_interactables:
		_nearby_interactables.append(area)
		interaction_started.emit(area)


func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area in _nearby_interactables:
		_nearby_interactables.erase(area)
		interaction_ended.emit(area)


func _is_interactable(node: Node) -> bool:
	# Check if the node is interactable
	if node.is_in_group("interactable"):
		return true
	if node.has_method("interact") or node.has_method("on_interact"):
		return true
	if node.get("is_interactable"):
		return true
	return false


# Public API

func set_player_id(id: int) -> void:
	player_id = id
	_setup_multiplayer_authority()
	_apply_player_color()


func get_player_id() -> int:
	return player_id


func is_local_player() -> bool:
	return _is_local_player


func is_moving() -> bool:
	return _is_moving


func get_nearby_interactables() -> Array[Node2D]:
	return _nearby_interactables.duplicate()


func has_interactable_nearby() -> bool:
	return not _nearby_interactables.is_empty()


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled


func teleport_to(new_position: Vector2) -> void:
	global_position = new_position
	velocity = Vector2.ZERO


# Network synchronization (to be called by network sync system)

func get_sync_state() -> Dictionary:
	return {
		"position": global_position,
		"velocity": velocity,
		"is_moving": _is_moving,
	}


func apply_sync_state(state: Dictionary) -> void:
	if state.has("position"):
		global_position = state.position
	if state.has("velocity"):
		velocity = state.velocity
	if state.has("is_moving"):
		_is_moving = state.is_moving
