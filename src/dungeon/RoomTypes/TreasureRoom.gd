extends Room
class_name TreasureRoom
## TreasureRoom - Room with loot and coin rewards
## Players can collect treasures to gain coins and items

# Treasure signals
signal treasure_collected(treasure_type: String, value: int)
signal all_treasures_collected()

# Treasure types
enum TreasureType {
	COIN_SMALL,   # 10 coins
	COIN_MEDIUM,  # 25 coins
	COIN_LARGE,   # 50 coins
	COIN_PILE,    # 100 coins
	CHEST,        # Random item + coins
	ITEM          # Specific item
}

# Treasure data structure
class TreasureData:
	var type: TreasureType
	var position: Vector2
	var value: int
	var is_collected: bool = false
	var node: Node2D = null

# Treasure configuration
@export var min_treasures: int = 3
@export var max_treasures: int = 6
@export var spawn_chest: bool = true

# Treasure state
var treasures: Array[TreasureData] = []
var total_value: int = 0
var collected_value: int = 0

# Random number generator
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	room_type = RoomType.TREASURE
	super._ready()


func _initialize_room() -> void:
	# Don't call parent _initialize_room as treasure room doesn't have a puzzle
	_setup_treasures()


## Setup treasures in the room
func _setup_treasures() -> void:
	# Initialize RNG with room seed
	var seed_value = room_seed
	if GameManager:
		seed_value = GameManager.get_match_seed() + room_seed
	_rng.seed = seed_value

	# Determine number of treasures
	var treasure_count = _rng.randi_range(min_treasures, max_treasures)

	# Generate treasure positions
	var spawn_area = Rect2(-600, -300, 1200, 600)  # Area where treasures can spawn

	# Generate treasures
	for i in treasure_count:
		var treasure = TreasureData.new()

		# Determine treasure type (weighted random)
		treasure.type = _get_weighted_treasure_type()
		treasure.value = _get_treasure_value(treasure.type)
		treasure.position = _get_random_spawn_position(spawn_area)

		treasures.append(treasure)
		total_value += treasure.value

	# Optionally spawn a chest
	if spawn_chest:
		var chest = TreasureData.new()
		chest.type = TreasureType.CHEST
		chest.value = _rng.randi_range(50, 100)
		chest.position = Vector2(0, 0)  # Center of room
		treasures.append(chest)
		total_value += chest.value

	# Spawn treasure nodes
	_spawn_treasure_nodes()

	# Unlock forward door immediately (treasure rooms don't require completion)
	set_door_locked("right", false)

	print("[TreasureRoom %d] Spawned %d treasures worth %d coins" % [
		room_index, treasures.size(), total_value
	])


## Get a weighted random treasure type
func _get_weighted_treasure_type() -> TreasureType:
	var roll = _rng.randf()

	# Weighted distribution
	if roll < 0.40:  # 40% chance
		return TreasureType.COIN_SMALL
	elif roll < 0.70:  # 30% chance
		return TreasureType.COIN_MEDIUM
	elif roll < 0.90:  # 20% chance
		return TreasureType.COIN_LARGE
	else:  # 10% chance
		return TreasureType.COIN_PILE


## Get value for a treasure type
func _get_treasure_value(type: TreasureType) -> int:
	match type:
		TreasureType.COIN_SMALL:
			return 10
		TreasureType.COIN_MEDIUM:
			return 25
		TreasureType.COIN_LARGE:
			return 50
		TreasureType.COIN_PILE:
			return 100
		TreasureType.CHEST:
			return _rng.randi_range(50, 100)
		TreasureType.ITEM:
			return 0
	return 0


## Get random spawn position within area
func _get_random_spawn_position(area: Rect2) -> Vector2:
	return Vector2(
		_rng.randf_range(area.position.x, area.position.x + area.size.x),
		_rng.randf_range(area.position.y, area.position.y + area.size.y)
	)


## Spawn visual nodes for treasures
func _spawn_treasure_nodes() -> void:
	for treasure in treasures:
		var treasure_node = _create_treasure_node(treasure)
		if treasure_node:
			treasure_node.position = treasure.position
			add_child(treasure_node)
			treasure.node = treasure_node


## Create a visual node for a treasure
func _create_treasure_node(treasure: TreasureData) -> Node2D:
	# Create a simple placeholder visual
	var node = Area2D.new()
	node.name = "Treasure_%d" % treasures.find(treasure)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = _get_treasure_radius(treasure.type)
	collision.shape = shape
	node.add_child(collision)

	# Add visual placeholder (colored circle)
	var visual = ColorRect.new()
	var size = shape.radius * 2
	visual.size = Vector2(size, size)
	visual.position = Vector2(-size / 2, -size / 2)
	visual.color = _get_treasure_color(treasure.type)
	node.add_child(visual)

	# Add label showing value
	var label = Label.new()
	label.text = str(treasure.value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -30)
	node.add_child(label)

	# Connect body entered signal
	node.body_entered.connect(_on_treasure_touched.bind(treasure))

	return node


## Get radius for treasure type
func _get_treasure_radius(type: TreasureType) -> float:
	match type:
		TreasureType.COIN_SMALL:
			return 15.0
		TreasureType.COIN_MEDIUM:
			return 20.0
		TreasureType.COIN_LARGE:
			return 25.0
		TreasureType.COIN_PILE:
			return 35.0
		TreasureType.CHEST:
			return 40.0
		TreasureType.ITEM:
			return 30.0
	return 20.0


## Get color for treasure type
func _get_treasure_color(type: TreasureType) -> Color:
	match type:
		TreasureType.COIN_SMALL:
			return Color(0.8, 0.7, 0.2)  # Gold
		TreasureType.COIN_MEDIUM:
			return Color(0.9, 0.8, 0.3)  # Brighter gold
		TreasureType.COIN_LARGE:
			return Color(1.0, 0.9, 0.4)  # Bright gold
		TreasureType.COIN_PILE:
			return Color(1.0, 0.85, 0.0)  # Pure gold
		TreasureType.CHEST:
			return Color(0.6, 0.4, 0.2)  # Brown (wood)
		TreasureType.ITEM:
			return Color(0.5, 0.8, 1.0)  # Light blue
	return Color.WHITE


## Handle treasure collection
func _on_treasure_touched(body: Node2D, treasure: TreasureData) -> void:
	if treasure.is_collected:
		return

	# Check if it's a player
	if not body.has_method("get_player_id"):
		return

	var player_id = body.get_player_id()

	# Mark as collected
	treasure.is_collected = true
	collected_value += treasure.value

	# Award coins to player
	if GameManager:
		GameManager.player_coins[player_id] = GameManager.player_coins.get(player_id, 0) + treasure.value

	# Remove visual
	if treasure.node:
		treasure.node.queue_free()
		treasure.node = null

	var type_name = _get_treasure_type_name(treasure.type)
	print("[TreasureRoom %d] Player %d collected %s (+%d coins)" % [
		room_index, player_id, type_name, treasure.value
	])

	treasure_collected.emit(type_name, treasure.value)

	# Check if all treasures collected
	if _all_treasures_collected():
		all_treasures_collected.emit()
		complete_room()


## Check if all treasures are collected
func _all_treasures_collected() -> bool:
	for treasure in treasures:
		if not treasure.is_collected:
			return false
	return true


## Get remaining treasure count
func get_remaining_treasure_count() -> int:
	var count = 0
	for treasure in treasures:
		if not treasure.is_collected:
			count += 1
	return count


## Get remaining treasure value
func get_remaining_value() -> int:
	return total_value - collected_value


## Get treasure type name
func _get_treasure_type_name(type: TreasureType) -> String:
	match type:
		TreasureType.COIN_SMALL:
			return "Small Coin"
		TreasureType.COIN_MEDIUM:
			return "Medium Coin"
		TreasureType.COIN_LARGE:
			return "Large Coin"
		TreasureType.COIN_PILE:
			return "Coin Pile"
		TreasureType.CHEST:
			return "Treasure Chest"
		TreasureType.ITEM:
			return "Item"
	return "Treasure"
