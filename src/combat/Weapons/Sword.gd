extends Weapon
class_name Sword
## Sword - Melee weapon with swing attack
## High damage, short range, cooldown between swings

# Sword-specific configuration
@export_group("Sword Settings")
@export var swing_duration: float = 0.3  # Duration of swing animation
@export var swing_arc: float = 120.0  # Arc of the swing in degrees
@export var hitbox_width: float = 30.0
@export var hitbox_height: float = 50.0

# Internal state
var _swing_timer: float = 0.0
var _swing_direction: Vector2 = Vector2.RIGHT
var _hits_this_swing: Array[int] = []  # Track which players we've hit this swing

# Node references
@onready var hitbox_area: Area2D = $HitboxArea
@onready var hitbox_shape: CollisionShape2D = $HitboxArea/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null


func _ready() -> void:
	super._ready()

	# Configure weapon properties for sword
	weapon_name = "Sword"
	weapon_type = WeaponType.MELEE
	damage = 25
	fire_rate = 2.0  # 2 swings per second
	attack_range = 50.0
	knockback_force = 150.0
	uses_ammo = false

	# Setup hitbox
	_setup_hitbox()

	# Connect hitbox signals
	if hitbox_area:
		hitbox_area.body_entered.connect(_on_hitbox_body_entered)
		hitbox_area.monitoring = false  # Disable until attacking

	print("[Sword] Initialized")


func _setup_hitbox() -> void:
	if not hitbox_shape:
		return

	# Create rectangular hitbox for sword swing
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(hitbox_width, hitbox_height)
	hitbox_shape.shape = rect_shape

	# Position hitbox in front of player
	if hitbox_area:
		hitbox_area.position = Vector2(attack_range / 2, 0)


func _process(delta: float) -> void:
	super._process(delta)

	# Update swing animation
	if _is_attacking:
		_update_swing(delta)


func _update_swing(delta: float) -> void:
	_swing_timer += delta

	# Calculate swing progress (0 to 1)
	var progress = _swing_timer / swing_duration

	if progress >= 1.0:
		_finish_swing()
		return

	# Rotate hitbox through swing arc
	var start_angle = -swing_arc / 2
	var current_angle = start_angle + (swing_arc * progress)

	# Apply rotation based on swing direction
	var base_rotation = _swing_direction.angle()
	rotation = base_rotation + deg_to_rad(current_angle)


func _attack(direction: Vector2) -> void:
	_swing_direction = direction.normalized()
	if _swing_direction == Vector2.ZERO:
		_swing_direction = Vector2.RIGHT

	_swing_timer = 0.0
	_hits_this_swing.clear()

	# Enable hitbox during swing
	if hitbox_area:
		hitbox_area.monitoring = true

	# Face the attack direction
	var base_rotation = _swing_direction.angle()
	rotation = base_rotation + deg_to_rad(-swing_arc / 2)

	# Play swing animation if available
	if animation_player and animation_player.has_animation("swing"):
		animation_player.play("swing")

	print("[Sword] Swing attack started in direction %s" % _swing_direction)


func _finish_swing() -> void:
	# Disable hitbox
	if hitbox_area:
		hitbox_area.monitoring = false

	# Reset rotation
	rotation = 0

	_on_attack_finished()
	print("[Sword] Swing finished, hit %d targets" % _hits_this_swing.size())


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _is_attacking:
		return

	# Check if it's a player
	if not body is CharacterBody2D:
		return

	if not body.has_method("get_player_id") and not "player_id" in body:
		return

	# Get target player ID
	var target_id: int
	if body.has_method("get_player_id"):
		target_id = body.get_player_id()
	else:
		target_id = body.player_id

	# Don't hit ourselves
	if target_id == owner_id:
		return

	# Don't hit same player twice in one swing
	if target_id in _hits_this_swing:
		return

	_hits_this_swing.append(target_id)

	# Deal damage through CombatSystem if available
	_deal_damage_to_player(target_id, body)


func _deal_damage_to_player(target_id: int, target_body: Node2D) -> void:
	# Try to find CombatSystem
	var combat_system = _get_combat_system()

	if combat_system:
		# Use CombatSystem for proper network sync
		if multiplayer and multiplayer.has_multiplayer_peer():
			combat_system.request_damage(owner_id, target_id, damage)
		else:
			combat_system.deal_damage(owner_id, target_id, damage)
	else:
		# Fallback: try direct damage method on player
		if target_body.has_method("take_damage"):
			target_body.take_damage(damage, owner_id)

	# Apply knockback
	_apply_knockback(target_body)

	print("[Sword] Hit player %d for %d damage" % [target_id, damage])


func _apply_knockback(target: Node2D) -> void:
	if knockback_force <= 0:
		return

	var knockback_direction = _swing_direction

	if target.has_method("apply_knockback"):
		target.apply_knockback(knockback_direction * knockback_force)
	elif "velocity" in target:
		target.velocity += knockback_direction * knockback_force


func _get_combat_system() -> Node:
	# Try to get CombatSystem from tree (autoload or parent)
	var combat = get_node_or_null("/root/CombatSystem")
	if combat:
		return combat

	# Try parent hierarchy
	var parent = get_parent()
	while parent:
		if parent.has_method("deal_damage"):
			return parent
		var child_combat = parent.get_node_or_null("CombatSystem")
		if child_combat:
			return child_combat
		parent = parent.get_parent()

	return null


# Network sync for attack visualization

@rpc("any_peer", "call_local", "unreliable")
func sync_swing(direction: Vector2) -> void:
	"""
	Sync sword swing animation to other players.
	"""
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		return  # Don't process our own RPC

	# Just play the animation, damage is handled by CombatSystem
	_swing_direction = direction
	_swing_timer = 0.0
	_is_attacking = true

	if hitbox_area:
		hitbox_area.monitoring = false  # Other clients don't do damage checks

	var base_rotation = _swing_direction.angle()
	rotation = base_rotation + deg_to_rad(-swing_arc / 2)

	if animation_player and animation_player.has_animation("swing"):
		animation_player.play("swing")


func attack(direction: Vector2 = Vector2.RIGHT) -> bool:
	var result = super.attack(direction)

	# Sync attack to other players
	if result and multiplayer and multiplayer.has_multiplayer_peer():
		sync_swing.rpc(direction)

	return result
