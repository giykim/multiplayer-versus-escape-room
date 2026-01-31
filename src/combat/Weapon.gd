extends Node2D
class_name Weapon
## Weapon - Base class for all weapons
## Provides common properties and virtual methods for weapon implementations

# Weapon types
enum WeaponType {
	MELEE,
	RANGED,
	AREA
}

# Signals
signal attack_started()
signal attack_finished()
signal ammo_changed(current: int, max_ammo: int)
signal reloaded()

# Weapon configuration
@export_group("Weapon Stats")
@export var weapon_name: String = "Weapon"
@export var weapon_type: WeaponType = WeaponType.MELEE
@export var damage: int = 10
@export var fire_rate: float = 1.0  # Attacks per second
@export var attack_range: float = 50.0  # Range in pixels
@export var knockback_force: float = 100.0

@export_group("Ammo")
@export var uses_ammo: bool = false
@export var max_ammo: int = 10
@export var current_ammo: int = 10
@export var reload_time: float = 1.0

@export_group("Network")
@export var owner_id: int = 0  # Player ID who owns this weapon

# Internal state
var _can_attack: bool = true
var _is_attacking: bool = false
var _is_reloading: bool = false
var _attack_cooldown_timer: float = 0.0
var _reload_timer: float = 0.0

# Reference to the owning player
var _owner_player: Node = null


func _ready() -> void:
	if uses_ammo:
		current_ammo = max_ammo


func _process(delta: float) -> void:
	_update_cooldown(delta)
	_update_reload(delta)


func _update_cooldown(delta: float) -> void:
	if _attack_cooldown_timer > 0:
		_attack_cooldown_timer -= delta
		if _attack_cooldown_timer <= 0:
			_can_attack = true


func _update_reload(delta: float) -> void:
	if _is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0:
			_finish_reload()


# Public API

func set_owner_player(player: Node) -> void:
	_owner_player = player
	if player and player.has_method("get_player_id"):
		owner_id = player.get_player_id()
	elif player and "player_id" in player:
		owner_id = player.player_id


func get_owner_player() -> Node:
	return _owner_player


func can_attack() -> bool:
	if not _can_attack:
		return false

	if _is_attacking:
		return false

	if _is_reloading:
		return false

	if uses_ammo and current_ammo <= 0:
		return false

	return true


func attack(direction: Vector2 = Vector2.RIGHT) -> bool:
	"""
	Attempt to perform an attack in the given direction.
	Returns true if the attack was initiated.
	"""
	if not can_attack():
		return false

	_can_attack = false
	_is_attacking = true
	_attack_cooldown_timer = 1.0 / fire_rate

	if uses_ammo:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)

	attack_started.emit()

	# Call the virtual attack method
	_attack(direction)

	return true


func reload() -> bool:
	"""
	Attempt to reload the weapon.
	Returns true if reload was initiated.
	"""
	if not uses_ammo:
		return false

	if _is_reloading:
		return false

	if current_ammo >= max_ammo:
		return false

	_is_reloading = true
	_reload_timer = reload_time

	_reload()

	return true


func add_ammo(amount: int) -> void:
	"""
	Add ammo to the weapon (e.g., from pickup).
	"""
	if not uses_ammo:
		return

	current_ammo = mini(current_ammo + amount, max_ammo)
	ammo_changed.emit(current_ammo, max_ammo)


func set_ammo(amount: int) -> void:
	"""
	Set the current ammo amount directly.
	"""
	if not uses_ammo:
		return

	current_ammo = clampi(amount, 0, max_ammo)
	ammo_changed.emit(current_ammo, max_ammo)


# Virtual methods - Override in subclasses

func _attack(_direction: Vector2) -> void:
	"""
	Virtual method called when attack is performed.
	Override in weapon subclasses to implement specific attack behavior.
	"""
	# Default implementation - just end attack immediately
	_on_attack_finished()


func _reload() -> void:
	"""
	Virtual method called when reload starts.
	Override in weapon subclasses for reload animations/sounds.
	"""
	pass


func _finish_reload() -> void:
	"""
	Called when reload timer completes.
	"""
	_is_reloading = false
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	reloaded.emit()


func _on_attack_finished() -> void:
	"""
	Called when attack animation/action completes.
	Subclasses should call this when their attack is done.
	"""
	_is_attacking = false
	attack_finished.emit()


# Utility functions

func get_attack_cooldown_remaining() -> float:
	return maxf(_attack_cooldown_timer, 0.0)


func get_reload_progress() -> float:
	"""
	Returns reload progress from 0.0 to 1.0
	"""
	if not _is_reloading:
		return 1.0
	return 1.0 - (_reload_timer / reload_time)


func is_attacking() -> bool:
	return _is_attacking


func is_reloading() -> bool:
	return _is_reloading


# Network sync helpers

func get_weapon_state() -> Dictionary:
	return {
		"current_ammo": current_ammo,
		"is_attacking": _is_attacking,
		"is_reloading": _is_reloading,
		"cooldown": _attack_cooldown_timer,
		"reload_timer": _reload_timer,
	}


func apply_weapon_state(state: Dictionary) -> void:
	if state.has("current_ammo"):
		current_ammo = state.current_ammo
		ammo_changed.emit(current_ammo, max_ammo)
	if state.has("is_attacking"):
		_is_attacking = state.is_attacking
	if state.has("is_reloading"):
		_is_reloading = state.is_reloading
	if state.has("cooldown"):
		_attack_cooldown_timer = state.cooldown
		_can_attack = _attack_cooldown_timer <= 0
	if state.has("reload_timer"):
		_reload_timer = state.reload_timer
