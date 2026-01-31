extends Weapon
class_name Bow
## Bow - Ranged weapon with charge mechanic
## Limited ammo, charge for more damage, fires projectiles

# Bow-specific configuration
@export_group("Bow Settings")
@export var projectile_scene: PackedScene
@export var min_charge_time: float = 0.1  # Minimum charge before firing
@export var max_charge_time: float = 1.5  # Full charge time
@export var min_damage_multiplier: float = 0.5  # Damage at no charge
@export var max_damage_multiplier: float = 2.0  # Damage at full charge
@export var min_projectile_speed: float = 300.0
@export var max_projectile_speed: float = 600.0
@export var arrow_spawn_offset: float = 20.0  # How far from player to spawn arrow

# Internal state
var _is_charging: bool = false
var _charge_time: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT

# Node references
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var charge_indicator: Node2D = $ChargeIndicator if has_node("ChargeIndicator") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

# Preload default projectile if not set
var _default_projectile_path = "res://src/combat/Projectile.tscn"


func _ready() -> void:
	super._ready()

	# Configure weapon properties for bow
	weapon_name = "Bow"
	weapon_type = WeaponType.RANGED
	damage = 15  # Base damage (modified by charge)
	fire_rate = 1.5  # Shots per second (not counting charge time)
	attack_range = 400.0  # Max projectile range
	knockback_force = 50.0
	uses_ammo = true
	max_ammo = 15
	current_ammo = 15
	reload_time = 2.0

	# Load default projectile if none set
	if not projectile_scene:
		if ResourceLoader.exists(_default_projectile_path):
			projectile_scene = load(_default_projectile_path)

	print("[Bow] Initialized with %d arrows" % current_ammo)


func _process(delta: float) -> void:
	super._process(delta)

	# Update charge
	if _is_charging:
		_update_charge(delta)


func _update_charge(delta: float) -> void:
	_charge_time += delta
	_charge_time = minf(_charge_time, max_charge_time)

	# Update charge indicator visual
	if charge_indicator:
		var charge_percent = get_charge_percent()
		charge_indicator.scale = Vector2.ONE * (0.5 + charge_percent * 0.5)

		# Color from yellow to red at full charge
		if charge_indicator is Sprite2D or charge_indicator.has_method("set_modulate"):
			var color = Color.YELLOW.lerp(Color.RED, charge_percent)
			charge_indicator.modulate = color

	# Rotate to face charge direction
	rotation = _charge_direction.angle()


# Charge system

func start_charge(direction: Vector2 = Vector2.RIGHT) -> bool:
	"""
	Start charging the bow. Call release_charge() to fire.
	Returns true if charge started successfully.
	"""
	if not can_attack():
		return false

	if _is_charging:
		return false

	_is_charging = true
	_charge_time = 0.0
	_charge_direction = direction.normalized()
	if _charge_direction == Vector2.ZERO:
		_charge_direction = Vector2.RIGHT

	# Play draw animation
	if animation_player and animation_player.has_animation("draw"):
		animation_player.play("draw")

	# Show charge indicator
	if charge_indicator:
		charge_indicator.visible = true

	print("[Bow] Started charging")
	return true


func update_charge_direction(direction: Vector2) -> void:
	"""
	Update the aim direction while charging.
	"""
	if not _is_charging:
		return

	_charge_direction = direction.normalized()
	if _charge_direction == Vector2.ZERO:
		_charge_direction = Vector2.RIGHT

	rotation = _charge_direction.angle()


func release_charge() -> bool:
	"""
	Release the charged shot. Returns true if projectile was fired.
	"""
	if not _is_charging:
		return false

	var can_fire = _charge_time >= min_charge_time and current_ammo > 0

	_is_charging = false

	# Hide charge indicator
	if charge_indicator:
		charge_indicator.visible = false

	if not can_fire:
		print("[Bow] Charge cancelled (insufficient charge or ammo)")
		return false

	# Fire the charged shot
	return attack(_charge_direction)


func cancel_charge() -> void:
	"""
	Cancel the current charge without firing.
	"""
	_is_charging = false
	_charge_time = 0.0

	if charge_indicator:
		charge_indicator.visible = false

	if animation_player:
		animation_player.stop()

	rotation = 0


func get_charge_percent() -> float:
	"""
	Returns charge progress from 0.0 to 1.0
	"""
	if max_charge_time <= 0:
		return 1.0
	return clampf(_charge_time / max_charge_time, 0.0, 1.0)


func is_charging() -> bool:
	return _is_charging


func _attack(direction: Vector2) -> void:
	# Calculate charged damage and speed
	var charge_percent = get_charge_percent()
	var damage_multiplier = lerpf(min_damage_multiplier, max_damage_multiplier, charge_percent)
	var projectile_speed = lerpf(min_projectile_speed, max_projectile_speed, charge_percent)
	var final_damage = roundi(damage * damage_multiplier)

	# Spawn projectile
	_spawn_projectile(direction, final_damage, projectile_speed)

	# Reset charge
	_charge_time = 0.0

	# Play release animation
	if animation_player and animation_player.has_animation("release"):
		animation_player.play("release")

	# Reset rotation
	rotation = 0

	_on_attack_finished()

	print("[Bow] Fired arrow with %d damage (%.0f%% charge)" % [final_damage, charge_percent * 100])


func _spawn_projectile(direction: Vector2, projectile_damage: int, speed: float) -> void:
	if not projectile_scene:
		push_warning("[Bow] No projectile scene assigned")
		return

	# Create projectile instance
	var projectile = projectile_scene.instantiate()

	# Configure projectile
	if projectile.has_method("setup"):
		projectile.setup(owner_id, direction, projectile_damage, speed, attack_range, knockback_force)
	else:
		# Manual configuration if no setup method
		if "owner_id" in projectile:
			projectile.owner_id = owner_id
		if "direction" in projectile:
			projectile.direction = direction
		if "damage" in projectile:
			projectile.damage = projectile_damage
		if "speed" in projectile:
			projectile.speed = speed
		if "max_range" in projectile:
			projectile.max_range = attack_range

	# Position projectile
	var spawn_pos = global_position + direction * arrow_spawn_offset
	projectile.global_position = spawn_pos
	projectile.rotation = direction.angle()

	# Add to scene tree
	var projectiles_parent = _get_projectiles_parent()
	projectiles_parent.add_child(projectile)

	# Sync projectile spawn in multiplayer
	if multiplayer and multiplayer.has_multiplayer_peer():
		_sync_projectile_spawn.rpc(spawn_pos, direction, projectile_damage, speed)


func _get_projectiles_parent() -> Node:
	# Try to find a dedicated projectiles container
	var root = get_tree().current_scene
	if root:
		var container = root.get_node_or_null("Projectiles")
		if container:
			return container

	# Fallback to scene root
	return get_tree().current_scene if get_tree().current_scene else get_tree().root


# Network sync

@rpc("any_peer", "call_local", "reliable")
func _sync_projectile_spawn(spawn_pos: Vector2, direction: Vector2, projectile_damage: int, speed: float) -> void:
	"""
	Sync projectile spawn to other clients.
	"""
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == multiplayer.get_unique_id():
		return  # Don't spawn duplicate on sender

	if not projectile_scene:
		return

	# Create visual-only projectile on other clients
	var projectile = projectile_scene.instantiate()

	if projectile.has_method("setup"):
		# Mark as non-authoritative (won't deal damage on this client)
		projectile.setup(owner_id, direction, projectile_damage, speed, attack_range, knockback_force)
		if "is_authority" in projectile:
			projectile.is_authority = false

	projectile.global_position = spawn_pos
	projectile.rotation = direction.angle()

	var projectiles_parent = _get_projectiles_parent()
	projectiles_parent.add_child(projectile)


@rpc("any_peer", "call_local", "unreliable")
func _sync_charge_state(is_charging: bool, charge_time: float, direction: Vector2) -> void:
	"""
	Sync charge state to other players for visual feedback.
	"""
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == multiplayer.get_unique_id():
		return

	_is_charging = is_charging
	_charge_time = charge_time
	_charge_direction = direction

	if charge_indicator:
		charge_indicator.visible = is_charging

	rotation = direction.angle() if is_charging else 0


# Override to sync charge state

func start_charge(direction: Vector2 = Vector2.RIGHT) -> bool:
	var result = super.start_charge(direction)

	if result and multiplayer and multiplayer.has_multiplayer_peer():
		_sync_charge_state.rpc(true, 0.0, direction)

	return result


func cancel_charge() -> void:
	super.cancel_charge()

	if multiplayer and multiplayer.has_multiplayer_peer():
		_sync_charge_state.rpc(false, 0.0, Vector2.ZERO)
