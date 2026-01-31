extends Node
## AudioManager - Audio singleton for music and sound effects

signal music_changed(track_name: String)

enum MusicTrack {
	NONE,
	MENU,
	LOBBY,
	PUZZLE,
	ARENA,
	VICTORY,
	DEFEAT
}

# Audio bus names
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

# Volume settings (in dB)
var master_volume: float = 0.0
var music_volume: float = -6.0
var sfx_volume: float = 0.0

# Current music state
var current_track: MusicTrack = MusicTrack.NONE
var music_player: AudioStreamPlayer = null

# SFX pool for overlapping sounds
var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 8


func _ready() -> void:
	_setup_audio_buses()
	_setup_music_player()
	_setup_sfx_pool()
	print("[AudioManager] Initialized")


func _setup_audio_buses() -> void:
	# Ensure audio buses exist (they should be created in Godot editor)
	# This just applies default volumes
	_set_bus_volume(BUS_MASTER, master_volume)
	if AudioServer.get_bus_index(BUS_MUSIC) != -1:
		_set_bus_volume(BUS_MUSIC, music_volume)
	if AudioServer.get_bus_index(BUS_SFX) != -1:
		_set_bus_volume(BUS_SFX, sfx_volume)


func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	add_child(music_player)


func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		sfx_pool.append(player)


func play_music(track: MusicTrack, fade_duration: float = 1.0) -> void:
	if track == current_track:
		return

	current_track = track

	# TODO: Load actual music tracks
	# For now, just stop any playing music
	if track == MusicTrack.NONE:
		_fade_out_music(fade_duration)
		return

	var track_path = _get_track_path(track)
	if track_path.is_empty():
		return

	# Check if file exists before loading
	if not ResourceLoader.exists(track_path):
		push_warning("[AudioManager] Music file not found: %s" % track_path)
		return

	var stream = load(track_path)
	if stream:
		if music_player.playing:
			_crossfade_music(stream, fade_duration)
		else:
			music_player.stream = stream
			music_player.play()

		music_changed.emit(MusicTrack.keys()[track])


func _get_track_path(track: MusicTrack) -> String:
	# TODO: Map tracks to actual audio files
	match track:
		MusicTrack.MENU:
			return "res://assets/audio/music_menu.ogg"
		MusicTrack.LOBBY:
			return "res://assets/audio/music_lobby.ogg"
		MusicTrack.PUZZLE:
			return "res://assets/audio/music_puzzle.ogg"
		MusicTrack.ARENA:
			return "res://assets/audio/music_arena.ogg"
		MusicTrack.VICTORY:
			return "res://assets/audio/music_victory.ogg"
		MusicTrack.DEFEAT:
			return "res://assets/audio/music_defeat.ogg"
	return ""


func _fade_out_music(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, duration)
	tween.tween_callback(music_player.stop)


func _crossfade_music(new_stream: AudioStream, duration: float) -> void:
	# Simple crossfade implementation
	_fade_out_music(duration / 2)
	await get_tree().create_timer(duration / 2).timeout
	music_player.stream = new_stream
	music_player.volume_db = music_volume
	music_player.play()


func play_sfx(sound_path: String, volume_offset: float = 0.0, pitch_variance: float = 0.0) -> void:
	var stream = load(sound_path)
	if not stream:
		push_warning("[AudioManager] Sound not found: %s" % sound_path)
		return

	# Find available player in pool
	var player = _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = sfx_volume + volume_offset

		if pitch_variance > 0:
			player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
		else:
			player.pitch_scale = 1.0

		player.play()


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_pool:
		if not player.playing:
			return player

	# All players busy, reuse the first one
	return sfx_pool[0]


# Common sound effect shortcuts
func play_ui_click() -> void:
	play_sfx("res://assets/audio/sfx_ui_click.ogg")


func play_puzzle_solve() -> void:
	play_sfx("res://assets/audio/sfx_puzzle_solve.ogg", 3.0)


func play_coin_collect() -> void:
	play_sfx("res://assets/audio/sfx_coin.ogg", 0.0, 0.1)


func play_damage() -> void:
	play_sfx("res://assets/audio/sfx_damage.ogg", 0.0, 0.15)


# Volume controls
func set_master_volume(volume_db: float) -> void:
	master_volume = volume_db
	_set_bus_volume(BUS_MASTER, volume_db)


func set_music_volume(volume_db: float) -> void:
	music_volume = volume_db
	_set_bus_volume(BUS_MUSIC, volume_db)


func set_sfx_volume(volume_db: float) -> void:
	sfx_volume = volume_db
	_set_bus_volume(BUS_SFX, volume_db)


func _set_bus_volume(bus_name: String, volume_db: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)


func toggle_mute() -> void:
	var bus_idx = AudioServer.get_bus_index(BUS_MASTER)
	if bus_idx != -1:
		var is_muted = AudioServer.is_bus_mute(bus_idx)
		AudioServer.set_bus_mute(bus_idx, not is_muted)
