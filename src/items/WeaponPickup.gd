extends Item
class_name WeaponPickup
## WeaponPickup - Weapon pickup that gives player a weapon
## Can only be picked up once and grants a weapon to the player's inventory

# Signal for weapon acquisition
signal weapon_acquired(weapon_type: String, player_id: int)

## Weapon Configuration
@export var weapon_type: String = "sword"
@export var weapon_name: String = "Basic Sword"
@export var weapon_damage: int = 10
@export var weapon_rarity: WeaponRarity = WeaponRarity.COMMON

## Weapon rarity enum
enum WeaponRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

## Rarity colors
const RARITY_COLORS = {
	WeaponRarity.COMMON: Color(0.7, 0.7, 0.7),      # Gray
	WeaponRarity.UNCOMMON: Color(0.3, 0.8, 0.3),   # Green
	WeaponRarity.RARE: Color(0.3, 0.5, 1.0),        # Blue
	WeaponRarity.EPIC: Color(0.7, 0.3, 0.9),        # Purple
	WeaponRarity.LEGENDARY: Color(1.0, 0.7, 0.2)   # Orange/Gold
}

## Rarity glow intensity
const RARITY_GLOW = {
	WeaponRarity.COMMON: 1.2,
	WeaponRarity.UNCOMMON: 1.3,
	WeaponRarity.RARE: 1.4,
	WeaponRarity.EPIC: 1.5,
	WeaponRarity.LEGENDARY: 1.8
}

## Reference to visual elements
var placeholder: ColorRect
var rarity_indicator: ColorRect


func _item_ready() -> void:
	item_type = "weapon"
	item_name = weapon_name

	# Setup visual based on rarity
	_setup_weapon_visual()

	# Setup glow based on rarity
	glow_color = RARITY_COLORS[weapon_rarity]
	glow_color.a = 0.6
	glow_intensity = RARITY_GLOW[weapon_rarity]


func _setup_weapon_visual() -> void:
	# Get or create placeholder
	placeholder = get_node_or_null("Sprite2D/Placeholder")
	if not placeholder:
		if sprite:
			placeholder = ColorRect.new()
			placeholder.name = "Placeholder"
			sprite.add_child(placeholder)

	if placeholder:
		# Weapon-shaped placeholder (rectangle for sword-like shape)
		placeholder.size = Vector2(20, 40)
		placeholder.position = -placeholder.size / 2
		placeholder.color = RARITY_COLORS[weapon_rarity]

	# Create rarity indicator (border/outline effect)
	_create_rarity_indicator()


func _create_rarity_indicator() -> void:
	if sprite and not rarity_indicator:
		rarity_indicator = ColorRect.new()
		rarity_indicator.name = "RarityIndicator"
		rarity_indicator.size = Vector2(24, 44)
		rarity_indicator.position = -rarity_indicator.size / 2
		rarity_indicator.color = RARITY_COLORS[weapon_rarity]
		rarity_indicator.color.a = 0.3
		rarity_indicator.z_index = -1
		sprite.add_child(rarity_indicator)
		sprite.move_child(rarity_indicator, 0)


func _on_pickup(player_id: int) -> void:
	# Grant weapon to player
	_give_weapon_to_player(player_id)

	# Emit weapon acquired signal
	weapon_acquired.emit(weapon_type, player_id)

	print("[WeaponPickup] Player %d acquired %s (%s rarity)" % [
		player_id, weapon_name, WeaponRarity.keys()[weapon_rarity]
	])


func _give_weapon_to_player(player_id: int) -> void:
	# Try to give weapon via GameManager
	if GameManager:
		# Check if player has an inventory/weapons array
		var player_data = GameManager.get_player_data(player_id)
		if player_data:
			# Store weapon data in player advantages as a weapon token
			var weapon_token = "weapon_%s_%s" % [weapon_type, weapon_rarity]
			if not GameManager.player_advantages[player_id].has(weapon_token):
				GameManager.player_advantages[player_id].append(weapon_token)

	# Try to give weapon directly to player node if it has inventory
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get_player_id") and player.get_player_id() == player_id:
			_add_weapon_to_player_node(player)
			break


func _add_weapon_to_player_node(player: Node) -> void:
	# Check for various inventory methods
	if player.has_method("add_weapon"):
		player.add_weapon(get_weapon_data())
	elif player.has_method("give_weapon"):
		player.give_weapon(get_weapon_data())
	elif player.has_method("equip_weapon"):
		player.equip_weapon(get_weapon_data())
	elif player.get("inventory"):
		var inventory = player.get("inventory")
		if inventory.has_method("add_item"):
			inventory.add_item(get_weapon_data())
	elif player.get("weapons"):
		var weapons = player.get("weapons")
		if weapons is Array:
			weapons.append(get_weapon_data())


## Get weapon data as a dictionary
func get_weapon_data() -> Dictionary:
	return {
		"type": weapon_type,
		"name": weapon_name,
		"damage": weapon_damage,
		"rarity": weapon_rarity,
		"rarity_name": WeaponRarity.keys()[weapon_rarity]
	}


## Set weapon properties (can be called before adding to scene tree)
func set_weapon(type: String, name: String, damage: int, rarity: WeaponRarity) -> void:
	weapon_type = type
	weapon_name = name
	weapon_damage = damage
	weapon_rarity = rarity

	if is_inside_tree():
		item_name = weapon_name
		_setup_weapon_visual()


## Static helper to create a weapon pickup
static func create_weapon(type: String, name: String, damage: int, rarity: WeaponRarity) -> WeaponPickup:
	var weapon_scene = preload("res://src/items/WeaponPickup.tscn")
	var weapon = weapon_scene.instantiate() as WeaponPickup
	weapon.set_weapon(type, name, damage, rarity)
	return weapon


## Get rarity color
func get_rarity_color() -> Color:
	return RARITY_COLORS[weapon_rarity]
