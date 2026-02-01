extends CanvasLayer
## HUD - In-game heads-up display
## Shows coins, timer, puzzle progress, and player advantages

@onready var coin_label: Label = %CoinLabel
@onready var timer_label: Label = %TimerLabel
@onready var puzzle_progress: Label = %PuzzleProgress
@onready var advantages_container: VBoxContainer = %AdvantagesContainer
@onready var minimap_container: Control = %MinimapContainer

# Timer state
var match_time: float = 0.0
var timer_running: bool = false

# Local player tracking
var local_player_id: int = 0


func _ready() -> void:
	# Connect to GameManager signals
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)
		GameManager.puzzle_completed.connect(_on_puzzle_completed)

	# Initialize display
	_update_coins(0)
	_update_timer(0.0)
	_update_puzzle_progress(0, 0)

	print("[HUD] Ready")


func _process(delta: float) -> void:
	if timer_running:
		match_time += delta
		_update_timer(match_time)


func initialize(player_id: int) -> void:
	local_player_id = player_id

	# Get initial player data
	var player_data = GameManager.get_player_data(player_id)
	if player_data:
		_update_coins(player_data.coins)


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PUZZLE_PHASE:
			timer_running = true
			match_time = 0.0
			visible = true
		GameManager.GameState.ARENA_PHASE:
			timer_running = false
			_show_arena_hud()
		GameManager.GameState.GAME_OVER:
			timer_running = false
		_:
			timer_running = false


func _on_puzzle_completed(player_id: int, puzzle_id: String, time_taken: float) -> void:
	if player_id == local_player_id:
		# Update local player's display
		var player_data = GameManager.get_player_data(player_id)
		if player_data:
			_update_coins(player_data.coins)
			_update_advantages(GameManager.player_advantages.get(player_id, []))

		# Flash puzzle completion
		_flash_puzzle_complete()


func _update_coins(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)


func _update_timer(time: float) -> void:
	if not timer_label:
		return
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	timer_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


func _update_puzzle_progress(solved: int, total: int) -> void:
	if not puzzle_progress:
		return
	if total > 0:
		puzzle_progress.text = "Puzzles: %d/%d" % [solved, total]
	else:
		puzzle_progress.text = "Puzzles: --"


func _update_advantages(advantages: Array) -> void:
	# Clear existing
	if not advantages_container:
		return

	for child in advantages_container.get_children():
		child.queue_free()

	# Add advantage indicators
	for advantage in advantages:
		var label = Label.new()
		label.text = _get_advantage_display_name(advantage)
		label.add_theme_color_override("font_color", Color(0.494, 0.851, 0.341))
		label.add_theme_font_size_override("font_size", 12)
		advantages_container.add_child(label)


func _get_advantage_display_name(advantage: String) -> String:
	if advantage.begins_with("map_reveal"):
		return "Map Reveal"
	elif advantage == "trap_placement":
		return "Trap Token"
	elif advantage == "arena_spawn_choice":
		return "Spawn Choice"
	else:
		return advantage.capitalize()


func _flash_puzzle_complete() -> void:
	# Visual feedback for puzzle completion
	if puzzle_progress:
		var tween = create_tween()
		tween.tween_property(puzzle_progress, "modulate", Color(0.494, 0.851, 0.341), 0.1)
		tween.tween_property(puzzle_progress, "modulate", Color.WHITE, 0.3)

	if AudioManager:
		AudioManager.play_puzzle_solve()


func _show_arena_hud() -> void:
	# Modify HUD for arena phase
	if puzzle_progress:
		puzzle_progress.text = "ARENA"
		puzzle_progress.add_theme_color_override("font_color", Color(0.851, 0.341, 0.341))


func show_message(text: String, duration: float = 2.0) -> void:
	# TODO: Implement floating message system
	print("[HUD] Message: %s" % text)


func set_minimap_visible(visible_state: bool) -> void:
	if minimap_container:
		minimap_container.visible = visible_state
