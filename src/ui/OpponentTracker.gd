extends Control
class_name OpponentTracker
## OpponentTracker - Shows opponent progress through the dungeon
## Displays room position, puzzle status, and coins for each opponent

signal opponent_finished_puzzle(player_id: int)
signal opponent_entered_room(player_id: int, room_index: int)

# UI container for opponent entries
@onready var entries_container: VBoxContainer = $VBox/EntriesContainer

# Track opponent data
var opponent_entries: Dictionary = {}  # player_id -> OpponentEntry node
var local_player_id: int = 0

# Colors for status
const COLOR_AHEAD: Color = Color(0.8, 0.3, 0.3)  # Red - opponent ahead
const COLOR_BEHIND: Color = Color(0.3, 0.8, 0.3)  # Green - opponent behind
const COLOR_SAME: Color = Color(0.8, 0.8, 0.3)    # Yellow - same room


func _ready() -> void:
	# Connect to game signals
	if GameManager:
		GameManager.puzzle_completed.connect(_on_puzzle_completed)

	if NetworkManager:
		NetworkManager.lobby_updated.connect(_on_lobby_updated)


func initialize(player_id: int) -> void:
	local_player_id = player_id
	_refresh_opponent_list()


func _refresh_opponent_list() -> void:
	# Clear existing entries
	if entries_container:
		for child in entries_container.get_children():
			child.queue_free()
	opponent_entries.clear()

	# Create entry for each opponent
	if not GameManager:
		return
	for player_id in GameManager.players:
		if player_id == local_player_id:
			continue
		_create_opponent_entry(player_id)


func _create_opponent_entry(player_id: int) -> void:
	if not entries_container:
		return
	var entry = _build_entry_ui(player_id)
	entries_container.add_child(entry)
	opponent_entries[player_id] = entry


func _build_entry_ui(player_id: int) -> Control:
	var player_data = GameManager.get_player_data(player_id)
	var player_name = player_data.display_name if player_data else "Player %d" % player_id

	var container = PanelContainer.new()
	container.name = "Opponent_%d" % player_id
	container.custom_minimum_size = Vector2(200, 60)

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	container.add_child(vbox)

	# Player name row
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = player_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", player_data.color if player_data else Color.WHITE)
	vbox.add_child(name_label)

	# Progress row
	var progress_row = HBoxContainer.new()
	progress_row.name = "ProgressRow"
	vbox.add_child(progress_row)

	var room_label = Label.new()
	room_label.name = "RoomLabel"
	room_label.text = "Room: 1"
	room_label.add_theme_font_size_override("font_size", 12)
	room_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	progress_row.add_child(room_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(spacer)

	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Exploring"
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	progress_row.add_child(status_label)

	# Coins row
	var coins_row = HBoxContainer.new()
	coins_row.name = "CoinsRow"
	vbox.add_child(coins_row)

	var coins_icon = Label.new()
	coins_icon.text = "$"
	coins_icon.add_theme_font_size_override("font_size", 12)
	coins_icon.add_theme_color_override("font_color", Color(1, 0.843, 0))
	coins_row.add_child(coins_icon)

	var coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	coins_label.text = "0"
	coins_label.add_theme_font_size_override("font_size", 12)
	coins_row.add_child(coins_label)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coins_row.add_child(spacer2)

	var puzzles_label = Label.new()
	puzzles_label.name = "PuzzlesLabel"
	puzzles_label.text = "Puzzles: 0"
	puzzles_label.add_theme_font_size_override("font_size", 12)
	puzzles_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	coins_row.add_child(puzzles_label)

	return container


func update_opponent(player_id: int, room_index: int, status: String, coins: int, puzzles_solved: int) -> void:
	if not opponent_entries.has(player_id):
		return

	var entry = opponent_entries[player_id]

	# Update room label
	var room_label = entry.get_node("VBoxContainer/ProgressRow/RoomLabel") if entry.has_node("VBoxContainer/ProgressRow/RoomLabel") else null
	if room_label:
		room_label.text = "Room: %d" % (room_index + 1)

	# Update status
	var status_label = entry.get_node("VBoxContainer/ProgressRow/StatusLabel") if entry.has_node("VBoxContainer/ProgressRow/StatusLabel") else null
	if status_label:
		status_label.text = status

	# Update coins
	var coins_label = entry.get_node("VBoxContainer/CoinsRow/CoinsLabel") if entry.has_node("VBoxContainer/CoinsRow/CoinsLabel") else null
	if coins_label:
		coins_label.text = str(coins)

	# Update puzzles
	var puzzles_label = entry.get_node("VBoxContainer/CoinsRow/PuzzlesLabel") if entry.has_node("VBoxContainer/CoinsRow/PuzzlesLabel") else null
	if puzzles_label:
		puzzles_label.text = "Puzzles: %d" % puzzles_solved

	# Update color based on relative position
	_update_entry_color(player_id, room_index)


func _update_entry_color(player_id: int, opponent_room: int) -> void:
	if not opponent_entries.has(player_id):
		return

	# Get local player's room (from dungeon if available)
	var local_room = 0
	var dungeon = get_tree().get_first_node_in_group("dungeon")
	if dungeon and dungeon.has_method("get") and dungeon.get("current_room_index") != null:
		local_room = dungeon.current_room_index

	var entry = opponent_entries[player_id]
	var style = entry.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	if opponent_room > local_room:
		style.border_color = COLOR_AHEAD
		style.border_width_left = 3
	elif opponent_room < local_room:
		style.border_color = COLOR_BEHIND
		style.border_width_left = 3
	else:
		style.border_color = COLOR_SAME
		style.border_width_left = 3

	entry.add_theme_stylebox_override("panel", style)


func _on_puzzle_completed(player_id: int, puzzle_id: String, time_taken: float) -> void:
	if player_id == local_player_id:
		return

	opponent_finished_puzzle.emit(player_id)

	# Update that opponent's status
	var player_data = GameManager.get_player_data(player_id)
	if player_data:
		var room_index = 0  # Would need to track per-player
		update_opponent(player_id, room_index, "Solved!", player_data.coins, player_data.puzzles_solved)


func _on_lobby_updated(_players: Array) -> void:
	_refresh_opponent_list()


# Called by network sync to update opponent positions
@rpc("any_peer", "reliable")
func sync_player_progress(player_id: int, room_index: int, status: String, coins: int, puzzles: int) -> void:
	update_opponent(player_id, room_index, status, coins, puzzles)
	opponent_entered_room.emit(player_id, room_index)


# Broadcast local player's progress to opponents
func broadcast_progress(room_index: int, status: String) -> void:
	if not NetworkManager or not NetworkManager.is_multiplayer_active():
		return

	var coins = 0
	var puzzles = 0
	if GameManager:
		coins = GameManager.player_coins.get(local_player_id, 0)
		var player_data = GameManager.get_player_data(local_player_id)
		puzzles = player_data.puzzles_solved if player_data else 0

	sync_player_progress.rpc(local_player_id, room_index, status, coins, puzzles)
