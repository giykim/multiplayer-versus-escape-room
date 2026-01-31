extends StaticBody3D
class_name PuzzleElement3D
## PuzzleElement3D - Interactable 3D puzzle piece
## Handles raycast detection, highlighting, and interaction

# Signals
signal element_activated(element: PuzzleElement3D)
signal element_highlighted(element: PuzzleElement3D, is_highlighted: bool)

# Element identification
@export var element_id: String = ""
@export var element_value: int = 0  # Generic value for puzzle logic

# Visual components
@export var mesh_instance: MeshInstance3D = null
@export var collision_shape: CollisionShape3D = null

# Highlight settings (can be overridden by parent puzzle)
@export var default_highlight_color: Color = Color(1.0, 0.8, 0.2)
@export var default_highlight_intensity: float = 0.5

# State
var is_highlighted: bool = false
var is_interactable: bool = true
var is_animating: bool = false

# Material references
var _original_material: Material = null
var _highlight_material: StandardMaterial3D = null


func _ready() -> void:
	# Generate element_id if not set
	if element_id.is_empty():
		element_id = "element_%d" % get_instance_id()

	# Add to interactable group for raycast detection
	add_to_group("interactable")

	# Set collision layer to 3 (bit 2 = value 4)
	collision_layer = 4
	collision_mask = 0  # Elements don't need to detect other collisions

	# Auto-find mesh instance if not set
	if not mesh_instance:
		for child in get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break

	# Store original material and create highlight material
	if mesh_instance and mesh_instance.mesh:
		_setup_materials()


func _setup_materials() -> void:
	if not mesh_instance:
		return

	# Get or create the surface material
	if mesh_instance.get_surface_override_material_count() > 0:
		_original_material = mesh_instance.get_surface_override_material(0)
	elif mesh_instance.mesh.get_surface_count() > 0:
		_original_material = mesh_instance.mesh.surface_get_material(0)

	# Create a copy for highlighting
	if _original_material:
		_highlight_material = _original_material.duplicate() as StandardMaterial3D
	else:
		# Create a default material if none exists
		_highlight_material = StandardMaterial3D.new()
		_highlight_material.albedo_color = Color(0.5, 0.5, 0.5)
		_original_material = _highlight_material.duplicate()

	# Ensure highlight material supports emission
	if _highlight_material:
		_highlight_material.emission_enabled = true
		_highlight_material.emission = Color.BLACK
		_highlight_material.emission_energy_multiplier = 0.0


## Set whether this element is highlighted (called by parent puzzle's raycast)
func set_highlighted(highlighted: bool, color: Color = Color.WHITE, intensity: float = 0.5) -> void:
	if not is_interactable:
		return

	is_highlighted = highlighted

	if mesh_instance and _highlight_material:
		if highlighted:
			# Apply emission glow
			_highlight_material.emission = color
			_highlight_material.emission_energy_multiplier = intensity
			mesh_instance.set_surface_override_material(0, _highlight_material)
		else:
			# Remove emission
			_highlight_material.emission = Color.BLACK
			_highlight_material.emission_energy_multiplier = 0.0
			if _original_material:
				mesh_instance.set_surface_override_material(0, _original_material)
			else:
				mesh_instance.set_surface_override_material(0, null)

	element_highlighted.emit(self, highlighted)


## Called when player interacts with this element (click/interact button)
func activate() -> void:
	if not is_interactable or is_animating:
		return

	print("[%s] Element activated" % element_id)
	element_activated.emit(self)

	_on_activated()


## Enable or disable interaction with this element
func set_interactable(interactable: bool) -> void:
	is_interactable = interactable

	if not interactable and is_highlighted:
		set_highlighted(false)


## Set the mesh for this element
func set_mesh(mesh: Mesh) -> void:
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)

	mesh_instance.mesh = mesh
	_setup_materials()


## Set the albedo color of the element
func set_color(color: Color) -> void:
	if _original_material and _original_material is StandardMaterial3D:
		(_original_material as StandardMaterial3D).albedo_color = color
	if _highlight_material:
		_highlight_material.albedo_color = color


## Flash feedback for invalid action
func flash_invalid() -> void:
	if is_animating:
		return

	is_animating = true
	var original_emission = _highlight_material.emission if _highlight_material else Color.BLACK

	var flash_tween = create_tween()
	if _highlight_material:
		flash_tween.tween_property(_highlight_material, "emission", Color.RED, 0.1)
		flash_tween.tween_property(_highlight_material, "emission", original_emission, 0.1)
	flash_tween.tween_callback(func(): is_animating = false)


## Flash feedback for valid action
func flash_valid() -> void:
	if is_animating:
		return

	is_animating = true
	var original_emission = _highlight_material.emission if _highlight_material else Color.BLACK

	var flash_tween = create_tween()
	if _highlight_material:
		flash_tween.tween_property(_highlight_material, "emission", Color.GREEN, 0.1)
		flash_tween.tween_property(_highlight_material, "emission", original_emission, 0.1)
	flash_tween.tween_callback(func(): is_animating = false)


## Celebratory animation when puzzle is solved
func celebrate() -> void:
	var celebrate_tween = create_tween()
	celebrate_tween.set_loops(2)
	celebrate_tween.tween_property(self, "scale", Vector3(1.1, 1.1, 1.1), 0.15)
	celebrate_tween.tween_property(self, "scale", Vector3.ONE, 0.15)


# === Virtual Methods (Override in subclasses) ===

## Called when element is activated - override for custom behavior
func _on_activated() -> void:
	pass
