extends Room3D
class_name TreasureRoom3D
## TreasureRoom3D - 3D room variant with item pickups/loot
## Door is always unlocked

# Treasure configuration
@export var min_coins: int = 3
@export var max_coins: int = 8
@export var spawn_chest: bool = true
@export var item_drop_chance: float = 0.3

# Treasure state
var coins_collected: int = 0
var total_coins: int = 0
var items_collected: Array[String] = []
var chest_opened: bool = false

# Spawn positions for loot (relative to room center)
var coin_spawn_positions: Array[Vector3] = []
var spawned_pickups: Array[Node3D] = []

# Scene paths
const COIN_PICKUP_SCENE: String = "res://src/pickups/CoinPickup3D.tscn"
const CHEST_SCENE: String = "res://src/pickups/TreasureChest3D.tscn"
const ITEM_PICKUP_SCENE: String = "res://src/pickups/ItemPickup3D.tscn"


func _ready() -> void:
	# Force room type to TREASURE
	room_type = RoomType.TREASURE

	# Treasure rooms have unlocked doors
	doors_locked["right"] = false

	super._ready()


## Override to setup treasure content
func _setup_treasure() -> void:
	# Generate spawn positions
	_generate_spawn_positions()

	# Spawn coins
	_spawn_coins()

	# Spawn chest if enabled
	if spawn_chest:
		_spawn_chest()

	# Maybe spawn an item
	var rng = RandomNumberGenerator.new()
	rng.seed = room_seed
	if rng.randf() < item_drop_chance:
		_spawn_random_item(rng)

	print("[TreasureRoom3D %d] Setup with %d coins" % [room_index, total_coins])


## Generate random positions for coin spawns
func _generate_spawn_positions() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = room_seed

	# Calculate number of coins
	total_coins = rng.randi_range(min_coins, max_coins)

	# Generate positions in a scattered pattern
	coin_spawn_positions.clear()

	for i in range(total_coins):
		var x = rng.randf_range(-3.5, 3.5)
		var z = rng.randf_range(-3.5, 3.5)
		var y = 0.3  # Slightly above floor

		coin_spawn_positions.append(Vector3(x, y, z))


## Spawn coin pickups
func _spawn_coins() -> void:
	if not ResourceLoader.exists(COIN_PICKUP_SCENE):
		push_warning("[TreasureRoom3D %d] Coin pickup scene not found" % room_index)
		_spawn_placeholder_coins()
		return

	var coin_scene = load(COIN_PICKUP_SCENE)
	if not coin_scene:
		_spawn_placeholder_coins()
		return

	for pos in coin_spawn_positions:
		var coin = coin_scene.instantiate()
		coin.position = pos

		# Connect pickup signal if exists
		if coin.has_signal("picked_up"):
			coin.picked_up.connect(_on_coin_picked_up)

		add_child(coin)
		spawned_pickups.append(coin)


## Spawn placeholder coins (simple meshes) if no coin scene exists
func _spawn_placeholder_coins() -> void:
	for pos in coin_spawn_positions:
		var coin = _create_placeholder_coin()
		coin.position = pos
		add_child(coin)
		spawned_pickups.append(coin)


## Create a simple placeholder coin mesh
func _create_placeholder_coin() -> Node3D:
	var coin_root = Area3D.new()
	coin_root.collision_layer = 8  # Pickup layer
	coin_root.collision_mask = 1   # Player layer

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.15
	cylinder.bottom_radius = 0.15
	cylinder.height = 0.05
	mesh_instance.mesh = cylinder

	# Gold material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.85, 0.0)
	material.metallic = 0.8
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = Color(1.0, 0.85, 0.0)
	material.emission_energy_multiplier = 0.2
	mesh_instance.material_override = material

	# Rotate to lay flat
	mesh_instance.rotation_degrees = Vector3(90, 0, 0)

	coin_root.add_child(mesh_instance)

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.15
	shape.height = 0.05
	collision.shape = shape
	collision.rotation_degrees = Vector3(90, 0, 0)
	coin_root.add_child(collision)

	# Connect body entered for pickup
	coin_root.body_entered.connect(_on_placeholder_coin_touched.bind(coin_root))

	return coin_root


## Spawn treasure chest
func _spawn_chest() -> void:
	if not ResourceLoader.exists(CHEST_SCENE):
		push_warning("[TreasureRoom3D %d] Chest scene not found, using placeholder" % room_index)
		_spawn_placeholder_chest()
		return

	var chest_scene = load(CHEST_SCENE)
	if not chest_scene:
		_spawn_placeholder_chest()
		return

	var chest = chest_scene.instantiate()
	chest.position = Vector3(0, 0.3, -3)  # Back center of room

	# Connect chest signals
	if chest.has_signal("chest_opened"):
		chest.chest_opened.connect(_on_chest_opened)

	add_child(chest)


## Create a placeholder chest
func _spawn_placeholder_chest() -> void:
	var chest = StaticBody3D.new()
	chest.name = "TreasureChest"
	chest.position = Vector3(0, 0.4, -3)

	# Create chest mesh (simple box)
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.6, 0.6)
	mesh_instance.mesh = box

	# Brown wood material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.3, 0.1)
	mesh_instance.material_override = material

	chest.add_child(mesh_instance)

	# Add collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 0.6, 0.6)
	collision.shape = shape
	chest.add_child(collision)

	# Add interaction area
	var interact_area = Area3D.new()
	interact_area.collision_layer = 8
	interact_area.collision_mask = 1

	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	area_shape.size = Vector3(1.5, 1.0, 1.0)
	area_collision.shape = area_shape
	interact_area.add_child(area_collision)

	interact_area.body_entered.connect(_on_placeholder_chest_touched)

	chest.add_child(interact_area)
	add_child(chest)


## Spawn a random item pickup
func _spawn_random_item(rng: RandomNumberGenerator) -> void:
	if not ResourceLoader.exists(ITEM_PICKUP_SCENE):
		return

	var item_scene = load(ITEM_PICKUP_SCENE)
	if not item_scene:
		return

	var item = item_scene.instantiate()
	item.position = Vector3(rng.randf_range(-2, 2), 0.5, rng.randf_range(-2, 2))

	if item.has_signal("picked_up"):
		item.picked_up.connect(_on_item_picked_up)

	add_child(item)
	spawned_pickups.append(item)


## Get remaining pickups count
func get_remaining_pickups() -> int:
	return total_coins - coins_collected


## Check if all treasure collected
func is_fully_looted() -> bool:
	return coins_collected >= total_coins and chest_opened


# === Signal Handlers ===

func _on_coin_picked_up(value: int = 1) -> void:
	coins_collected += 1
	print("[TreasureRoom3D %d] Coin collected (%d/%d)" % [room_index, coins_collected, total_coins])

	# Notify GameManager of coin pickup
	if GameManager and GameManager.has_method("add_coins"):
		GameManager.add_coins(value)


func _on_placeholder_coin_touched(body: Node3D, coin: Node3D) -> void:
	if body.has_method("get_player_id"):
		coins_collected += 1
		coin.queue_free()
		spawned_pickups.erase(coin)
		print("[TreasureRoom3D %d] Placeholder coin collected (%d/%d)" % [room_index, coins_collected, total_coins])

		# Notify GameManager
		if GameManager and GameManager.has_method("add_coins"):
			GameManager.add_coins(1)


func _on_chest_opened(contents: Array = []) -> void:
	chest_opened = true
	print("[TreasureRoom3D %d] Chest opened" % room_index)


func _on_placeholder_chest_touched(body: Node3D) -> void:
	if chest_opened:
		return

	if body.has_method("get_player_id"):
		chest_opened = true
		print("[TreasureRoom3D %d] Placeholder chest opened" % room_index)

		# Give bonus coins
		if GameManager and GameManager.has_method("add_coins"):
			GameManager.add_coins(5)


func _on_item_picked_up(item_id: String) -> void:
	items_collected.append(item_id)
	print("[TreasureRoom3D %d] Item collected: %s" % [room_index, item_id])
