extends Area2D
class_name Item
## Item - Base class for all pickupable items
## Extends Area2D for pickup detection with visual effects and network sync

# Signals
signal item_picked_up(item: Item, player_id: int)

## Item Configuration
@export_group("Item Properties")
@export var item_name: String = "Item"
@export var item_type: String = "generic"
@export var value: int = 0

## Visual Configuration
@export_group("Visual Effects")
@export var bob_enabled: bool = true
@export var bob_height: float = 5.0
@export var bob_speed: float = 2.0
@export var glow_enabled: bool = true
@export var glow_color: Color = Color(1.0, 1.0, 0.8, 0.5)
@export var glow_intensity: float = 1.5

## Network Configuration
@export_group("Network")
@export var sync_pickup: bool = true

## Node references (set by scene or subclass)
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var animation_player: AnimationPlayer
var glow_sprite: Sprite2D

## Internal state
var _is_picked_up: bool = false
var _original_position: Vector2
var _bob_time: float = 0.0
var _pickup_authority_id: int = -1  # Track which player is attempting pickup


func _ready() -> void:
	# Store original position for bobbing
	_original_position = position

	# Get node references if they exist
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	animation_player = get_node_or_null("AnimationPlayer")
	glow_sprite = get_node_or_null("GlowSprite")

	# Setup collision detection
	body_entered.connect(_on_body_entered)

	# Add to pickups group for easy querying
	add_to_group("pickups")
	add_to_group("interactable")

	# Setup glow effect
	if glow_enabled:
		_setup_glow()

	# Start idle animation if available
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

	# Call subclass initialization
	_item_ready()


func _item_ready() -> void:
	# Override in subclasses for additional setup
	pass


func _process(delta: float) -> void:
	if _is_picked_up:
		return

	# Apply bobbing animation
	if bob_enabled:
		_bob_time += delta * bob_speed
		var bob_offset = sin(_bob_time) * bob_height
		position.y = _original_position.y + bob_offset


func _setup_glow() -> void:
	# Create glow effect if sprite exists but no glow sprite
	if sprite and not glow_sprite:
		glow_sprite = Sprite2D.new()
		glow_sprite.name = "GlowSprite"
		glow_sprite.texture = sprite.texture if sprite.texture else null
		glow_sprite.modulate = glow_color
		glow_sprite.scale = sprite.scale * glow_intensity
		glow_sprite.z_index = -1
		add_child(glow_sprite)
		move_child(glow_sprite, 0)


func _on_body_entered(body: Node2D) -> void:
	if _is_picked_up:
		return

	# Check if it's a player
	if not body.has_method("get_player_id"):
		return

	var player_id = body.get_player_id()

	# Handle network sync for pickup
	if sync_pickup and multiplayer and multiplayer.has_multiplayer_peer():
		_request_pickup(player_id)
	else:
		# Single player - just pick up
		_do_pickup(player_id)


func _request_pickup(player_id: int) -> void:
	# In multiplayer, we need to sync who gets the item
	# Only the server/host should determine who gets it
	if multiplayer.is_server():
		# Server decides and notifies all clients
		_do_pickup.rpc(player_id)
	else:
		# Client requests pickup from server
		_request_pickup_from_server.rpc_id(1, player_id)


@rpc("any_peer", "reliable")
func _request_pickup_from_server(player_id: int) -> void:
	# Server receives request and processes it
	if not multiplayer.is_server():
		return

	if _is_picked_up:
		return

	# First one to request gets it
	_do_pickup.rpc(player_id)


@rpc("authority", "call_local", "reliable")
func _do_pickup(player_id: int) -> void:
	if _is_picked_up:
		return

	_is_picked_up = true
	_pickup_authority_id = player_id

	# Disable collision
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Call subclass pickup logic
	_on_pickup(player_id)

	# Emit signal
	item_picked_up.emit(self, player_id)

	# Play pickup animation or just remove
	_play_pickup_effect()


func _on_pickup(player_id: int) -> void:
	# Override in subclasses to handle specific pickup logic
	print("[Item] %s picked up by player %d" % [item_name, player_id])


func _play_pickup_effect() -> void:
	# Play pickup animation if available
	if animation_player and animation_player.has_animation("pickup"):
		animation_player.play("pickup")
		animation_player.animation_finished.connect(_on_pickup_animation_finished)
	else:
		# Default: quick fade and remove
		_default_pickup_effect()


func _default_pickup_effect() -> void:
	# Create a simple tween animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _on_pickup_animation_finished(_anim_name: String) -> void:
	queue_free()


## Check if item has been picked up
func is_picked_up() -> bool:
	return _is_picked_up


## Get the player who picked up this item
func get_pickup_player_id() -> int:
	return _pickup_authority_id


## Manual pickup method (for interaction-based pickup instead of auto)
func pickup_by(player_id: int) -> bool:
	if _is_picked_up:
		return false

	if sync_pickup and multiplayer and multiplayer.has_multiplayer_peer():
		_request_pickup(player_id)
	else:
		_do_pickup(player_id)

	return true


## Interact method for interaction system
func interact(player: Node2D) -> void:
	if player.has_method("get_player_id"):
		pickup_by(player.get_player_id())


## Set the item's visual representation
func set_item_visual(texture: Texture2D, color: Color = Color.WHITE) -> void:
	if sprite:
		sprite.texture = texture
		sprite.modulate = color

	# Update glow sprite if exists
	if glow_sprite and texture:
		glow_sprite.texture = texture
