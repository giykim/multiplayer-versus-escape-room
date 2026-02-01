# Steam Multiplayer Integration Guide

This document explains how to integrate Steam networking into the multiplayer puzzle game.

## Overview

Steam provides two networking options:
1. **Steam Networking Sockets** - Low-level P2P networking with NAT traversal
2. **Steam Lobby System** - Matchmaking and session management

## Prerequisites

1. **Steamworks SDK Account** - Register at https://partner.steamgames.com/
2. **GodotSteam Plugin** - https://github.com/GodotSteam/GodotSteam
3. **Steam App ID** - Get from Steamworks dashboard (use 480 for testing)

## Installation Steps

### 1. Install GodotSteam

```bash
# Option A: Download pre-compiled binaries
# Go to https://github.com/GodotSteam/GodotSteam/releases
# Download the version matching your Godot version (4.x)

# Option B: Build from source (for custom modifications)
git clone https://github.com/GodotSteam/GodotSteam
cd GodotSteam
# Follow build instructions for your platform
```

### 2. Project Setup

1. Copy the GodotSteam addon to `addons/godotsteam/`
2. Create `steam_appid.txt` in the project root with your App ID:
   ```
   480
   ```
3. Enable the plugin in Project Settings > Plugins

### 3. Create Steam Network Manager

Create `src/networking/SteamNetworkManager.gd`:

```gdscript
extends Node
class_name SteamNetworkManager

signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_join_failed(reason: String)
signal player_joined_lobby(steam_id: int)
signal player_left_lobby(steam_id: int)
signal p2p_message_received(sender_id: int, data: PackedByteArray)

const LOBBY_TYPE_PRIVATE = 0
const LOBBY_TYPE_FRIENDS_ONLY = 1
const LOBBY_TYPE_PUBLIC = 2

var steam_id: int = 0
var lobby_id: int = 0
var lobby_members: Array[int] = []
var is_host: bool = false

func _ready() -> void:
	if not Steam.steamInitEx():
		push_error("Steam not initialized!")
		return

	steam_id = Steam.getSteamID()
	print("[Steam] Initialized. Steam ID: %d" % steam_id)

	# Connect Steam signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.p2p_session_request.connect(_on_p2p_session_request)


func _process(_delta: float) -> void:
	Steam.run_callbacks()
	_read_p2p_messages()


# Lobby Management

func create_lobby(max_players: int = 4, lobby_type: int = LOBBY_TYPE_FRIENDS_ONLY) -> void:
	print("[Steam] Creating lobby...")
	Steam.createLobby(lobby_type, max_players)


func join_lobby(target_lobby_id: int) -> void:
	print("[Steam] Joining lobby: %d" % target_lobby_id)
	Steam.joinLobby(target_lobby_id)


func leave_lobby() -> void:
	if lobby_id > 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		lobby_members.clear()
		is_host = false


func get_lobby_members() -> Array[int]:
	if lobby_id == 0:
		return []

	var members: Array[int] = []
	var count = Steam.getNumLobbyMembers(lobby_id)
	for i in range(count):
		members.append(Steam.getLobbyMemberByIndex(lobby_id, i))
	return members


# P2P Messaging

func send_p2p_message(target_steam_id: int, data: PackedByteArray, reliable: bool = true) -> bool:
	var send_type = Steam.P2P_SEND_RELIABLE if reliable else Steam.P2P_SEND_UNRELIABLE
	return Steam.sendP2PPacket(target_steam_id, data, send_type)


func broadcast_p2p_message(data: PackedByteArray, reliable: bool = true) -> void:
	for member_id in lobby_members:
		if member_id != steam_id:
			send_p2p_message(member_id, data, reliable)


func _read_p2p_messages() -> void:
	var packet_size = Steam.getAvailableP2PPacketSize()
	while packet_size > 0:
		var packet = Steam.readP2PPacket(packet_size)
		if packet.is_empty():
			break

		var sender_id = packet["steam_id_remote"]
		var data = packet["data"]
		p2p_message_received.emit(sender_id, data)

		packet_size = Steam.getAvailableP2PPacketSize()


# Signal Handlers

func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if result == Steam.RESULT_OK:
		lobby_id = new_lobby_id
		is_host = true
		lobby_members = get_lobby_members()
		print("[Steam] Lobby created: %d" % lobby_id)
		lobby_created.emit(lobby_id)
	else:
		push_error("[Steam] Failed to create lobby: %d" % result)


func _on_lobby_joined(new_lobby_id: int, _permissions: int, _locked: bool, result: int) -> void:
	if result == Steam.RESULT_OK:
		lobby_id = new_lobby_id
		is_host = Steam.getLobbyOwner(lobby_id) == steam_id
		lobby_members = get_lobby_members()
		print("[Steam] Joined lobby: %d (Host: %s)" % [lobby_id, is_host])
		lobby_joined.emit(lobby_id)
	else:
		lobby_join_failed.emit("Join failed: %d" % result)


func _on_lobby_chat_update(this_lobby_id: int, changed_id: int, making_change_id: int, state: int) -> void:
	if this_lobby_id != lobby_id:
		return

	lobby_members = get_lobby_members()

	if state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		player_joined_lobby.emit(changed_id)
	elif state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT or state == Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		player_left_lobby.emit(changed_id)


func _on_p2p_session_request(remote_id: int) -> void:
	# Accept P2P connection from lobby members
	if remote_id in lobby_members:
		Steam.acceptP2PSessionWithUser(remote_id)
```

### 4. Integrate with Existing NetworkManager

Modify `src/autoload/NetworkManager.gd` to support Steam:

```gdscript
# Add at the top of NetworkManager.gd
var use_steam: bool = false
var steam_manager: Node = null

func _ready() -> void:
	# Check if Steam is available
	if ClassDB.class_exists("Steam"):
		steam_manager = load("res://src/networking/SteamNetworkManager.gd").new()
		add_child(steam_manager)
		use_steam = true
		_connect_steam_signals()

func _connect_steam_signals() -> void:
	steam_manager.lobby_created.connect(_on_steam_lobby_created)
	steam_manager.lobby_joined.connect(_on_steam_lobby_joined)
	steam_manager.player_joined_lobby.connect(_on_steam_player_joined)
	steam_manager.player_left_lobby.connect(_on_steam_player_left)
	steam_manager.p2p_message_received.connect(_on_steam_message)

# Add Steam-specific hosting
func host_game_steam(max_players: int = 4) -> void:
	if use_steam:
		steam_manager.create_lobby(max_players)
	else:
		host_game()  # Fallback to ENet

func join_game_steam(lobby_id: int) -> void:
	if use_steam:
		steam_manager.join_lobby(lobby_id)
```

### 5. Message Serialization

Create a protocol for Steam P2P messages:

```gdscript
# src/networking/SteamProtocol.gd
extends RefCounted
class_name SteamProtocol

enum MessageType {
	GAME_STATE_SYNC,
	PLAYER_INPUT,
	PUZZLE_COMPLETED,
	DAMAGE_DEALT,
	PLAYER_DIED,
	CHAT_MESSAGE,
}

static func encode(type: MessageType, data: Dictionary) -> PackedByteArray:
	var payload = {
		"type": type,
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	}
	return var_to_bytes(payload)

static func decode(bytes: PackedByteArray) -> Dictionary:
	return bytes_to_var(bytes)
```

## Steam Lobby Browser

To let players find public lobbies:

```gdscript
func search_lobbies() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game", "puzzle_versus", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_list_received(lobbies: Array) -> void:
	for lobby in lobbies:
		var name = Steam.getLobbyData(lobby, "name")
		var players = Steam.getNumLobbyMembers(lobby)
		var max_players = Steam.getLobbyMemberLimit(lobby)
		print("Found: %s (%d/%d)" % [name, players, max_players])
```

## Testing Without Steam

For development, you can test without Steam:
1. Use the existing ENet-based networking (already implemented)
2. Set `use_steam = false` in NetworkManager
3. Steam features will gracefully fall back to ENet

## Deployment Checklist

1. [ ] Register on Steamworks Partner Program
2. [ ] Create Steam App ID
3. [ ] Configure Steamworks settings (achievements, leaderboards, etc.)
4. [ ] Build with GodotSteam plugin
5. [ ] Test with Steam client running
6. [ ] Submit for Steam review

## Resources

- GodotSteam Documentation: https://godotsteam.com/
- Steamworks Documentation: https://partner.steamgames.com/doc/home
- GodotSteam GitHub: https://github.com/GodotSteam/GodotSteam
- Steam Networking Guide: https://partner.steamgames.com/doc/features/multiplayer
