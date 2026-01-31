extends Node
class_name InterferenceManager
## InterferenceManager - Manages sabotage abilities and trap placement
## Players earn interference tokens from puzzle solving advantages

signal trap_placed(player_id: int, trap_type: Trap.TrapType, position: Vector3)
signal interference_used(player_id: int, target_id: int, effect: String)

# Player interference tokens
var player_tokens: Dictionary = {}  # player_id -> Array of token types

# Active traps in world
var active_traps: Array[Trap] = []

# Token types that can be earned
enum TokenType {
	TRAP_SLOW,
	TRAP_STUN,
	TRAP_BLIND,
	TRAP_REVERSE,
	TRAP_DAMAGE,
	PUZZLE_SCRAMBLE,  # Scrambles opponent's puzzle
	TIME_STEAL,       # Steals time from opponent
	VISION_SHARE      # Sees opponent's screen briefly
}

# Cost in coins to buy tokens
const TOKEN_COSTS: Dictionary = {
	TokenType.TRAP_SLOW: 30,
	TokenType.TRAP_STUN: 50,
	TokenType.TRAP_BLIND: 40,
	TokenType.TRAP_REVERSE: 60,
	TokenType.TRAP_DAMAGE: 75,
	TokenType.PUZZLE_SCRAMBLE: 100,
	TokenType.TIME_STEAL: 80,
	TokenType.VISION_SHARE: 50
}


func _ready() -> void:
	print("[InterferenceManager] Initialized")


## Give a token to a player
func award_token(player_id: int, token_type: TokenType) -> void:
	if not player_tokens.has(player_id):
		player_tokens[player_id] = []

	player_tokens[player_id].append(token_type)
	print("[InterferenceManager] Player %d earned token: %s" % [player_id, TokenType.keys()[token_type]])


## Check if player has a specific token
func has_token(player_id: int, token_type: TokenType) -> bool:
	if not player_tokens.has(player_id):
		return false
	return token_type in player_tokens[player_id]


## Use a token (returns true if successful)
func use_token(player_id: int, token_type: TokenType) -> bool:
	if not has_token(player_id, token_type):
		return false

	player_tokens[player_id].erase(token_type)
	return true


## Get all tokens for a player
func get_tokens(player_id: int) -> Array:
	return player_tokens.get(player_id, [])


## Place a trap in the world
func place_trap(player_id: int, trap_type: Trap.TrapType, position: Vector3) -> bool:
	# Check for corresponding token
	var token_type = _trap_type_to_token(trap_type)
	if not use_token(player_id, token_type):
		print("[InterferenceManager] Player %d doesn't have token for trap" % player_id)
		return false

	# Find world node to add trap to
	var world = get_tree().current_scene
	if not world:
		return false

	# Create trap
	var trap = Trap.place_trap(trap_type, position, player_id, world)
	active_traps.append(trap)

	# Connect signals
	trap.trap_triggered.connect(_on_trap_triggered.bind(player_id))
	trap.trap_expired.connect(_on_trap_expired.bind(trap))

	trap_placed.emit(player_id, trap_type, position)
	print("[InterferenceManager] Player %d placed %s trap" % [player_id, Trap.TrapType.keys()[trap_type]])

	return true


## Buy a token with coins
func buy_token(player_id: int, token_type: TokenType) -> bool:
	var cost = TOKEN_COSTS.get(token_type, 999)
	var player_coins = GameManager.player_coins.get(player_id, 0)

	if player_coins < cost:
		print("[InterferenceManager] Player %d can't afford token (need %d, have %d)" % [player_id, cost, player_coins])
		return false

	# Deduct coins
	GameManager.player_coins[player_id] = player_coins - cost

	# Award token
	award_token(player_id, token_type)

	return true


## Scramble an opponent's puzzle
func scramble_puzzle(user_id: int, target_id: int) -> bool:
	if not use_token(user_id, TokenType.PUZZLE_SCRAMBLE):
		return false

	# Find target's current puzzle
	# This would need to be implemented based on how puzzles are tracked
	interference_used.emit(user_id, target_id, "puzzle_scramble")
	print("[InterferenceManager] Player %d scrambled player %d's puzzle" % [user_id, target_id])

	# Network sync
	if NetworkManager.is_multiplayer_active():
		_sync_scramble.rpc(target_id)

	return true


@rpc("any_peer", "reliable")
func _sync_scramble(target_id: int) -> void:
	# If we're the target, scramble our puzzle
	var local_id = NetworkManager.get_local_player_id()
	if target_id == local_id:
		# Find and scramble current puzzle
		var puzzles = get_tree().get_nodes_in_group("puzzles")
		for puzzle in puzzles:
			if puzzle.has_method("scramble"):
				puzzle.scramble()


## Steal time from opponent (adds to your timer, removes from theirs)
func steal_time(user_id: int, target_id: int, seconds: float = 10.0) -> bool:
	if not use_token(user_id, TokenType.TIME_STEAL):
		return false

	interference_used.emit(user_id, target_id, "time_steal")
	print("[InterferenceManager] Player %d stole %0.1fs from player %d" % [user_id, seconds, target_id])

	return true


func _trap_type_to_token(trap_type: Trap.TrapType) -> TokenType:
	match trap_type:
		Trap.TrapType.SLOW:
			return TokenType.TRAP_SLOW
		Trap.TrapType.STUN:
			return TokenType.TRAP_STUN
		Trap.TrapType.BLIND:
			return TokenType.TRAP_BLIND
		Trap.TrapType.REVERSE:
			return TokenType.TRAP_REVERSE
		Trap.TrapType.DAMAGE:
			return TokenType.TRAP_DAMAGE
	return TokenType.TRAP_SLOW


func _on_trap_triggered(victim_id: int, trap_type: Trap.TrapType, placer_id: int) -> void:
	print("[InterferenceManager] Trap triggered! Victim: %d, Placer: %d" % [victim_id, placer_id])


func _on_trap_expired(trap: Trap) -> void:
	active_traps.erase(trap)


## Award trap token to first puzzle solver
func award_first_solver_bonus(player_id: int) -> void:
	# First solver gets a random trap token
	var trap_tokens = [
		TokenType.TRAP_SLOW,
		TokenType.TRAP_STUN,
		TokenType.TRAP_BLIND
	]
	var random_token = trap_tokens[randi() % trap_tokens.size()]
	award_token(player_id, random_token)
