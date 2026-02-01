extends BaseTest
## TestCombatSystem - Unit tests for combat mechanics

var combat_script: Script
var weapon_script: Script
var sword_script: Script
var bow_script: Script


func setup() -> void:
	combat_script = load("res://src/combat/CombatSystem.gd") if ResourceLoader.exists("res://src/combat/CombatSystem.gd") else null
	weapon_script = load("res://src/combat/Weapon.gd") if ResourceLoader.exists("res://src/combat/Weapon.gd") else null
	sword_script = load("res://src/combat/Weapons/Sword.gd") if ResourceLoader.exists("res://src/combat/Weapons/Sword.gd") else null
	bow_script = load("res://src/combat/Weapons/Bow.gd") if ResourceLoader.exists("res://src/combat/Weapons/Bow.gd") else null


func get_test_methods() -> Array[String]:
	return [
		"test_combat_system_exists",
		"test_combat_has_health_management",
		"test_combat_has_damage_system",
		"test_combat_has_death_handling",
		"test_combat_has_respawn_system",
		"test_combat_has_network_sync",
		"test_weapon_base_class_exists",
		"test_sword_weapon_exists",
		"test_bow_weapon_exists",
		"test_combat_multiplayer_null_safety",
	]


func test_combat_system_exists() -> Dictionary:
	return assert_not_null(combat_script, "CombatSystem.gd should exist")


func test_combat_has_health_management() -> Dictionary:
	if not combat_script:
		return {"passed": false, "message": "CombatSystem not loaded"}

	var source = combat_script.source_code
	var has_health = "player_health" in source
	var has_max_health = "MAX_HEALTH" in source
	var has_get_health = "get_health" in source
	var has_heal = "heal_player" in source

	var passed = has_health and has_max_health and has_get_health and has_heal
	return {
		"passed": passed,
		"message": "Health management present" if passed else "Missing health management"
	}


func test_combat_has_damage_system() -> Dictionary:
	if not combat_script:
		return {"passed": false, "message": "CombatSystem not loaded"}

	var source = combat_script.source_code
	var has_deal_damage = "deal_damage" in source
	var has_damage_signal = "signal damage_dealt" in source
	var has_invincibility = "player_invincibility" in source or "INVINCIBILITY_DURATION" in source

	var passed = has_deal_damage and has_damage_signal and has_invincibility
	return {
		"passed": passed,
		"message": "Damage system present" if passed else "Missing damage components"
	}


func test_combat_has_death_handling() -> Dictionary:
	if not combat_script:
		return {"passed": false, "message": "CombatSystem not loaded"}

	var source = combat_script.source_code
	var has_death = "_on_player_death" in source
	var has_death_signal = "signal player_died" in source
	var has_is_alive = "is_alive" in source

	var passed = has_death and has_death_signal and has_is_alive
	return {
		"passed": passed,
		"message": "Death handling present" if passed else "Missing death handling"
	}


func test_combat_has_respawn_system() -> Dictionary:
	if not combat_script:
		return {"passed": false, "message": "CombatSystem not loaded"}

	var source = combat_script.source_code
	var has_respawn = "_respawn_player" in source
	var has_respawn_signal = "signal player_respawned" in source
	var has_respawn_delay = "RESPAWN_DELAY" in source
	var has_respawn_points = "respawn_points" in source

	var passed = has_respawn and has_respawn_signal and has_respawn_delay
	return {
		"passed": passed,
		"message": "Respawn system present" if passed else "Missing respawn components"
	}


func test_combat_has_network_sync() -> Dictionary:
	if not combat_script:
		return {"passed": false, "message": "CombatSystem not loaded"}

	var source = combat_script.source_code
	var has_rpc = "@rpc" in source
	var has_sync_damage = "_sync_damage" in source
	var has_sync_death = "_sync_death" in source
	var has_request_damage = "request_damage" in source

	var passed = has_rpc and has_sync_damage and has_sync_death
	return {
		"passed": passed,
		"message": "Network sync present" if passed else "Missing network sync"
	}


func test_weapon_base_class_exists() -> Dictionary:
	return assert_not_null(weapon_script, "Weapon.gd base class should exist")


func test_sword_weapon_exists() -> Dictionary:
	if not sword_script:
		return {"passed": false, "message": "Sword.gd not found"}

	var source = sword_script.source_code
	var extends_weapon = "extends Weapon" in source
	var has_swing = "swing" in source.to_lower()
	var has_hitbox = "hitbox" in source.to_lower()

	var passed = extends_weapon and has_swing and has_hitbox
	return {
		"passed": passed,
		"message": "Sword weapon properly configured" if passed else "Sword missing components"
	}


func test_bow_weapon_exists() -> Dictionary:
	if not bow_script:
		return {"passed": false, "message": "Bow.gd not found"}

	var source = bow_script.source_code
	var extends_weapon = "extends Weapon" in source
	var has_charge = "charge" in source.to_lower()
	var has_projectile = "projectile" in source.to_lower()

	var passed = extends_weapon and has_charge and has_projectile
	return {
		"passed": passed,
		"message": "Bow weapon properly configured" if passed else "Bow missing components"
	}


func test_combat_multiplayer_null_safety() -> Dictionary:
	if not combat_script:
		return {"passed": false, "message": "CombatSystem not loaded"}

	var source = combat_script.source_code
	var has_null_check = "if multiplayer and multiplayer.has_multiplayer_peer()" in source

	return {
		"passed": has_null_check,
		"message": "Multiplayer null safety present" if has_null_check else "Missing multiplayer null checks"
	}
