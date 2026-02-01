extends Control
## MainMenu - Main menu screen for the game
## Handles navigation to lobby, settings, and game exit

@onready var single_player_button: Button = %SinglePlayerButton
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# Connect button signals (with null checks)
	if single_player_button:
		single_player_button.pressed.connect(_on_single_player_pressed)
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Set initial game state
	if GameManager:
		GameManager.change_state(GameManager.GameState.MENU)

	# Play menu music
	if AudioManager:
		AudioManager.play_music(AudioManager.MusicTrack.MENU)

	print("[MainMenu] Ready")


func _on_single_player_pressed() -> void:
	if AudioManager:
		AudioManager.play_ui_click()

	# Register single player
	if GameManager:
		GameManager.register_player(1, "Player")
		GameManager.start_match(randi())

	# Go directly to game scene
	get_tree().change_scene_to_file("res://src/Game3D.tscn")


func _on_host_pressed() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	_go_to_lobby(true)


func _on_join_pressed() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	_go_to_lobby(false)


func _on_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	# TODO: Open settings menu
	print("[MainMenu] Settings not yet implemented")


func _on_quit_pressed() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	# Small delay to let the click sound play
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


func _go_to_lobby(as_host: bool) -> void:
	# Store hosting preference for lobby to use
	var lobby_scene = load("res://src/ui/Lobby.tscn")
	var lobby_instance = lobby_scene.instantiate()
	lobby_instance.is_hosting = as_host

	get_tree().root.add_child(lobby_instance)
	queue_free()
