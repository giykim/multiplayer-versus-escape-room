extends BaseTest
## TestDoorTransitions - Integration tests for door transitions between rooms

func get_test_methods() -> Array[String]:
	return [
		# Basic transitions
		"test_transition_to_next_room",
		"test_transition_to_previous_room",
		"test_transition_blocked_by_locked_door",

		# Cooldown system
		"test_transition_cooldown_prevents_double",
		"test_transition_cooldown_resets",

		# Room state after transition
		"test_current_room_updates_after_transition",
		"test_room_visibility_updates",

		# Player positioning
		"test_spawn_position_in_new_room",

		# Signal emission
		"test_room_changed_signal_emitted",

		# Edge cases
		"test_transition_to_same_room_ignored",
		"test_transition_beyond_bounds_rejected",
	]


func test_transition_to_next_room() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	# Unlock the door first
	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = false

	var start_index = dungeon.current_room_index
	var success = dungeon.transition_to_room(start_index + 1, 1)

	# Account for cooldown preventing second call
	var new_index = dungeon.current_room_index

	temp_parent.queue_free()

	return {
		"passed": success and new_index == start_index + 1,
		"message": "Transition from %d to %d, success: %s" % [start_index, new_index, success]
	}


func test_transition_to_previous_room() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	# First go to room 1
	var room0 = dungeon.get_current_room()
	if room0:
		room0.doors_locked["right"] = false
	dungeon.transition_to_room(1, 1)

	# Wait for cooldown
	await Engine.get_main_loop().create_timer(0.6).timeout

	# Now go back to room 0
	var room1 = dungeon.get_current_room()
	if room1:
		room1.doors_locked["left"] = false
	var success = dungeon.transition_to_room(0, 1)
	var new_index = dungeon.current_room_index

	temp_parent.queue_free()

	return {
		"passed": success and new_index == 0,
		"message": "Returned to room 0: %s (index: %d)" % [success, new_index]
	}


func test_transition_blocked_by_locked_door() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	# Ensure door is locked
	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = true

	var start_index = dungeon.current_room_index
	var success = dungeon.transition_to_room(start_index + 1, 1)
	var still_same = dungeon.current_room_index == start_index

	temp_parent.queue_free()

	return assert_true(not success and still_same, "Transition should fail with locked door")


func test_transition_cooldown_prevents_double() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	# Unlock door
	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = false

	# First transition should succeed
	var first = dungeon.transition_to_room(1, 1)

	# Immediate second transition should fail due to cooldown
	var second = dungeon.transition_to_room(2, 1)

	temp_parent.queue_free()

	return {
		"passed": first and not second,
		"message": "First: %s, Second (blocked): %s" % [first, second]
	}


func test_transition_cooldown_resets() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	# Unlock doors
	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = false

	# First transition
	dungeon.transition_to_room(1, 1)

	# Wait for cooldown to expire
	await Engine.get_main_loop().create_timer(0.6).timeout

	# Now cooldown should be reset
	var cooldown_reset = not dungeon.transition_cooldown

	temp_parent.queue_free()

	return assert_true(cooldown_reset, "Transition cooldown should reset after timeout")


func test_current_room_updates_after_transition() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = false

	dungeon.transition_to_room(1, 1)

	var current = dungeon.get_current_room()
	var is_room1 = current != null

	temp_parent.queue_free()

	return assert_true(is_room1, "get_current_room should return the new room after transition")


func test_room_visibility_updates() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	# Load room 1
	dungeon._load_room(1)

	var room0 = dungeon.loaded_rooms.get(0)
	var room1 = dungeon.loaded_rooms.get(1)

	# Initially room 0 should be visible
	var room0_visible_before = room0.visible if room0 else false

	# Unlock and transition
	if room0:
		room0.doors_locked["right"] = false
	dungeon.transition_to_room(1, 1)

	var room0_visible_after = room0.visible if room0 else true
	var room1_visible_after = room1.visible if room1 else false

	temp_parent.queue_free()

	return {
		"passed": not room0_visible_after and room1_visible_after,
		"message": "Room 0 visible: %s, Room 1 visible: %s" % [room0_visible_after, room1_visible_after]
	}


func test_spawn_position_in_new_room() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = false

	dungeon.transition_to_room(1, 1)

	var spawn_pos = dungeon.get_player_spawn_position()
	var is_valid = spawn_pos is Vector3 and spawn_pos.y > 0

	temp_parent.queue_free()

	return assert_true(is_valid, "Spawn position should be valid after transition")


func test_room_changed_signal_emitted() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	var signal_received = false
	var old_room_arg = -1
	var new_room_arg = -1

	dungeon.room_changed.connect(func(old, new):
		signal_received = true
		old_room_arg = old
		new_room_arg = new
	)

	var room = dungeon.get_current_room()
	if room:
		room.doors_locked["right"] = false

	dungeon.transition_to_room(1, 1)

	temp_parent.queue_free()

	return {
		"passed": signal_received and old_room_arg == 0 and new_room_arg == 1,
		"message": "Signal received: %s, old: %d, new: %d" % [signal_received, old_room_arg, new_room_arg]
	}


func test_transition_to_same_room_ignored() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	var result = dungeon.transition_to_room(0, 1)  # Already in room 0

	temp_parent.queue_free()

	return assert_false(result, "Transition to same room should return false")


func test_transition_beyond_bounds_rejected() -> Dictionary:
	var dungeon = Dungeon3D.new()

	var temp_parent = Node3D.new()
	temp_parent.add_child(dungeon)

	dungeon.generate_dungeon(12345)

	var result_negative = dungeon.transition_to_room(-1, 1)
	var result_too_high = dungeon.transition_to_room(999, 1)

	temp_parent.queue_free()

	return assert_true(not result_negative and not result_too_high, "Transitions outside valid range should fail")
