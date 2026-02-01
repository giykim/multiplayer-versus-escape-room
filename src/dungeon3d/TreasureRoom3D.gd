extends Room3D
class_name TreasureRoom3D
## TreasureRoom3D - 3D room with multiple chests to open
## One chest unlocks the door, others have items or are empty
## Chests cost coins to open and require E interaction

# Treasure configuration
@export var min_chests: int = 3
@export var max_chests: int = 5
@export var base_chest_cost: int = 5
@export var max_chest_cost: int = 15

# Chest data structure
class ChestData:
	var position: Vector3
	var cost: int
	var content_type: String  # "door_key", "coins", "item", "empty"
	var content_value: int
	var is_opened: bool = false
	var node: Node3D = null

# Treasure state
var chests: Array[ChestData] = []
var key_chest_index: int = -1
var door_unlocked: bool = false

# Chest content types and their probabilities
const CHEST_CONTENTS = {
	"coins": 0.4,      # 40% chance - gives coins back
	"item": 0.2,       # 20% chance - gives an item/advantage
	"empty": 0.4       # 40% chance - nothing (lost coins)
}


func _ready() -> void:
	room_type = RoomType.TREASURE
	doors_locked["right"] = true
	super._ready()


func _should_lock_forward_door() -> bool:
	return true


func _setup_treasure() -> void:
	_generate_chests()
	_spawn_all_chests()
	print("[TreasureRoom3D %d] Setup with %d chests (key in chest %d)" % [room_index, chests.size(), key_chest_index])


func _generate_chests() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = room_seed

	var chest_count = rng.randi_range(min_chests, max_chests)
	chests.clear()

	# Chest positions - spread across the back of the room
	var positions = _get_chest_positions(chest_count)

	# Randomly select which chest has the key
	key_chest_index = rng.randi_range(0, chest_count - 1)

	for i in range(chest_count):
		var chest = ChestData.new()
		chest.position = positions[i]
		chest.cost = rng.randi_range(base_chest_cost, max_chest_cost)

		if i == key_chest_index:
			chest.content_type = "door_key"
			chest.content_value = 0
		else:
			# Random content based on probabilities
			var roll = rng.randf()
			if roll < CHEST_CONTENTS["coins"]:
				chest.content_type = "coins"
				chest.content_value = rng.randi_range(chest.cost, chest.cost * 2)  # Get more than you paid
			elif roll < CHEST_CONTENTS["coins"] + CHEST_CONTENTS["item"]:
				chest.content_type = "item"
				chest.content_value = 1
			else:
				chest.content_type = "empty"
				chest.content_value = 0

		chests.append(chest)


func _get_chest_positions(count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var spacing = 6.0 / float(count + 1)
	var start_x = -3.0 + spacing

	for i in range(count):
		var x = start_x + i * spacing
		var z = -3.0 + randf_range(-0.5, 0.5)  # Slight variation
		positions.append(Vector3(x, 0.4, z))

	return positions


func _spawn_all_chests() -> void:
	for i in range(chests.size()):
		var chest_data = chests[i]
		var chest_node = _create_chest(chest_data, i)
		chest_data.node = chest_node
		add_child(chest_node)


func _create_chest(chest_data: ChestData, index: int) -> Node3D:
	var chest = Node3D.new()
	chest.name = "Chest_%d" % index
	chest.position = chest_data.position

	# Chest body (closed)
	var body = MeshInstance3D.new()
	body.name = "ChestBody"
	var box = BoxMesh.new()
	box.size = Vector3(0.8, 0.5, 0.5)
	body.mesh = box

	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.45, 0.28, 0.1)
	body.material_override = body_mat
	chest.add_child(body)

	# Chest lid (will animate when opened)
	var lid = MeshInstance3D.new()
	lid.name = "ChestLid"
	var lid_box = BoxMesh.new()
	lid_box.size = Vector3(0.8, 0.15, 0.5)
	lid.mesh = lid_box
	lid.position = Vector3(0, 0.325, 0)

	var lid_mat = StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.5, 0.32, 0.12)
	lid.material_override = lid_mat
	chest.add_child(lid)

	# Gold trim
	var trim = MeshInstance3D.new()
	trim.name = "Trim"
	var trim_box = BoxMesh.new()
	trim_box.size = Vector3(0.82, 0.08, 0.52)
	trim.mesh = trim_box
	trim.position = Vector3(0, 0.25, 0)

	var trim_mat = StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.85, 0.7, 0.2)
	trim_mat.metallic = 0.8
	trim.material_override = trim_mat
	chest.add_child(trim)

	# Cost label
	var cost_label = Label3D.new()
	cost_label.name = "CostLabel"
	cost_label.text = "%d coins" % chest_data.cost
	cost_label.font_size = 24
	cost_label.pixel_size = 0.008
	cost_label.position = Vector3(0, 0.7, 0)
	cost_label.modulate = Color(1.0, 0.85, 0.0)
	cost_label.outline_size = 8
	cost_label.outline_modulate = Color.BLACK
	cost_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chest.add_child(cost_label)

	# Hint label (shows "???" or content type hint)
	var hint_label = Label3D.new()
	hint_label.name = "HintLabel"
	hint_label.text = "Press [E] to open"
	hint_label.font_size = 18
	hint_label.pixel_size = 0.008
	hint_label.position = Vector3(0, 0.9, 0)
	hint_label.modulate = Color.WHITE
	hint_label.outline_size = 6
	hint_label.outline_modulate = Color.BLACK
	hint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chest.add_child(hint_label)

	# Interaction area
	var interact_area = Area3D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 32  # Interactable layer
	interact_area.collision_mask = 0
	interact_area.set_meta("puzzle_parent", self)
	interact_area.set_meta("chest_index", index)
	interact_area.add_to_group("interactable")

	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	area_shape.size = Vector3(1.2, 1.5, 1.2)
	area_collision.shape = area_shape
	area_collision.position = Vector3(0, 0.5, 0)
	interact_area.add_child(area_collision)

	chest.add_child(interact_area)

	# Collision for chest body
	var body_collision = StaticBody3D.new()
	body_collision.name = "ChestCollision"
	var body_shape = CollisionShape3D.new()
	var body_box = BoxShape3D.new()
	body_box.size = Vector3(0.8, 0.65, 0.5)
	body_shape.shape = body_box
	body_shape.position = Vector3(0, 0.075, 0)
	body_collision.add_child(body_shape)
	chest.add_child(body_collision)

	return chest


func interact(player: Node3D) -> void:
	# Find which chest the player is looking at
	var ray = player.get_node_or_null("Head/Camera3D/InteractionRay")
	if not ray or not ray.is_colliding():
		return

	var collider = ray.get_collider()
	if not collider or not collider.has_meta("chest_index"):
		return

	var chest_index = collider.get_meta("chest_index")
	_try_open_chest(chest_index, player)


func _try_open_chest(index: int, player: Node3D) -> void:
	if index < 0 or index >= chests.size():
		return

	var chest_data = chests[index]
	if chest_data.is_opened:
		print("[TreasureRoom3D] Chest already opened")
		return

	# Check if player has enough coins
	var player_id = player.get_player_id() if player.has_method("get_player_id") else 1
	var player_coins = 0
	if GameManager:
		var pdata = GameManager.get_player_data(player_id)
		if pdata:
			player_coins = pdata.coins

	if player_coins < chest_data.cost:
		print("[TreasureRoom3D] Not enough coins! Need %d, have %d" % [chest_data.cost, player_coins])
		_show_feedback(chest_data.node, "Need %d coins!" % chest_data.cost, Color.RED)
		return

	# Deduct coins
	if GameManager:
		GameManager.add_coins(player_id, -chest_data.cost)

	# Open the chest
	chest_data.is_opened = true
	_animate_chest_open(chest_data.node)
	_reveal_chest_contents(chest_data, player_id)


func _animate_chest_open(chest_node: Node3D) -> void:
	var lid = chest_node.get_node_or_null("ChestLid")
	if lid:
		# Rotate lid open
		var tween = create_tween()
		tween.tween_property(lid, "rotation_degrees:x", -110, 0.3)
		tween.parallel().tween_property(lid, "position:y", 0.5, 0.3)
		tween.parallel().tween_property(lid, "position:z", -0.2, 0.3)

	# Update labels
	var cost_label = chest_node.get_node_or_null("CostLabel")
	if cost_label:
		cost_label.text = "OPENED"
		cost_label.modulate = Color(0.5, 0.5, 0.5)

	var hint_label = chest_node.get_node_or_null("HintLabel")
	if hint_label:
		hint_label.visible = false

	# Change chest color to show it's opened
	var body = chest_node.get_node_or_null("ChestBody")
	if body:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.22, 0.08)  # Darker
		body.material_override = mat


func _reveal_chest_contents(chest_data: ChestData, player_id: int) -> void:
	match chest_data.content_type:
		"door_key":
			_show_feedback(chest_data.node, "DOOR UNLOCKED!", Color.GREEN)
			door_unlocked = true
			complete_room()
			print("[TreasureRoom3D] Door key found! Door unlocked!")

		"coins":
			var coin_reward = chest_data.content_value
			if GameManager:
				GameManager.add_coins(player_id, coin_reward)
			_show_feedback(chest_data.node, "+%d coins!" % coin_reward, Color.YELLOW)
			_spawn_coin_effect(chest_data.node.position)
			print("[TreasureRoom3D] Found %d coins!" % coin_reward)

		"item":
			# Grant a random advantage
			if GameManager:
				var advantages = GameManager.player_advantages.get(player_id, [])
				var items = ["speed_boost", "puzzle_hint", "trap_immunity"]
				var item = items[randi() % items.size()]
				advantages.append(item)
				GameManager.player_advantages[player_id] = advantages
				_show_feedback(chest_data.node, "Got: %s!" % item.replace("_", " ").capitalize(), Color.CYAN)
			print("[TreasureRoom3D] Found an item!")

		"empty":
			_show_feedback(chest_data.node, "Empty...", Color.GRAY)
			print("[TreasureRoom3D] Chest was empty!")


func _show_feedback(chest_node: Node3D, message: String, color: Color) -> void:
	var feedback = Label3D.new()
	feedback.text = message
	feedback.font_size = 28
	feedback.pixel_size = 0.008
	feedback.position = Vector3(0, 1.2, 0)
	feedback.modulate = color
	feedback.outline_size = 10
	feedback.outline_modulate = Color.BLACK
	feedback.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chest_node.add_child(feedback)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(feedback, "position:y", 1.8, 1.0)
	tween.parallel().tween_property(feedback, "modulate:a", 0.0, 1.0)
	tween.tween_callback(feedback.queue_free)


func _spawn_coin_effect(pos: Vector3) -> void:
	# Create floating coin particles
	for i in range(5):
		var coin = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.08
		cyl.height = 0.02
		coin.mesh = cyl
		coin.rotation_degrees.x = 90

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.0)
		mat.emission_energy_multiplier = 0.5
		coin.material_override = mat

		coin.position = pos + Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3))
		add_child(coin)

		var tween = create_tween()
		tween.tween_property(coin, "position:y", pos.y + 1.5, 0.5)
		tween.parallel().tween_property(coin, "rotation_degrees:y", 360, 0.5)
		tween.tween_property(coin, "modulate:a", 0.0, 0.3)
		tween.tween_callback(coin.queue_free)
