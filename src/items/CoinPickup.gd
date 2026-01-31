extends Item
class_name CoinPickup
## CoinPickup - Coin/gold pickup that adds currency to the player
## Comes in different sizes with different values

# Coin size enum
enum CoinSize {
	SMALL,   # 10 coins
	MEDIUM,  # 25 coins
	LARGE    # 50 coins
}

## Coin Configuration
@export var coin_size: CoinSize = CoinSize.SMALL

## Visual Configuration
@export var sparkle_on_pickup: bool = true
@export var sparkle_count: int = 8

## Coin values by size
const COIN_VALUES = {
	CoinSize.SMALL: 10,
	CoinSize.MEDIUM: 25,
	CoinSize.LARGE: 50
}

## Coin colors by size
const COIN_COLORS = {
	CoinSize.SMALL: Color(0.8, 0.7, 0.2),      # Bronze/gold
	CoinSize.MEDIUM: Color(0.9, 0.85, 0.3),    # Brighter gold
	CoinSize.LARGE: Color(1.0, 0.95, 0.4)      # Bright gold/yellow
}

## Coin sizes (scale)
const COIN_SCALES = {
	CoinSize.SMALL: Vector2(0.8, 0.8),
	CoinSize.MEDIUM: Vector2(1.0, 1.0),
	CoinSize.LARGE: Vector2(1.3, 1.3)
}

## Reference to the placeholder visual
var placeholder: ColorRect


func _item_ready() -> void:
	item_type = "coin"

	# Set value based on coin size
	value = COIN_VALUES[coin_size]
	item_name = _get_coin_name()

	# Setup visual based on size
	_setup_coin_visual()

	# Configure glow
	glow_color = COIN_COLORS[coin_size]
	glow_color.a = 0.4


func _setup_coin_visual() -> void:
	# Get placeholder visual
	placeholder = get_node_or_null("Sprite2D/Placeholder")
	if not placeholder:
		# Create placeholder if it doesn't exist
		if sprite:
			placeholder = ColorRect.new()
			placeholder.name = "Placeholder"
			sprite.add_child(placeholder)

	if placeholder:
		# Size based on coin size
		var base_size = 32.0
		match coin_size:
			CoinSize.SMALL:
				base_size = 24.0
			CoinSize.MEDIUM:
				base_size = 32.0
			CoinSize.LARGE:
				base_size = 44.0

		placeholder.size = Vector2(base_size, base_size)
		placeholder.position = -placeholder.size / 2
		placeholder.color = COIN_COLORS[coin_size]

	# Apply scale
	scale = COIN_SCALES[coin_size]


func _get_coin_name() -> String:
	match coin_size:
		CoinSize.SMALL:
			return "Small Coin"
		CoinSize.MEDIUM:
			return "Medium Coin"
		CoinSize.LARGE:
			return "Large Coin"
	return "Coin"


func _on_pickup(player_id: int) -> void:
	# Add coins to player via GameManager
	if GameManager:
		var current_coins = GameManager.player_coins.get(player_id, 0)
		GameManager.player_coins[player_id] = current_coins + value

		# Also update PlayerData if it exists
		var player_data = GameManager.get_player_data(player_id)
		if player_data:
			player_data.coins = GameManager.player_coins[player_id]

	print("[CoinPickup] Player %d collected %s (+%d coins)" % [player_id, item_name, value])


func _play_pickup_effect() -> void:
	# Spawn sparkle particles
	if sparkle_on_pickup:
		_spawn_sparkles()

	# Play the default pickup effect
	_default_pickup_effect()


func _spawn_sparkles() -> void:
	var coin_color = COIN_COLORS[coin_size]

	for i in sparkle_count:
		var sparkle = _create_sparkle(coin_color)
		get_parent().add_child(sparkle)
		sparkle.global_position = global_position

		# Random direction
		var angle = (float(i) / sparkle_count) * TAU + randf() * 0.5
		var speed = randf_range(80, 150)
		var direction = Vector2.from_angle(angle)

		# Animate sparkle
		var tween = sparkle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(sparkle, "position", sparkle.position + direction * speed * 0.5, 0.4)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.4)
		tween.tween_property(sparkle, "scale", Vector2(0.1, 0.1), 0.4)
		tween.chain().tween_callback(sparkle.queue_free)


func _create_sparkle(color: Color) -> Node2D:
	var sparkle = Node2D.new()

	var visual = ColorRect.new()
	visual.size = Vector2(8, 8)
	visual.position = -visual.size / 2
	visual.color = color
	visual.color.a = 0.9

	sparkle.add_child(visual)
	sparkle.scale = Vector2(randf_range(0.5, 1.0), randf_range(0.5, 1.0))

	return sparkle


## Static helper to create a coin pickup with specific size
static func create_coin(size: CoinSize) -> CoinPickup:
	var coin_scene = preload("res://src/items/CoinPickup.tscn")
	var coin = coin_scene.instantiate() as CoinPickup
	coin.coin_size = size
	return coin


## Set the coin size (can be called before adding to scene tree)
func set_coin_size(size: CoinSize) -> void:
	coin_size = size
	if is_inside_tree():
		value = COIN_VALUES[coin_size]
		item_name = _get_coin_name()
		_setup_coin_visual()
