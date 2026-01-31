extends Room
class_name ArenaRoom
## ArenaRoom - Final showdown room where players fight
## Handles spawn positions based on advantages, combat phase, and victory conditions

signal arena_started()
signal arena_ended(winner_id: int)
signal player_eliminated(player_id: int)

# Arena configuration
@export var arena_countdown: float = 5.0  # Countdown before combat starts
@export var combat_time_limit: float = 180.0  # 3 minutes max combat time
@export var spawn_positions: Array[Vector2] = [
	Vector2(-300, 0),   # Position 1 (best - center left)
	Vector2(300, 0),    # Position 2 (center right)
	Vector2(-300, 200), # Position 3 (back left)
	Vector2(300, 200),  # Position 4 (back right)
]

# Arena state
var arena_active: bool = false
var countdown_remaining: float = 0.0
var combat_time_remaining: float = 0.0
var player_spawn_order: Array[int] = []  # Ordered by advantages
var eliminated_players: Array[int] = []
var combat_system: CombatSystem = null

# UI elements
var countdown_label: Label = null
var timer_label: Label = null


func _ready() -> void:
	super._ready()
	room_type = RoomType.ARENA

	# Arena doesn't have doors - it's the end
	has_left_door = true
	has_right_door = false
	doors_locked["left"] = true
	doors_locked["right"] = true

	_setup_arena_ui()
	print("[ArenaRoom] Initialized")


func _process(delta: float) -> void:
	if countdown_remaining > 0:
		countdown_remaining -= delta
		_update_countdown_ui()
		if countdown_remaining <= 0:
			_start_combat()
	elif arena_active:
		combat_time_remaining -= delta
		_update_timer_ui()
		if combat_time_remaining <= 0:
			_end_combat_timeout()


func _setup_arena_ui() -> void:
	# Create countdown label
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 72)
	countdown_label.add_theme_color_override("font_color", Color.WHITE)
	countdown_label.position = Vector2(ROOM_WIDTH / 2 - 100, ROOM_HEIGHT / 2 - 50)
	countdown_label.size = Vector2(200, 100)
	countdown_label.visible = false
	add_child(countdown_label)

	# Create combat timer label
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.position = Vector2(ROOM_WIDTH / 2 - 50, 20)
	timer_label.size = Vector2(100, 40)
	timer_label.visible = false
	add_child(timer_label)


func activate() -> void:
	# Override - arena starts countdown instead of puzzle
	print("[ArenaRoom] Arena activated - preparing for combat")
	_prepare_arena()


func _prepare_arena() -> void:
	# Determine spawn order based on player advantages
	_calculate_spawn_order()

	# Position players at spawn points
	_position_players()

	# Setup combat system
	_setup_combat()

	# Start countdown
	countdown_remaining = arena_countdown
	countdown_label.visible = true

	AudioManager.play_music(AudioManager.MusicTrack.ARENA)


func _calculate_spawn_order() -> void:
	player_spawn_order.clear()

	# Get all players and their advantages
	var player_advantages: Array = []
	for player_id in GameManager.players:
		var advantages = GameManager.player_advantages.get(player_id, [])
		var has_spawn_choice = "arena_spawn_choice" in advantages
		var advantage_count = advantages.size()
		player_advantages.append({
			"id": player_id,
			"has_spawn_choice": has_spawn_choice,
			"advantage_count": advantage_count
		})

	# Sort: players with spawn_choice first, then by advantage count
	player_advantages.sort_custom(func(a, b):
		if a.has_spawn_choice != b.has_spawn_choice:
			return a.has_spawn_choice  # spawn_choice goes first
		return a.advantage_count > b.advantage_count
	)

	for p in player_advantages:
		player_spawn_order.append(p.id)

	print("[ArenaRoom] Spawn order: %s" % str(player_spawn_order))


func _position_players() -> void:
	for i in player_spawn_order.size():
		var player_id = player_spawn_order[i]
		var spawn_pos = spawn_positions[i % spawn_positions.size()]

		# Get player node and position it
		var player = _get_player_node(player_id)
		if player:
			player.global_position = global_position + spawn_pos
			print("[ArenaRoom] Player %d spawned at position %d" % [player_id, i])


func _get_player_node(player_id: int) -> Node2D:
	# Try to find player in scene tree
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get_player_id") and player.get_player_id() == player_id:
			return player
		if player.get("player_id") == player_id:
			return player
	return null


func _setup_combat() -> void:
	# Find or create CombatSystem
	combat_system = get_node_or_null("/root/CombatSystem")
	if not combat_system:
		combat_system = CombatSystem.new()
		combat_system.name = "CombatSystem"
		get_tree().root.add_child(combat_system)

	# Register all players with combat system
	for player_id in player_spawn_order:
		var player_node = _get_player_node(player_id)
		combat_system.register_player(player_id, player_node)

	# Connect to death signal
	if not combat_system.player_died.is_connected(_on_player_died):
		combat_system.player_died.connect(_on_player_died)

	# Set respawn points (in arena, no respawn - just track death)
	combat_system.respawn_points = []  # Empty = no respawn


func _update_countdown_ui() -> void:
	if countdown_label:
		if countdown_remaining > 1:
			countdown_label.text = str(ceili(countdown_remaining))
		elif countdown_remaining > 0:
			countdown_label.text = "FIGHT!"
		else:
			countdown_label.visible = false


func _update_timer_ui() -> void:
	if timer_label:
		var minutes = int(combat_time_remaining) / 60
		var seconds = int(combat_time_remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]

		# Flash red when low time
		if combat_time_remaining < 30:
			timer_label.add_theme_color_override("font_color", Color.RED)


func _start_combat() -> void:
	arena_active = true
	combat_time_remaining = combat_time_limit
	timer_label.visible = true

	# Enable player combat controls
	for player_id in player_spawn_order:
		var player = _get_player_node(player_id)
		if player and player.has_method("enable_combat"):
			player.enable_combat(true)

	print("[ArenaRoom] Combat started!")
	arena_started.emit()


func _on_player_died(player_id: int, killer_id: int) -> void:
	if player_id in eliminated_players:
		return

	eliminated_players.append(player_id)
	print("[ArenaRoom] Player %d eliminated by player %d" % [player_id, killer_id])
	player_eliminated.emit(player_id)

	# Check for winner
	_check_victory_condition()


func _check_victory_condition() -> void:
	var alive_players: Array[int] = []
	for player_id in player_spawn_order:
		if player_id not in eliminated_players:
			alive_players.append(player_id)

	if alive_players.size() == 1:
		# We have a winner!
		_end_combat_victory(alive_players[0])
	elif alive_players.size() == 0:
		# Everyone dead? Shouldn't happen but handle it
		_end_combat_draw()


func _end_combat_victory(winner_id: int) -> void:
	arena_active = false
	timer_label.visible = false

	print("[ArenaRoom] Player %d wins!" % winner_id)

	# Show victory message
	countdown_label.text = "WINNER!"
	countdown_label.add_theme_color_override("font_color", Color.GOLD)
	countdown_label.visible = true

	AudioManager.play_music(AudioManager.MusicTrack.VICTORY)

	arena_ended.emit(winner_id)

	# Notify GameManager
	GameManager.change_state(GameManager.GameState.GAME_OVER)


func _end_combat_timeout() -> void:
	arena_active = false

	# Find player with most health
	var winner_id = -1
	var highest_health = -1

	for player_id in player_spawn_order:
		if player_id in eliminated_players:
			continue
		var health = combat_system.player_health.get(player_id, 0)
		if health > highest_health:
			highest_health = health
			winner_id = player_id

	if winner_id >= 0:
		print("[ArenaRoom] Time's up! Player %d wins with %d health" % [winner_id, highest_health])
		_end_combat_victory(winner_id)
	else:
		_end_combat_draw()


func _end_combat_draw() -> void:
	arena_active = false
	timer_label.visible = false

	print("[ArenaRoom] Draw - no winner")

	countdown_label.text = "DRAW"
	countdown_label.add_theme_color_override("font_color", Color.GRAY)
	countdown_label.visible = true

	arena_ended.emit(-1)
	GameManager.change_state(GameManager.GameState.GAME_OVER)


func on_player_enter(player_id: int) -> void:
	super.on_player_enter(player_id)

	# When first player enters, wait for others (short delay) then start
	if players_in_room.size() == 1:
		# In single player, start immediately
		if not NetworkManager.is_multiplayer_active():
			activate()
		else:
			# Wait for other players
			_start_player_wait_timer()


func _start_player_wait_timer() -> void:
	# Give other players 10 seconds to arrive
	await get_tree().create_timer(10.0).timeout
	if not arena_active and players_in_room.size() > 0:
		activate()


func get_player_spawn_position() -> Vector2:
	# Return center of arena for initial positioning
	return global_position + Vector2(0, 0)
