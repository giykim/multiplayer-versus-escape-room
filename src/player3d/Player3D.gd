extends CharacterBody3D
class_name Player3D
## Player3D - First-person character controller with movement, interaction, and network sync
## 3D first-person movement with gravity, jumping, and raycast-based interaction

# Interaction signals
signal interaction_started(interactable: Node3D)
signal interaction_ended(interactable: Node3D)
signal interaction_triggered(interactable: Node3D)

# Movement signals
signal movement_started()
signal movement_stopped()

# Player state signals
signal player_ready()

## Movement Configuration
@export_group("Movement")
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var jump_velocity: float = 4.5

## Look Configuration
@export_group("Look")
@export var mouse_sensitivity: float = 0.002
@export var pitch_limit: float = 89.0  # Degrees

## Interaction Configuration
@export_group("Interaction")
@export var interaction_enabled: bool = true
@export var interaction_range: float = 3.0

## Network Configuration
@export_group("Network")
@export var player_id: int = 1

## Node references
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var player_input: PlayerInput3D = $PlayerInput3D

## Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## Internal state
var _input_direction: Vector3 = Vector3.ZERO
var _is_moving: bool = false
var _is_sprinting: bool = false
var _is_local_player: bool = true
var _current_interactable: Node3D = null
var _previous_interactable: Node3D = null


func _ready() -> void:
	# Determine if this is the local player
	_setup_multiplayer_authority()

	# Connect input signals
	if player_input:
		player_input.movement_input_changed.connect(_on_movement_input_changed)
		player_input.look_input.connect(_on_look_input)
		player_input.interact_pressed.connect(_on_interact_pressed)
		player_input.jump_pressed.connect(_on_jump_pressed)
		player_input.sprint_started.connect(_on_sprint_started)
		player_input.sprint_ended.connect(_on_sprint_ended)

		# Pass sensitivity to input handler
		player_input.mouse_sensitivity = mouse_sensitivity

	# Setup camera for local player only
	_setup_camera()

	# Setup interaction raycast
	_setup_interaction_ray()

	# Apply player color if available from GameManager
	_apply_player_color()

	print("[Player3D] Initialized (ID: %d, Local: %s)" % [player_id, _is_local_player])
	player_ready.emit()


func _setup_multiplayer_authority() -> void:
	# Check if we're in a multiplayer context
	if multiplayer and multiplayer.has_multiplayer_peer():
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
		camera.current = _is_local_player

		# Hide body mesh for local player (first-person view)
		if body_mesh and _is_local_player:
			body_mesh.visible = false


func _setup_interaction_ray() -> void:
	if interaction_ray:
		interaction_ray.target_position = Vector3(0, 0, -interaction_range)
		interaction_ray.enabled = true


func _apply_player_color() -> void:
	# Try to get player color from GameManager
	if GameManager and GameManager.players.has(player_id):
		var player_data = GameManager.get_player_data(player_id)
		if player_data and body_mesh:
			var material = StandardMaterial3D.new()
			material.albedo_color = player_data.color
			body_mesh.material_override = material
	elif body_mesh:
		# Default color based on player ID
		var default_colors = [
			Color(0.2, 0.6, 1.0),   # Blue
			Color(1.0, 0.3, 0.3),   # Red
			Color(0.3, 1.0, 0.3),   # Green
			Color(1.0, 1.0, 0.3),   # Yellow
		]
		var color_index = (player_id - 1) % default_colors.size()
		var material = StandardMaterial3D.new()
		material.albedo_color = default_colors[color_index]
		body_mesh.material_override = material


func _physics_process(delta: float) -> void:
	# Only process movement for local player or if we're not in multiplayer
	if not _is_local_player and multiplayer and multiplayer.has_multiplayer_peer():
		return

	_process_gravity(delta)
	_process_movement(delta)
	move_and_slide()

	# Update moving state
	var was_moving = _is_moving
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	_is_moving = horizontal_velocity.length_squared() > 0.1

	if _is_moving and not was_moving:
		movement_started.emit()
	elif not _is_moving and was_moving:
		movement_stopped.emit()

	# Check for interactables via raycast
	_process_interaction_ray()


func _process_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func _process_movement(delta: float) -> void:
	# Get the camera's forward and right directions (ignoring Y for horizontal movement)
	var forward = -head.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = head.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	# Calculate target velocity based on input direction relative to camera
	var target_direction = (forward * -_input_direction.z + right * _input_direction.x).normalized()
	var current_speed = sprint_speed if _is_sprinting else move_speed
	var target_velocity = target_direction * current_speed * _input_direction.length()

	# Horizontal movement with acceleration/friction
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if _input_direction.length_squared() > 0.01:
		# Accelerate towards target velocity
		horizontal_velocity = horizontal_velocity.lerp(target_velocity, acceleration * delta)
	else:
		# Apply friction when no input
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, friction * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


func _process_interaction_ray() -> void:
	if not interaction_ray or not interaction_enabled:
		return

	var new_interactable: Node3D = null

	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider is Node3D and _is_interactable(collider):
			new_interactable = collider

	# Handle interactable changes
	if new_interactable != _current_interactable:
		if _current_interactable:
			interaction_ended.emit(_current_interactable)

		_current_interactable = new_interactable

		if _current_interactable:
			interaction_started.emit(_current_interactable)


func _on_movement_input_changed(direction: Vector3) -> void:
	_input_direction = direction


func _on_look_input(mouse_motion: Vector2) -> void:
	if not _is_local_player:
		return

	# Rotate player (yaw) - rotate around Y axis
	rotate_y(-mouse_motion.x)

	# Rotate head (pitch) - rotate around X axis with clamping
	if head:
		head.rotate_x(-mouse_motion.y)
		# Clamp pitch to prevent over-rotation
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))


func _on_interact_pressed() -> void:
	if not interaction_enabled:
		return

	_try_interact()


func _on_jump_pressed() -> void:
	if is_on_floor():
		velocity.y = jump_velocity


func _on_sprint_started() -> void:
	_is_sprinting = true


func _on_sprint_ended() -> void:
	_is_sprinting = false


func _try_interact() -> void:
	if _current_interactable:
		interaction_triggered.emit(_current_interactable)

		# Call interact method if it exists on the interactable
		if _current_interactable.has_method("interact"):
			_current_interactable.interact(self)
		elif _current_interactable.has_method("on_interact"):
			_current_interactable.on_interact(self)


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


func is_sprinting() -> bool:
	return _is_sprinting


func get_current_interactable() -> Node3D:
	return _current_interactable


func has_interactable_in_view() -> bool:
	return _current_interactable != null


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled


func teleport_to(new_position: Vector3) -> void:
	global_position = new_position
	velocity = Vector3.ZERO


func set_look_direction(yaw: float, pitch: float) -> void:
	rotation.y = yaw
	if head:
		head.rotation.x = clamp(pitch, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))


func get_look_direction() -> Vector2:
	var pitch = head.rotation.x if head else 0.0
	return Vector2(rotation.y, pitch)


# Network synchronization (to be called by network sync system)

func get_sync_state() -> Dictionary:
	return {
		"position": global_position,
		"velocity": velocity,
		"rotation_y": rotation.y,
		"head_rotation_x": head.rotation.x if head else 0.0,
		"is_moving": _is_moving,
		"is_sprinting": _is_sprinting,
	}


func apply_sync_state(state: Dictionary) -> void:
	if state.has("position"):
		global_position = state.position
	if state.has("velocity"):
		velocity = state.velocity
	if state.has("rotation_y"):
		rotation.y = state.rotation_y
	if state.has("head_rotation_x") and head:
		head.rotation.x = state.head_rotation_x
	if state.has("is_moving"):
		_is_moving = state.is_moving
	if state.has("is_sprinting"):
		_is_sprinting = state.is_sprinting
