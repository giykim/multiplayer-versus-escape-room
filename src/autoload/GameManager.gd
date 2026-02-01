extends Node
## GameManager - Core game state singleton
## Manages game flow, player data, and match state

signal game_state_changed(new_state: GameState)
signal player_registered(player_id: int)
signal puzzle_completed(player_id: int, puzzle_id: String, time_taken: float)
signal match_ended(winner_id: int)
signal coins_changed(player_id: int, new_total: int)

enum GameState {
	MENU,
	LOBBY,
	LOADING,
	PUZZLE_PHASE,
	ARENA_PHASE,
	GAME_OVER
}

# Current game state
var current_state: GameState = GameState.MENU

# Match configuration
var match_seed: int = 0
var max_players: int = 4

# Player data storage
var players: Dictionary = {}  # player_id -> PlayerData

# Competition tracking
var puzzle_completion_order: Array[int] = []  # player_ids in order of completion
var player_coins: Dictionary = {}  # player_id -> coins
var player_advantages: Dictionary = {}  # player_id -> Array of advantages

# Match timing
var match_start_time: float = 0.0
var puzzle_phase_duration: float = 300.0  # 5 minutes for puzzle phase


class PlayerData:
	var id: int
	var display_name: String
	var color: Color
	var coins: int = 0
	var puzzles_solved: int = 0
	var advantages: Array[String] = []
	var is_ready: bool = false

	func _init(player_id: int, name: String = "Player"):
		id = player_id
		display_name = name
		color = Color(randf(), randf(), randf())


func _ready() -> void:
	print("[GameManager] Initialized")


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state

	print("[GameManager] State changed: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])
	game_state_changed.emit(new_state)

	match new_state:
		GameState.PUZZLE_PHASE:
			_start_puzzle_phase()
		GameState.ARENA_PHASE:
			_start_arena_phase()
		GameState.GAME_OVER:
			_handle_game_over()


func register_player(player_id: int, display_name: String = "") -> void:
	if display_name.is_empty():
		display_name = "Player %d" % player_id

	var player_data = PlayerData.new(player_id, display_name)
	players[player_id] = player_data
	player_coins[player_id] = 0
	player_advantages[player_id] = []

	print("[GameManager] Player registered: %s (ID: %d)" % [display_name, player_id])
	player_registered.emit(player_id)


func unregister_player(player_id: int) -> void:
	if players.has(player_id):
		players.erase(player_id)
		player_coins.erase(player_id)
		player_advantages.erase(player_id)
		print("[GameManager] Player unregistered: %d" % player_id)


func start_match(seed_value: int = -1) -> void:
	if seed_value < 0:
		match_seed = randi()
	else:
		match_seed = seed_value

	# Reset match state
	puzzle_completion_order.clear()
	for player_id in players:
		player_coins[player_id] = 0
		player_advantages[player_id] = []
		players[player_id].puzzles_solved = 0

	print("[GameManager] Match starting with seed: %d" % match_seed)
	change_state(GameState.LOADING)


func on_puzzle_solved(player_id: int, puzzle_id: String, time_taken: float) -> void:
	if not players.has(player_id):
		return

	var player = players[player_id]
	player.puzzles_solved += 1

	# Award coins based on completion order
	var completion_rank = puzzle_completion_order.size()
	var coin_reward = _calculate_coin_reward(completion_rank)
	player_coins[player_id] += coin_reward
	player.coins = player_coins[player_id]

	# Track completion order for this puzzle
	if not puzzle_completion_order.has(player_id):
		puzzle_completion_order.append(player_id)

	# Award advantages for first solver
	if completion_rank == 0:
		_award_first_solver_advantages(player_id, puzzle_id)

	print("[GameManager] Player %d solved puzzle %s in %.2fs (rank: %d, coins: +%d)" % [
		player_id, puzzle_id, time_taken, completion_rank + 1, coin_reward
	])

	puzzle_completed.emit(player_id, puzzle_id, time_taken)


func _calculate_coin_reward(completion_rank: int) -> int:
	# First place gets most coins, decreasing for later finishers
	var base_reward = 100
	var rank_penalty = completion_rank * 20
	return maxi(base_reward - rank_penalty, 20)


func _award_first_solver_advantages(player_id: int, puzzle_id: String) -> void:
	var advantages = player_advantages[player_id]

	# Information advantage: reveal part of the map
	advantages.append("map_reveal_%s" % puzzle_id)

	# Positioning advantage: trap placement token
	if advantages.size() >= 3:
		advantages.append("trap_placement")

	player_advantages[player_id] = advantages
	print("[GameManager] Player %d gained advantages: %s" % [player_id, advantages])


func _start_puzzle_phase() -> void:
	match_start_time = Time.get_ticks_msec() / 1000.0
	puzzle_completion_order.clear()
	print("[GameManager] Puzzle phase started")


func _start_arena_phase() -> void:
	# Calculate final advantages
	for i in puzzle_completion_order.size():
		var player_id = puzzle_completion_order[i]
		if i == 0:
			player_advantages[player_id].append("arena_spawn_choice")
		elif i == puzzle_completion_order.size() - 1:
			# Last place gets a small consolation
			player_coins[player_id] += 50

	print("[GameManager] Arena phase started")


func _handle_game_over() -> void:
	print("[GameManager] Game over")


func get_player_data(player_id: int) -> PlayerData:
	return players.get(player_id, null)


func get_all_players() -> Array:
	return players.values()


func get_match_seed() -> int:
	return match_seed


func is_in_game() -> bool:
	return current_state in [GameState.PUZZLE_PHASE, GameState.ARENA_PHASE]


func add_coins(player_id: int, amount: int) -> void:
	if not players.has(player_id):
		# If no player specified, add to player 1 (single player mode)
		if players.has(1):
			player_id = 1
		else:
			# Register player 1 if not exists
			register_player(1, "Player 1")
			player_id = 1

	player_coins[player_id] = player_coins.get(player_id, 0) + amount
	if players.has(player_id):
		players[player_id].coins = player_coins[player_id]

	print("[GameManager] Player %d coins: +%d (total: %d)" % [player_id, amount, player_coins[player_id]])
	coins_changed.emit(player_id, player_coins[player_id])


func add_coins_local(amount: int) -> void:
	# Add coins to the local player (for single player or when player_id isn't known)
	var local_id = 1
	if NetworkManager and NetworkManager.has_method("get_local_player_id"):
		local_id = NetworkManager.get_local_player_id()
	add_coins(local_id, amount)
