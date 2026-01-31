extends Area2D
class_name Projectile
## Projectile - Base projectile for ranged weapons
## Moves in a direction, deals damage on collision, despawns after range/time

# Signals
signal hit_target(target_id: int)
signal projectile_destroyed()

# Configuration
@export_group("Projectile Settings")
@export var speed: float = 400.0
@export var damage: int = 10
@export var max_range: float = 500.0
@export var max_lifetime: float = 5.0  # Safety timeout
@export var knockback_force: float = 50.0
@export var pierce_count: int = 0  # 0 = destroy on first hit, 1+ = pierce through enemies

@export_group("Visuals")
@export var trail_enabled: bool = true
@export var destroy_effect_scene: PackedScene = null

# Runtime state
var owner_id: int = 0
var direction: Vector2 = Vector2.RIGHT
var is_authority: bool = true  # Only authority deals damage
var _distance_traveled: float = 0.0
var _lifetime: float = 0.0
var _hits_remaining: int = 0
var _hit_targets: Array[int] = []  # Track which players we've hit
var _start_position: Vector2

# Node references
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var trail: GPUParticles2D = $Trail if has_node("Trail") else null


func _ready() -> void:
	_start_position = global_position
	_hits_remaining = pierce_count + 1  # +1 because first hit counts

	# Connect collision signal
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Setup trail
	if trail and trail_enabled:
		trail.emitting = true
	elif trail:
		trail.emitting = false

	# Ensure proper collision
	monitoring = is_authority  # Only check collisions if we're the authority
	monitorable = true  # Always visible to other collision checks


func _physics_process(delta: float) -> void:
	# Update lifetime
	_lifetime += delta
	if _lifetime >= max_lifetime:
		_destroy()
		return

	# Move projectile
	var movement = direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()

	# Check range limit
	if _distance_traveled >= max_range:
		_destroy()
		return


func setup(projectile_owner_id: int, fire_direction: Vector2, projectile_damage: int,
		   projectile_speed: float, projectile_range: float, projectile_knockback: float = 50.0) -> void:
	"""
	Configure the projectile with all necessary parameters.
	"""
	owner_id = projectile_owner_id
	direction = fire_direction.normalized()
	damage = projectile_damage
	speed = projectile_speed
	max_range = projectile_range
	knockback_force = projectile_knockback

	# Update rotation to match direction
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if not is_authority:
		return

	# Check if it's a player
	if body is CharacterBody2D:
		_handle_player_collision(body)
	else:
		# Hit a wall or other obstacle
		_handle_obstacle_collision(body)


func _on_area_entered(area: Area2D) -> void:
	if not is_authority:
		return

	# Check for hurtbox areas on players
	var parent = area.get_parent()
	if parent and parent is CharacterBody2D:
		_handle_player_collision(parent)


func _handle_player_collision(body: Node2D) -> void:
	# Get target player ID
	var target_id: int = -1

	if body.has_method("get_player_id"):
		target_id = body.get_player_id()
	elif "player_id" in body:
		target_id = body.player_id
	else:
		return  # Not a player

	# Don't hit owner
	if target_id == owner_id:
		return

	# Don't hit same target twice
	if target_id in _hit_targets:
		return

	_hit_targets.append(target_id)

	# Deal damage
	_deal_damage(target_id, body)

	hit_target.emit(target_id)

	# Check pierce
	_hits_remaining -= 1
	if _hits_remaining <= 0:
		_destroy()


func _handle_obstacle_collision(body: Node2D) -> void:
	# Check if obstacle is in a collision layer we should stop at
	if body.is_in_group("projectile_pass"):
		return  # This obstacle allows projectiles through

	# Default: destroy on obstacle hit
	_destroy()


func _deal_damage(target_id: int, target_body: Node2D) -> void:
	# Try to find CombatSystem
	var combat_system = _get_combat_system()

	if combat_system:
		# Use CombatSystem for proper network sync
		if multiplayer.has_multiplayer_peer():
			combat_system.request_damage(owner_id, target_id, damage)
		else:
			combat_system.deal_damage(owner_id, target_id, damage)
	else:
		# Fallback: direct damage
		if target_body.has_method("take_damage"):
			target_body.take_damage(damage, owner_id)

	# Apply knockback
	_apply_knockback(target_body)

	print("[Projectile] Hit player %d for %d damage" % [target_id, damage])


func _apply_knockback(target: Node2D) -> void:
	if knockback_force <= 0:
		return

	if target.has_method("apply_knockback"):
		target.apply_knockback(direction * knockback_force)
	elif "velocity" in target:
		target.velocity += direction * knockback_force


func _get_combat_system() -> Node:
	# Try to get CombatSystem from autoload
	var combat = get_node_or_null("/root/CombatSystem")
	if combat:
		return combat

	# Try to find in scene
	var root = get_tree().current_scene
	if root:
		var combat_node = root.get_node_or_null("CombatSystem")
		if combat_node:
			return combat_node

	return null


func _destroy() -> void:
	# Spawn destroy effect if available
	if destroy_effect_scene:
		var effect = destroy_effect_scene.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)

	# Stop trail
	if trail:
		trail.emitting = false

	projectile_destroyed.emit()

	# Queue free (with small delay if trail needs to fade)
	if trail and trail_enabled:
		# Wait for trail to fade
		set_physics_process(false)
		monitoring = false
		if sprite:
			sprite.visible = false
		await get_tree().create_timer(trail.lifetime).timeout

	queue_free()


# Utility methods

func get_distance_traveled() -> float:
	return _distance_traveled


func get_remaining_range() -> float:
	return maxf(max_range - _distance_traveled, 0.0)


func get_lifetime() -> float:
	return _lifetime


# Allow external destruction (e.g., from shields or abilities)
func destroy() -> void:
	_destroy()
