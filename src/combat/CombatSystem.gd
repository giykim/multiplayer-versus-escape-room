extends Node
class_name CombatSystem
## CombatSystem - Combat manager for player health, damage, and death handling
## Handles network synchronization for multiplayer combat

# Combat signals
signal damage_dealt(attacker_id: int, target_id: int, damage: int, remaining_health: int)
signal player_died(player_id: int, killer_id: int)
signal player_respawned(player_id: int, spawn_position: Vector2)
signal health_changed(player_id: int, new_health: int, max_health: int)

# Combat configuration
const MAX_HEALTH: int = 100
const INVINCIBILITY_DURATION: float = 1.0  # Seconds of invincibility after taking damage
const RESPAWN_DELAY: float = 3.0  # Seconds before respawn
const DEFAULT_RESPAWN_POSITION: Vector2 = Vector2(100, 100)

# Player health tracking
var player_health: Dictionary = {}  # player_id -> current_health
var player_invincibility: Dictionary = {}  # player_id -> invincibility_timer (remaining seconds)
var player_death_timers: Dictionary = {}  # player_id -> respawn_timer (remaining seconds)
var respawn_points: Array[Vector2] = []  # Available respawn locations

# Reference to active players (set externally)
var active_players: Dictionary = {}  # player_id -> Player node


func _ready() -> void:
	print("[CombatSystem] Initialized")


func _process(delta: float) -> void:
	_update_invincibility_timers(delta)
	_update_respawn_timers(delta)


func _update_invincibility_timers(delta: float) -> void:
	var players_to_clear: Array[int] = []

	for player_id in player_invincibility:
		player_invincibility[player_id] -= delta
		if player_invincibility[player_id] <= 0:
			players_to_clear.append(player_id)

	for player_id in players_to_clear:
		player_invincibility.erase(player_id)


func _update_respawn_timers(delta: float) -> void:
	var players_to_respawn: Array[int] = []

	for player_id in player_death_timers:
		player_death_timers[player_id] -= delta
		if player_death_timers[player_id] <= 0:
			players_to_respawn.append(player_id)

	for player_id in players_to_respawn:
		player_death_timers.erase(player_id)
		_respawn_player(player_id)


# Player registration

func register_player(player_id: int, player_node: Node = null) -> void:
	player_health[player_id] = MAX_HEALTH

	if player_node:
		active_players[player_id] = player_node

	print("[CombatSystem] Player %d registered with %d health" % [player_id, MAX_HEALTH])
	health_changed.emit(player_id, MAX_HEALTH, MAX_HEALTH)


func unregister_player(player_id: int) -> void:
	player_health.erase(player_id)
	player_invincibility.erase(player_id)
	player_death_timers.erase(player_id)
	active_players.erase(player_id)

	print("[CombatSystem] Player %d unregistered" % player_id)


func set_player_node(player_id: int, player_node: Node) -> void:
	active_players[player_id] = player_node


# Health management

func get_health(player_id: int) -> int:
	return player_health.get(player_id, 0)


func get_max_health() -> int:
	return MAX_HEALTH


func is_alive(player_id: int) -> bool:
	return player_health.get(player_id, 0) > 0


func is_invincible(player_id: int) -> bool:
	return player_invincibility.has(player_id) and player_invincibility[player_id] > 0


func heal_player(player_id: int, amount: int) -> void:
	if not player_health.has(player_id):
		return

	if not is_alive(player_id):
		return

	var old_health = player_health[player_id]
	player_health[player_id] = mini(old_health + amount, MAX_HEALTH)

	if player_health[player_id] != old_health:
		health_changed.emit(player_id, player_health[player_id], MAX_HEALTH)
		print("[CombatSystem] Player %d healed for %d (now %d)" % [player_id, amount, player_health[player_id]])

		# Sync heal in multiplayer
		if multiplayer.has_multiplayer_peer():
			_sync_health.rpc(player_id, player_health[player_id])


# Damage handling

func deal_damage(attacker_id: int, target_id: int, damage: int) -> bool:
	"""
	Deal damage to a target player.
	Returns true if damage was actually dealt (target was valid and not invincible).
	"""
	if not player_health.has(target_id):
		return false

	if not is_alive(target_id):
		return false

	if is_invincible(target_id):
		print("[CombatSystem] Player %d is invincible, damage blocked" % target_id)
		return false

	# Apply damage
	var old_health = player_health[target_id]
	player_health[target_id] = maxi(old_health - damage, 0)
	var new_health = player_health[target_id]

	# Grant invincibility frames
	player_invincibility[target_id] = INVINCIBILITY_DURATION

	print("[CombatSystem] Player %d dealt %d damage to player %d (%d -> %d)" % [
		attacker_id, damage, target_id, old_health, new_health
	])

	damage_dealt.emit(attacker_id, target_id, damage, new_health)
	health_changed.emit(target_id, new_health, MAX_HEALTH)

	# Sync damage in multiplayer
	if multiplayer.has_multiplayer_peer():
		_sync_damage.rpc(attacker_id, target_id, damage, new_health)

	# Check for death
	if new_health <= 0:
		_on_player_death(target_id, attacker_id)

	return true


func _on_player_death(player_id: int, killer_id: int) -> void:
	print("[CombatSystem] Player %d was killed by player %d" % [player_id, killer_id])

	# Disable player if we have reference
	if active_players.has(player_id):
		var player = active_players[player_id]
		if player.has_method("on_death"):
			player.on_death()
		elif player.has_method("set_visible"):
			player.visible = false

	player_died.emit(player_id, killer_id)

	# Start respawn timer
	player_death_timers[player_id] = RESPAWN_DELAY

	# Sync death in multiplayer
	if multiplayer.has_multiplayer_peer():
		_sync_death.rpc(player_id, killer_id)


func _respawn_player(player_id: int) -> void:
	# Reset health
	player_health[player_id] = MAX_HEALTH

	# Choose respawn position
	var spawn_pos = _get_respawn_position(player_id)

	# Respawn player if we have reference
	if active_players.has(player_id):
		var player = active_players[player_id]
		if player.has_method("on_respawn"):
			player.on_respawn(spawn_pos)
		else:
			if player.has_method("teleport_to"):
				player.teleport_to(spawn_pos)
			if "visible" in player:
				player.visible = true

	# Grant brief invincibility after respawn
	player_invincibility[player_id] = INVINCIBILITY_DURATION * 2

	print("[CombatSystem] Player %d respawned at %s" % [player_id, spawn_pos])

	health_changed.emit(player_id, MAX_HEALTH, MAX_HEALTH)
	player_respawned.emit(player_id, spawn_pos)

	# Sync respawn in multiplayer
	if multiplayer.has_multiplayer_peer():
		_sync_respawn.rpc(player_id, spawn_pos)


func _get_respawn_position(player_id: int) -> Vector2:
	if respawn_points.is_empty():
		return DEFAULT_RESPAWN_POSITION

	# Simple round-robin based on player ID
	var index = (player_id - 1) % respawn_points.size()
	return respawn_points[index]


func add_respawn_point(position: Vector2) -> void:
	respawn_points.append(position)


func clear_respawn_points() -> void:
	respawn_points.clear()


# Network synchronization RPCs

@rpc("any_peer", "call_local", "reliable")
func request_damage(attacker_id: int, target_id: int, damage: int) -> void:
	"""
	Client requests to deal damage. Server validates and applies.
	In single player, this just applies the damage directly.
	"""
	if not multiplayer.has_multiplayer_peer():
		# Single player - apply directly
		deal_damage(attacker_id, target_id, damage)
		return

	# In multiplayer, only server (host) processes damage
	if multiplayer.is_server():
		deal_damage(attacker_id, target_id, damage)
	else:
		# Client - forward request to server
		request_damage.rpc_id(1, attacker_id, target_id, damage)


@rpc("authority", "call_local", "reliable")
func _sync_damage(attacker_id: int, target_id: int, damage: int, new_health: int) -> void:
	"""
	Server syncs damage result to all clients.
	"""
	if multiplayer.is_server():
		return  # Server already processed this

	# Update local state
	if player_health.has(target_id):
		player_health[target_id] = new_health
		player_invincibility[target_id] = INVINCIBILITY_DURATION

		damage_dealt.emit(attacker_id, target_id, damage, new_health)
		health_changed.emit(target_id, new_health, MAX_HEALTH)


@rpc("authority", "call_local", "reliable")
func _sync_health(player_id: int, health: int) -> void:
	"""
	Server syncs health changes (like healing) to all clients.
	"""
	if multiplayer.is_server():
		return

	if player_health.has(player_id):
		player_health[player_id] = health
		health_changed.emit(player_id, health, MAX_HEALTH)


@rpc("authority", "call_local", "reliable")
func _sync_death(player_id: int, killer_id: int) -> void:
	"""
	Server syncs player death to all clients.
	"""
	if multiplayer.is_server():
		return

	# Disable player locally
	if active_players.has(player_id):
		var player = active_players[player_id]
		if player.has_method("on_death"):
			player.on_death()
		elif "visible" in player:
			player.visible = false

	player_died.emit(player_id, killer_id)


@rpc("authority", "call_local", "reliable")
func _sync_respawn(player_id: int, spawn_position: Vector2) -> void:
	"""
	Server syncs player respawn to all clients.
	"""
	if multiplayer.is_server():
		return

	player_health[player_id] = MAX_HEALTH
	player_invincibility[player_id] = INVINCIBILITY_DURATION * 2

	if active_players.has(player_id):
		var player = active_players[player_id]
		if player.has_method("on_respawn"):
			player.on_respawn(spawn_position)
		else:
			if player.has_method("teleport_to"):
				player.teleport_to(spawn_position)
			if "visible" in player:
				player.visible = true

	health_changed.emit(player_id, MAX_HEALTH, MAX_HEALTH)
	player_respawned.emit(player_id, spawn_position)


# Utility functions

func reset_all_players() -> void:
	"""
	Reset all players to full health. Used at match start.
	"""
	for player_id in player_health:
		player_health[player_id] = MAX_HEALTH
		health_changed.emit(player_id, MAX_HEALTH, MAX_HEALTH)

	player_invincibility.clear()
	player_death_timers.clear()

	print("[CombatSystem] All players reset to full health")


func get_alive_players() -> Array[int]:
	"""
	Returns array of player IDs that are currently alive.
	"""
	var alive: Array[int] = []
	for player_id in player_health:
		if is_alive(player_id):
			alive.append(player_id)
	return alive


func get_dead_players() -> Array[int]:
	"""
	Returns array of player IDs that are currently dead.
	"""
	var dead: Array[int] = []
	for player_id in player_health:
		if not is_alive(player_id):
			dead.append(player_id)
	return dead
