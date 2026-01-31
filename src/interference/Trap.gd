extends Area3D
class_name Trap
## Trap - Placeable trap that interferes with opponents
## Can slow, damage, or disorient players who trigger it

signal trap_triggered(victim_id: int, trap_type: TrapType)
signal trap_expired()

enum TrapType {
	SLOW,       # Slows movement
	STUN,       # Brief stun
	BLIND,      # Screen flash
	REVERSE,    # Reverses controls briefly
	DAMAGE      # Deals damage
}

@export var trap_type: TrapType = TrapType.SLOW
@export var duration: float = 3.0  # Effect duration
@export var intensity: float = 0.5  # Effect strength (0-1)
@export var lifetime: float = 60.0  # How long trap exists
@export var owner_player_id: int = -1  # Who placed this trap

# Visual
var mesh: MeshInstance3D = null
var is_active: bool = true
var time_alive: float = 0.0

# Trap colors by type
const TRAP_COLORS: Dictionary = {
	TrapType.SLOW: Color(0.2, 0.2, 0.8, 0.5),     # Blue
	TrapType.STUN: Color(0.8, 0.8, 0.2, 0.5),     # Yellow
	TrapType.BLIND: Color(0.8, 0.8, 0.8, 0.5),    # White
	TrapType.REVERSE: Color(0.8, 0.2, 0.8, 0.5),  # Purple
	TrapType.DAMAGE: Color(0.8, 0.2, 0.2, 0.5)    # Red
}


func _ready() -> void:
	_setup_visuals()
	_setup_collision()

	body_entered.connect(_on_body_entered)

	# Add to traps group
	add_to_group("traps")


func _process(delta: float) -> void:
	if not is_active:
		return

	time_alive += delta

	# Expire after lifetime
	if time_alive >= lifetime:
		expire()
		return

	# Pulsing animation
	if mesh:
		var pulse = 0.8 + sin(time_alive * 4) * 0.2
		mesh.scale = Vector3(pulse, 0.1, pulse)


func _setup_visuals() -> void:
	# Create visual indicator (flat disc)
	mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 0.1
	mesh.mesh = cylinder

	# Material with trap color
	var material = StandardMaterial3D.new()
	material.albedo_color = TRAP_COLORS.get(trap_type, Color.RED)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = TRAP_COLORS.get(trap_type, Color.RED)
	material.emission_energy_multiplier = 2.0
	mesh.material_override = material

	add_child(mesh)


func _setup_collision() -> void:
	# Create collision shape
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 1.0
	collision.shape = shape
	add_child(collision)

	# Set collision layers
	collision_layer = 0
	collision_mask = 1  # Detect players


func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	# Don't trigger on owner
	var body_player_id = -1
	if body.has_method("get_player_id"):
		body_player_id = body.get_player_id()
	elif "player_id" in body:
		body_player_id = body.player_id

	if body_player_id == owner_player_id:
		return

	# Must be a player
	if not body.is_in_group("players") and not body is CharacterBody3D:
		return

	print("[Trap] Triggered by player %d (type: %s)" % [body_player_id, TrapType.keys()[trap_type]])

	# Apply effect
	_apply_effect(body, body_player_id)

	# Notify
	trap_triggered.emit(body_player_id, trap_type)

	# Single-use trap
	expire()


func _apply_effect(target: Node3D, player_id: int) -> void:
	match trap_type:
		TrapType.SLOW:
			_apply_slow(target)
		TrapType.STUN:
			_apply_stun(target)
		TrapType.BLIND:
			_apply_blind(target)
		TrapType.REVERSE:
			_apply_reverse(target)
		TrapType.DAMAGE:
			_apply_damage(target, player_id)


func _apply_slow(target: Node3D) -> void:
	# Reduce movement speed
	if "move_speed" in target:
		var original_speed = target.move_speed
		target.move_speed *= (1.0 - intensity)

		# Restore after duration
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(target) and "move_speed" in target:
				target.move_speed = original_speed
		)


func _apply_stun(target: Node3D) -> void:
	# Disable input briefly
	if target.has_method("set_input_enabled"):
		target.set_input_enabled(false)
		get_tree().create_timer(duration * intensity).timeout.connect(func():
			if is_instance_valid(target) and target.has_method("set_input_enabled"):
				target.set_input_enabled(true)
		)


func _apply_blind(target: Node3D) -> void:
	# Flash screen white (handled by HUD)
	if target.has_method("apply_screen_effect"):
		target.apply_screen_effect("blind", duration)


func _apply_reverse(target: Node3D) -> void:
	# Reverse controls
	if target.has_method("set_controls_reversed"):
		target.set_controls_reversed(true)
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(target) and target.has_method("set_controls_reversed"):
				target.set_controls_reversed(false)
		)


func _apply_damage(target: Node3D, player_id: int) -> void:
	# Deal damage via CombatSystem
	var damage = int(20 * intensity)
	var combat = get_node_or_null("/root/CombatSystem")
	if combat and combat.has_method("deal_damage"):
		combat.deal_damage(owner_player_id, player_id, damage)


func expire() -> void:
	is_active = false
	trap_expired.emit()

	# Fade out and remove
	var tween = create_tween()
	if mesh:
		tween.tween_property(mesh, "transparency", 1.0, 0.5)
	tween.tween_callback(queue_free)


## Create and place a trap at position
static func place_trap(trap_type: TrapType, position: Vector3, owner_id: int, parent: Node) -> Trap:
	var trap = Trap.new()
	trap.trap_type = trap_type
	trap.owner_player_id = owner_id
	trap.global_position = position
	parent.add_child(trap)
	return trap
