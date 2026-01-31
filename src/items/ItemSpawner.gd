extends Node2D
class_name ItemSpawner
## ItemSpawner - Spawns items at designated spawn points
## Uses seeded random for deterministic spawns across network

# Signals
signal item_spawned(item: Item, spawn_point: Vector2)
signal all_items_spawned()
signal item_pool_exhausted()

## Spawn Configuration
@export_group("Spawn Settings")
@export var spawn_on_ready: bool = false
@export var spawn_delay: float = 0.0
@export var max_items: int = -1  # -1 = unlimited

## Item Pool Configuration
@export_group("Item Pool")
@export var coin_weight: float = 50.0
@export var health_weight: float = 30.0
@export var weapon_weight: float = 20.0

## Coin sub-weights (within coin category)
@export_subgroup("Coin Distribution")
@export var small_coin_weight: float = 50.0
@export var medium_coin_weight: float = 35.0
@export var large_coin_weight: float = 15.0

## Health sub-weights
@export_subgroup("Health Distribution")
@export var small_health_weight: float = 40.0
@export var medium_health_weight: float = 40.0
@export var large_health_weight: float = 20.0

## Weapon sub-weights by rarity
@export_subgroup("Weapon Distribution")
@export var common_weapon_weight: float = 40.0
@export var uncommon_weapon_weight: float = 30.0
@export var rare_weapon_weight: float = 20.0
@export var epic_weapon_weight: float = 8.0
@export var legendary_weapon_weight: float = 2.0

## Seed Configuration
@export_group("Randomization")
@export var use_match_seed: bool = true
@export var local_seed_offset: int = 0
@export var custom_seed: int = 0

## Internal state
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_points: Array[Vector2] = []
var _spawned_items: Array[Item] = []
var _items_to_spawn: int = 0

## Preloaded scenes
var _coin_scene: PackedScene
var _health_scene: PackedScene
var _weapon_scene: PackedScene


func _ready() -> void:
	# Preload item scenes
	_coin_scene = preload("res://src/items/CoinPickup.tscn")
	_health_scene = preload("res://src/items/HealthPickup.tscn")
	_weapon_scene = preload("res://src/items/WeaponPickup.tscn")

	# Initialize RNG
	_initialize_rng()

	# Collect spawn points from children
	_collect_spawn_points()

	# Auto spawn if configured
	if spawn_on_ready and _spawn_points.size() > 0:
		if spawn_delay > 0:
			await get_tree().create_timer(spawn_delay).timeout
		spawn_items(_spawn_points.size())


func _initialize_rng() -> void:
	var seed_value = custom_seed

	if use_match_seed and GameManager:
		seed_value = GameManager.get_match_seed() + local_seed_offset
	elif custom_seed == 0:
		seed_value = randi()

	_rng.seed = seed_value
	print("[ItemSpawner] Initialized with seed: %d" % seed_value)


func _collect_spawn_points() -> void:
	_spawn_points.clear()

	# Find all Marker2D children as spawn points
	for child in get_children():
		if child is Marker2D:
			_spawn_points.append(child.position)

	# If no markers, check for SpawnPoints node
	var spawn_points_node = get_node_or_null("SpawnPoints")
	if spawn_points_node:
		for child in spawn_points_node.get_children():
			if child is Marker2D or child is Node2D:
				_spawn_points.append(child.position)

	print("[ItemSpawner] Found %d spawn points" % _spawn_points.size())


## Add spawn points manually
func add_spawn_point(point: Vector2) -> void:
	_spawn_points.append(point)


## Add multiple spawn points
func add_spawn_points(points: Array[Vector2]) -> void:
	_spawn_points.append_array(points)


## Clear all spawn points
func clear_spawn_points() -> void:
	_spawn_points.clear()


## Set the item pool weights
func set_item_weights(coins: float, health: float, weapons: float) -> void:
	coin_weight = coins
	health_weight = health
	weapon_weight = weapons


## Spawn items at all spawn points
func spawn_items(count: int = -1) -> Array[Item]:
	if count < 0:
		count = _spawn_points.size()

	if max_items >= 0:
		count = mini(count, max_items - _spawned_items.size())

	if count <= 0:
		item_pool_exhausted.emit()
		return []

	var spawned: Array[Item] = []
	var available_points = _spawn_points.duplicate()
	available_points.shuffle()

	_items_to_spawn = mini(count, available_points.size())

	for i in _items_to_spawn:
		if available_points.is_empty():
			break

		var spawn_point = available_points.pop_back()
		var item = _spawn_random_item(spawn_point)

		if item:
			spawned.append(item)
			_spawned_items.append(item)
			item_spawned.emit(item, spawn_point)

	all_items_spawned.emit()
	return spawned


## Spawn a specific item type at a point
func spawn_item_at(item_type: String, point: Vector2, variant: int = -1) -> Item:
	var item: Item = null

	match item_type:
		"coin":
			item = _create_coin(variant)
		"health":
			item = _create_health(variant)
		"weapon":
			item = _create_weapon(variant)
		_:
			push_warning("[ItemSpawner] Unknown item type: %s" % item_type)
			return null

	if item:
		item.position = point
		add_child(item)
		_spawned_items.append(item)
		item_spawned.emit(item, point)

	return item


## Spawn a random item at a point
func _spawn_random_item(point: Vector2) -> Item:
	var item_type = _get_random_item_type()
	var item: Item = null

	match item_type:
		"coin":
			item = _create_random_coin()
		"health":
			item = _create_random_health()
		"weapon":
			item = _create_random_weapon()

	if item:
		item.position = point
		add_child(item)

		# Connect to item pickup for tracking
		item.item_picked_up.connect(_on_item_picked_up)

	return item


## Get random item type based on weights
func _get_random_item_type() -> String:
	var total_weight = coin_weight + health_weight + weapon_weight
	var roll = _rng.randf() * total_weight

	if roll < coin_weight:
		return "coin"
	elif roll < coin_weight + health_weight:
		return "health"
	else:
		return "weapon"


## Create a random coin
func _create_random_coin() -> CoinPickup:
	var coin = _coin_scene.instantiate() as CoinPickup

	var total_weight = small_coin_weight + medium_coin_weight + large_coin_weight
	var roll = _rng.randf() * total_weight

	if roll < small_coin_weight:
		coin.coin_size = CoinPickup.CoinSize.SMALL
	elif roll < small_coin_weight + medium_coin_weight:
		coin.coin_size = CoinPickup.CoinSize.MEDIUM
	else:
		coin.coin_size = CoinPickup.CoinSize.LARGE

	return coin


## Create a coin with specific size
func _create_coin(size: int) -> CoinPickup:
	var coin = _coin_scene.instantiate() as CoinPickup

	if size >= 0 and size < CoinPickup.CoinSize.size():
		coin.coin_size = size as CoinPickup.CoinSize
	else:
		coin.coin_size = CoinPickup.CoinSize.MEDIUM

	return coin


## Create a random health pickup
func _create_random_health() -> HealthPickup:
	var health = _health_scene.instantiate() as HealthPickup

	var total_weight = small_health_weight + medium_health_weight + large_health_weight
	var roll = _rng.randf() * total_weight

	if roll < small_health_weight:
		health.health_size = HealthPickup.HealthSize.SMALL
	elif roll < small_health_weight + medium_health_weight:
		health.health_size = HealthPickup.HealthSize.MEDIUM
	else:
		health.health_size = HealthPickup.HealthSize.LARGE

	return health


## Create a health pickup with specific size
func _create_health(size: int) -> HealthPickup:
	var health = _health_scene.instantiate() as HealthPickup

	if size >= 0 and size < HealthPickup.HealthSize.size():
		health.health_size = size as HealthPickup.HealthSize
	else:
		health.health_size = HealthPickup.HealthSize.MEDIUM

	return health


## Create a random weapon
func _create_random_weapon() -> WeaponPickup:
	var weapon = _weapon_scene.instantiate() as WeaponPickup

	# Determine rarity
	var total_weight = common_weapon_weight + uncommon_weapon_weight + rare_weapon_weight + epic_weapon_weight + legendary_weapon_weight
	var roll = _rng.randf() * total_weight

	var rarity: WeaponPickup.WeaponRarity
	if roll < common_weapon_weight:
		rarity = WeaponPickup.WeaponRarity.COMMON
	elif roll < common_weapon_weight + uncommon_weapon_weight:
		rarity = WeaponPickup.WeaponRarity.UNCOMMON
	elif roll < common_weapon_weight + uncommon_weapon_weight + rare_weapon_weight:
		rarity = WeaponPickup.WeaponRarity.RARE
	elif roll < common_weapon_weight + uncommon_weapon_weight + rare_weapon_weight + epic_weapon_weight:
		rarity = WeaponPickup.WeaponRarity.EPIC
	else:
		rarity = WeaponPickup.WeaponRarity.LEGENDARY

	# Get random weapon type and stats
	var weapon_data = _get_random_weapon_data(rarity)
	weapon.set_weapon(weapon_data.type, weapon_data.name, weapon_data.damage, rarity)

	return weapon


## Create a weapon with specific rarity
func _create_weapon(rarity: int) -> WeaponPickup:
	var weapon = _weapon_scene.instantiate() as WeaponPickup

	if rarity < 0 or rarity >= WeaponPickup.WeaponRarity.size():
		rarity = WeaponPickup.WeaponRarity.COMMON

	var weapon_rarity = rarity as WeaponPickup.WeaponRarity
	var weapon_data = _get_random_weapon_data(weapon_rarity)
	weapon.set_weapon(weapon_data.type, weapon_data.name, weapon_data.damage, weapon_rarity)

	return weapon


## Get random weapon data based on rarity
func _get_random_weapon_data(rarity: WeaponPickup.WeaponRarity) -> Dictionary:
	# Base weapon types
	var weapon_types = [
		{"type": "sword", "base_name": "Sword", "base_damage": 10},
		{"type": "axe", "base_name": "Axe", "base_damage": 12},
		{"type": "dagger", "base_name": "Dagger", "base_damage": 7},
		{"type": "mace", "base_name": "Mace", "base_damage": 11},
		{"type": "spear", "base_name": "Spear", "base_damage": 9},
	]

	# Rarity prefixes
	var rarity_prefixes = {
		WeaponPickup.WeaponRarity.COMMON: ["Rusty", "Old", "Basic"],
		WeaponPickup.WeaponRarity.UNCOMMON: ["Sharp", "Sturdy", "Fine"],
		WeaponPickup.WeaponRarity.RARE: ["Enchanted", "Gleaming", "Superior"],
		WeaponPickup.WeaponRarity.EPIC: ["Mystic", "Ancient", "Powerful"],
		WeaponPickup.WeaponRarity.LEGENDARY: ["Legendary", "Divine", "Mythical"],
	}

	# Damage multipliers by rarity
	var damage_multipliers = {
		WeaponPickup.WeaponRarity.COMMON: 1.0,
		WeaponPickup.WeaponRarity.UNCOMMON: 1.3,
		WeaponPickup.WeaponRarity.RARE: 1.7,
		WeaponPickup.WeaponRarity.EPIC: 2.2,
		WeaponPickup.WeaponRarity.LEGENDARY: 3.0,
	}

	# Pick random weapon type
	var base = weapon_types[_rng.randi() % weapon_types.size()]

	# Pick random prefix for rarity
	var prefixes = rarity_prefixes[rarity]
	var prefix = prefixes[_rng.randi() % prefixes.size()]

	# Calculate damage
	var damage = int(base.base_damage * damage_multipliers[rarity])

	return {
		"type": base.type,
		"name": "%s %s" % [prefix, base.base_name],
		"damage": damage
	}


## Handle item pickup
func _on_item_picked_up(item: Item, _player_id: int) -> void:
	# Remove from tracking
	_spawned_items.erase(item)


## Get all currently spawned items
func get_spawned_items() -> Array[Item]:
	# Clean up invalid references
	var valid_items: Array[Item] = []
	for item in _spawned_items:
		if is_instance_valid(item) and not item.is_picked_up():
			valid_items.append(item)
	_spawned_items = valid_items
	return _spawned_items.duplicate()


## Get count of remaining items
func get_remaining_item_count() -> int:
	return get_spawned_items().size()


## Clear all spawned items
func clear_items() -> void:
	for item in _spawned_items:
		if is_instance_valid(item):
			item.queue_free()
	_spawned_items.clear()


## Reseed the RNG
func reseed(new_seed: int) -> void:
	_rng.seed = new_seed
