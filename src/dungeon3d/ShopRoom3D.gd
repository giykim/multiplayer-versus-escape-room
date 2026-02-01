extends Room3D
class_name ShopRoom3D
## ShopRoom3D - 3D room variant with shop items for purchase
## Doors are always unlocked - players can return to shop anytime

# Shop configuration
@export var item_count: int = 3

# Shop state
var shop_items: Array[Dictionary] = []
var purchased_items: Array[String] = []

# Shop item definitions
const SHOP_ITEMS: Array[Dictionary] = [
	{"id": "health_potion", "name": "Health Potion", "cost": 25, "description": "Restore 50 HP"},
	{"id": "speed_boost", "name": "Speed Boost", "cost": 30, "description": "Move faster for 30s"},
	{"id": "puzzle_hint", "name": "Puzzle Hint", "cost": 20, "description": "Get a hint on next puzzle"},
	{"id": "map_reveal", "name": "Map Reveal", "cost": 40, "description": "Reveal dungeon layout"},
	{"id": "extra_life", "name": "Extra Life", "cost": 100, "description": "Respawn once if defeated"},
	{"id": "damage_boost", "name": "Damage Boost", "cost": 50, "description": "+25% damage in arena"},
]

# Visual elements
var shop_stands: Array[Node3D] = []
var shopkeeper_label: Label3D = null


func _ready() -> void:
	# Force room type to SHOP
	room_type = RoomType.SHOP

	# Shop rooms have UNLOCKED doors
	doors_locked["left"] = false
	doors_locked["right"] = false

	super._ready()


## Override - shop rooms never lock doors
func _should_lock_forward_door() -> bool:
	return false


## Override to setup shop content
func _setup_shop() -> void:
	_generate_shop_items()
	_create_shop_stands()
	_create_shopkeeper_sign()

	print("[ShopRoom3D %d] Setup with %d items for sale" % [room_index, shop_items.size()])


## Generate random shop items for this room
func _generate_shop_items() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = room_seed

	# Shuffle available items
	var available = SHOP_ITEMS.duplicate()
	for i in range(available.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = available[i]
		available[i] = available[j]
		available[j] = temp

	# Take first N items
	shop_items.clear()
	for i in range(mini(item_count, available.size())):
		shop_items.append(available[i])


## Create visual shop stands for each item
func _create_shop_stands() -> void:
	var positions = [
		Vector3(-2.5, 0.5, -3),
		Vector3(0, 0.5, -3),
		Vector3(2.5, 0.5, -3)
	]

	for i in range(shop_items.size()):
		if i >= positions.size():
			break

		var item = shop_items[i]
		var stand = _create_shop_stand(item, positions[i])
		shop_stands.append(stand)
		add_child(stand)


## Create a single shop stand with item display
func _create_shop_stand(item: Dictionary, pos: Vector3) -> Node3D:
	var stand = StaticBody3D.new()
	stand.name = "ShopStand_%s" % item.id
	stand.position = pos

	# Create pedestal
	var pedestal = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 1.0, 0.6)
	pedestal.mesh = box

	var pedestal_mat = StandardMaterial3D.new()
	pedestal_mat.albedo_color = Color(0.3, 0.25, 0.2)
	pedestal.material_override = pedestal_mat

	stand.add_child(pedestal)

	# Create item display (floating orb)
	var item_display = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	item_display.mesh = sphere
	item_display.position = Vector3(0, 0.8, 0)

	var item_mat = StandardMaterial3D.new()
	item_mat.albedo_color = Color(0.2, 0.8, 0.4)
	item_mat.emission_enabled = true
	item_mat.emission = Color(0.2, 0.8, 0.4)
	item_mat.emission_energy_multiplier = 0.5
	item_display.material_override = item_mat

	stand.add_child(item_display)

	# Create item name label
	var name_label = Label3D.new()
	name_label.text = item.name
	name_label.font_size = 24
	name_label.pixel_size = 0.008
	name_label.position = Vector3(0, 1.3, 0)
	name_label.modulate = Color.WHITE
	name_label.outline_size = 8
	name_label.outline_modulate = Color.BLACK
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stand.add_child(name_label)

	# Create cost label
	var cost_label = Label3D.new()
	cost_label.text = "%d coins" % item.cost
	cost_label.font_size = 20
	cost_label.pixel_size = 0.008
	cost_label.position = Vector3(0, 1.1, 0)
	cost_label.modulate = Color(1.0, 0.85, 0.0)
	cost_label.outline_size = 6
	cost_label.outline_modulate = Color.BLACK
	cost_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stand.add_child(cost_label)

	# Add collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 0.6)
	collision.shape = shape
	stand.add_child(collision)

	# Add interaction area
	var interact_area = Area3D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 8
	interact_area.collision_mask = 1
	interact_area.set_meta("item_id", item.id)

	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	area_shape.size = Vector3(1.5, 2.0, 1.5)
	area_collision.shape = area_shape
	area_collision.position = Vector3(0, 0.5, 0)
	interact_area.add_child(area_collision)

	interact_area.body_entered.connect(_on_shop_item_touched.bind(item.id))

	stand.add_child(interact_area)

	return stand


## Create the shopkeeper sign
func _create_shopkeeper_sign() -> void:
	shopkeeper_label = Label3D.new()
	shopkeeper_label.name = "ShopkeeperSign"
	shopkeeper_label.text = "SHOP"
	shopkeeper_label.font_size = 64
	shopkeeper_label.pixel_size = 0.01
	shopkeeper_label.position = Vector3(0, 3.2, -4.5)
	shopkeeper_label.modulate = Color(0.3, 0.8, 0.3)
	shopkeeper_label.outline_size = 16
	shopkeeper_label.outline_modulate = Color.BLACK
	add_child(shopkeeper_label)

	# Subtitle
	var subtitle = Label3D.new()
	subtitle.text = "Walk into items to purchase"
	subtitle.font_size = 24
	subtitle.pixel_size = 0.008
	subtitle.position = Vector3(0, 2.8, -4.5)
	subtitle.modulate = Color.WHITE
	subtitle.outline_size = 8
	subtitle.outline_modulate = Color.BLACK
	add_child(subtitle)


## Try to purchase an item
func _on_shop_item_touched(body: Node3D, item_id: String) -> void:
	if not body.has_method("get_player_id"):
		return

	if purchased_items.has(item_id):
		print("[ShopRoom3D] Item already purchased: %s" % item_id)
		return

	# Find item data
	var item_data: Dictionary = {}
	for item in shop_items:
		if item.id == item_id:
			item_data = item
			break

	if item_data.is_empty():
		return

	# Check if player has enough coins
	var player_id = body.get_player_id()
	var player_coins = 0
	if GameManager:
		var player_data = GameManager.get_player_data(player_id)
		if player_data:
			player_coins = player_data.coins

	if player_coins < item_data.cost:
		print("[ShopRoom3D] Not enough coins for %s (need %d, have %d)" % [
			item_data.name, item_data.cost, player_coins
		])
		# Show feedback
		_show_purchase_feedback(item_id, false, "Not enough coins!")
		return

	# Deduct coins and grant item
	if GameManager:
		GameManager.add_coins(player_id, -item_data.cost)

	purchased_items.append(item_id)
	_apply_item_effect(player_id, item_id)
	_show_purchase_feedback(item_id, true, "Purchased!")
	_update_stand_visuals(item_id)

	print("[ShopRoom3D] Player %d purchased %s for %d coins" % [
		player_id, item_data.name, item_data.cost
	])


## Apply the effect of a purchased item
func _apply_item_effect(player_id: int, item_id: String) -> void:
	match item_id:
		"health_potion":
			# Heal player
			var players = get_tree().get_nodes_in_group("players")
			for player in players:
				if player.has_method("get_player_id") and player.get_player_id() == player_id:
					if player.has_method("heal"):
						player.heal(50)
		"speed_boost":
			# Apply speed boost (would need player support)
			pass
		"puzzle_hint":
			# Store hint for next puzzle
			if GameManager:
				var advantages = GameManager.player_advantages.get(player_id, [])
				advantages.append("puzzle_hint")
				GameManager.player_advantages[player_id] = advantages
		"map_reveal":
			# Reveal map
			if GameManager:
				var advantages = GameManager.player_advantages.get(player_id, [])
				advantages.append("map_reveal_all")
				GameManager.player_advantages[player_id] = advantages
		"extra_life":
			# Grant extra life
			if GameManager:
				var advantages = GameManager.player_advantages.get(player_id, [])
				advantages.append("extra_life")
				GameManager.player_advantages[player_id] = advantages
		"damage_boost":
			# Grant damage boost
			if GameManager:
				var advantages = GameManager.player_advantages.get(player_id, [])
				advantages.append("damage_boost")
				GameManager.player_advantages[player_id] = advantages


## Show purchase feedback
func _show_purchase_feedback(item_id: String, success: bool, message: String) -> void:
	# Find the stand and show feedback
	for stand in shop_stands:
		if stand.name == "ShopStand_%s" % item_id:
			var feedback = Label3D.new()
			feedback.text = message
			feedback.font_size = 24
			feedback.pixel_size = 0.008
			feedback.position = Vector3(0, 1.6, 0)
			feedback.modulate = Color.GREEN if success else Color.RED
			feedback.outline_size = 8
			feedback.outline_modulate = Color.BLACK
			feedback.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			stand.add_child(feedback)

			# Fade out and remove
			var tween = create_tween()
			tween.tween_property(feedback, "position:y", 2.0, 1.0)
			tween.parallel().tween_property(feedback, "modulate:a", 0.0, 1.0)
			tween.tween_callback(feedback.queue_free)
			break


## Update stand visuals after purchase
func _update_stand_visuals(item_id: String) -> void:
	for stand in shop_stands:
		if stand.name == "ShopStand_%s" % item_id:
			# Dim the item display
			for child in stand.get_children():
				if child is MeshInstance3D and child.mesh is SphereMesh:
					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color(0.3, 0.3, 0.3)
					child.material_override = mat

			# Update labels
			for child in stand.get_children():
				if child is Label3D:
					child.modulate = Color(0.5, 0.5, 0.5)
					if child.text.ends_with("coins"):
						child.text = "SOLD"
			break
