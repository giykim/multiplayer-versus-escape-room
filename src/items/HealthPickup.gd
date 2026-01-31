extends Item
class_name HealthPickup
## HealthPickup - Health restore item that heals the player
## Cannot overheal beyond max health

# Signal for health restored
signal health_restored(amount: int, player_id: int)

## Health Configuration
@export var heal_amount: int = 25
@export var heal_percentage: float = 0.0  # If > 0, heals this % of max health instead

## Health pickup size variants
enum HealthSize {
	SMALL,   # 15 HP
	MEDIUM,  # 25 HP
	LARGE    # 50 HP
}

## Visual Configuration
@export var health_size: HealthSize = HealthSize.MEDIUM
@export var pulse_effect: bool = true
@export var heal_particles: bool = true
@export var particle_count: int = 6

## Health values by size
const HEALTH_VALUES = {
	HealthSize.SMALL: 15,
	HealthSize.MEDIUM: 25,
	HealthSize.LARGE: 50
}

## Health colors - red/pink theme
const HEALTH_COLORS = {
	HealthSize.SMALL: Color(0.9, 0.4, 0.4),      # Light red
	HealthSize.MEDIUM: Color(1.0, 0.3, 0.3),     # Red
	HealthSize.LARGE: Color(1.0, 0.2, 0.5)       # Bright red/pink
}

## Health scales
const HEALTH_SCALES = {
	HealthSize.SMALL: Vector2(0.8, 0.8),
	HealthSize.MEDIUM: Vector2(1.0, 1.0),
	HealthSize.LARGE: Vector2(1.3, 1.3)
}

## Reference to visual elements
var placeholder: ColorRect
var cross_v: ColorRect
var cross_h: ColorRect


func _item_ready() -> void:
	item_type = "health"

	# Set heal amount based on size
	if heal_percentage <= 0:
		heal_amount = HEALTH_VALUES[health_size]

	item_name = _get_health_name()
	value = heal_amount

	# Setup visual
	_setup_health_visual()

	# Setup glow (green/healing theme)
	glow_color = Color(0.3, 1.0, 0.5, 0.5)
	glow_intensity = 1.4


func _setup_health_visual() -> void:
	# Get or create placeholder
	placeholder = get_node_or_null("Sprite2D/Placeholder")
	if not placeholder:
		if sprite:
			placeholder = ColorRect.new()
			placeholder.name = "Placeholder"
			sprite.add_child(placeholder)

	if placeholder:
		# Health pickup is a cross/plus shape represented as a rounded rect
		var base_size = 28.0
		match health_size:
			HealthSize.SMALL:
				base_size = 22.0
			HealthSize.MEDIUM:
				base_size = 28.0
			HealthSize.LARGE:
				base_size = 36.0

		placeholder.size = Vector2(base_size, base_size)
		placeholder.position = -placeholder.size / 2
		placeholder.color = HEALTH_COLORS[health_size]

	# Create cross shape overlay
	_create_cross_shape()

	# Apply scale
	scale = HEALTH_SCALES[health_size]


func _create_cross_shape() -> void:
	if not sprite:
		return

	# Vertical part of cross
	cross_v = get_node_or_null("Sprite2D/CrossV")
	if not cross_v:
		cross_v = ColorRect.new()
		cross_v.name = "CrossV"
		sprite.add_child(cross_v)

	# Horizontal part of cross
	cross_h = get_node_or_null("Sprite2D/CrossH")
	if not cross_h:
		cross_h = ColorRect.new()
		cross_h.name = "CrossH"
		sprite.add_child(cross_h)

	# Size the cross
	var cross_width = 8.0
	var cross_length = 20.0

	match health_size:
		HealthSize.SMALL:
			cross_width = 6.0
			cross_length = 16.0
		HealthSize.MEDIUM:
			cross_width = 8.0
			cross_length = 20.0
		HealthSize.LARGE:
			cross_width = 10.0
			cross_length = 26.0

	# White cross on top
	var cross_color = Color(1.0, 1.0, 1.0)

	cross_v.size = Vector2(cross_width, cross_length)
	cross_v.position = -cross_v.size / 2
	cross_v.color = cross_color

	cross_h.size = Vector2(cross_length, cross_width)
	cross_h.position = -cross_h.size / 2
	cross_h.color = cross_color


func _get_health_name() -> String:
	match health_size:
		HealthSize.SMALL:
			return "Small Health Pack"
		HealthSize.MEDIUM:
			return "Health Pack"
		HealthSize.LARGE:
			return "Large Health Pack"
	return "Health Pack"


func _on_pickup(player_id: int) -> void:
	# Find the player and heal them
	var actual_heal = _heal_player(player_id)

	if actual_heal > 0:
		health_restored.emit(actual_heal, player_id)
		print("[HealthPickup] Player %d healed for %d HP" % [player_id, actual_heal])
	else:
		print("[HealthPickup] Player %d picked up %s but was already at full health" % [player_id, item_name])


func _heal_player(player_id: int) -> int:
	# Find player node
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get_player_id") and player.get_player_id() == player_id:
			return _apply_heal_to_player(player)

	# Fallback: try to heal via GameManager if player has health there
	return _heal_via_game_manager(player_id)


func _apply_heal_to_player(player: Node) -> int:
	var current_health: int = 0
	var max_health: int = 100

	# Try to get current health
	if player.has_method("get_health"):
		current_health = player.get_health()
	elif player.get("health") != null:
		current_health = player.get("health")
	elif player.get("current_health") != null:
		current_health = player.get("current_health")
	else:
		# No health system found, assume heal works
		return heal_amount

	# Try to get max health
	if player.has_method("get_max_health"):
		max_health = player.get_max_health()
	elif player.get("max_health") != null:
		max_health = player.get("max_health")

	# Calculate actual heal (don't overheal)
	var heal_value = heal_amount
	if heal_percentage > 0:
		heal_value = int(max_health * heal_percentage / 100.0)

	var actual_heal = mini(heal_value, max_health - current_health)

	if actual_heal <= 0:
		return 0

	# Apply heal
	var new_health = current_health + actual_heal

	if player.has_method("set_health"):
		player.set_health(new_health)
	elif player.has_method("heal"):
		player.heal(actual_heal)
	elif player.get("health") != null:
		player.set("health", new_health)
	elif player.get("current_health") != null:
		player.set("current_health", new_health)

	return actual_heal


func _heal_via_game_manager(player_id: int) -> int:
	# This is a fallback if player node doesn't have health
	# GameManager doesn't track health by default, but could be extended
	return heal_amount


func _play_pickup_effect() -> void:
	# Spawn heal particles
	if heal_particles:
		_spawn_heal_particles()

	# Play the default pickup effect with green tint
	_heal_pickup_effect()


func _heal_pickup_effect() -> void:
	# Create a healing-themed tween animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Scale up and flash green
	tween.tween_property(self, "scale", scale * 1.6, 0.2)
	tween.tween_property(self, "modulate", Color(0.5, 1.5, 0.5, 1.0), 0.1)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _spawn_heal_particles() -> void:
	for i in particle_count:
		var particle = _create_heal_particle()
		get_parent().add_child(particle)
		particle.global_position = global_position

		# Particles rise up
		var x_offset = randf_range(-30, 30)
		var rise_height = randf_range(40, 80)

		var tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y - rise_height, 0.6)
		tween.tween_property(particle, "position:x", particle.position.x + x_offset, 0.6)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6).set_delay(0.2)
		tween.chain().tween_callback(particle.queue_free)


func _create_heal_particle() -> Node2D:
	var particle = Node2D.new()

	# Small plus sign particle
	var v_line = ColorRect.new()
	v_line.size = Vector2(4, 12)
	v_line.position = -v_line.size / 2
	v_line.color = Color(0.5, 1.0, 0.5, 0.9)
	particle.add_child(v_line)

	var h_line = ColorRect.new()
	h_line.size = Vector2(12, 4)
	h_line.position = -h_line.size / 2
	h_line.color = Color(0.5, 1.0, 0.5, 0.9)
	particle.add_child(h_line)

	particle.scale = Vector2(randf_range(0.5, 1.0), randf_range(0.5, 1.0))

	return particle


## Set health size (can be called before adding to scene tree)
func set_health_size(size: HealthSize) -> void:
	health_size = size
	if is_inside_tree():
		heal_amount = HEALTH_VALUES[health_size]
		item_name = _get_health_name()
		value = heal_amount
		_setup_health_visual()


## Static helper to create a health pickup
static func create_health(size: HealthSize) -> HealthPickup:
	var health_scene = preload("res://src/items/HealthPickup.tscn")
	var health = health_scene.instantiate() as HealthPickup
	health.set_health_size(size)
	return health
