extends BaseTest
## TestItems - Unit tests for item and pickup systems

var item_script: Script
var coin_script: Script
var health_script: Script
var weapon_pickup_script: Script


func setup() -> void:
	item_script = load("res://src/items/Item.gd") if ResourceLoader.exists("res://src/items/Item.gd") else null
	coin_script = load("res://src/items/CoinPickup.gd") if ResourceLoader.exists("res://src/items/CoinPickup.gd") else null
	health_script = load("res://src/items/HealthPickup.gd") if ResourceLoader.exists("res://src/items/HealthPickup.gd") else null
	weapon_pickup_script = load("res://src/items/WeaponPickup.gd") if ResourceLoader.exists("res://src/items/WeaponPickup.gd") else null


func get_test_methods() -> Array[String]:
	return [
		"test_item_base_exists",
		"test_item_has_pickup_signal",
		"test_item_has_visual_effects",
		"test_item_has_network_sync",
		"test_coin_pickup_exists",
		"test_health_pickup_exists",
		"test_weapon_pickup_exists",
		"test_item_multiplayer_null_safety",
	]


func test_item_base_exists() -> Dictionary:
	return assert_not_null(item_script, "Item.gd should exist")


func test_item_has_pickup_signal() -> Dictionary:
	if not item_script:
		return {"passed": false, "message": "Item not loaded"}

	var source = item_script.source_code
	var has_signal = "signal item_picked_up" in source
	var has_pickup_method = "_do_pickup" in source or "pickup" in source.to_lower()

	var passed = has_signal and has_pickup_method
	return {
		"passed": passed,
		"message": "Pickup system present" if passed else "Missing pickup signal/method"
	}


func test_item_has_visual_effects() -> Dictionary:
	if not item_script:
		return {"passed": false, "message": "Item not loaded"}

	var source = item_script.source_code
	var has_bob = "bob" in source.to_lower()
	var has_glow = "glow" in source.to_lower()
	var has_effect = "effect" in source.to_lower()

	var passed = has_bob or has_glow or has_effect
	return {
		"passed": passed,
		"message": "Visual effects present" if passed else "Missing visual effects"
	}


func test_item_has_network_sync() -> Dictionary:
	if not item_script:
		return {"passed": false, "message": "Item not loaded"}

	var source = item_script.source_code
	var has_rpc = "@rpc" in source
	var has_sync = "sync" in source.to_lower()

	var passed = has_rpc or has_sync
	return {
		"passed": passed,
		"message": "Network sync present" if passed else "Missing network sync"
	}


func test_coin_pickup_exists() -> Dictionary:
	if not coin_script:
		return {"passed": false, "message": "CoinPickup.gd not found"}

	var source = coin_script.source_code
	var extends_item = "extends Item" in source or "extends" in source
	var has_value = "value" in source.to_lower() or "coin" in source.to_lower()

	var passed = extends_item and has_value
	return {
		"passed": passed,
		"message": "CoinPickup configured" if passed else "CoinPickup missing components"
	}


func test_health_pickup_exists() -> Dictionary:
	if not health_script:
		return {"passed": false, "message": "HealthPickup.gd not found"}

	var source = health_script.source_code
	var extends_item = "extends Item" in source or "extends" in source
	var has_heal = "heal" in source.to_lower()

	var passed = extends_item and has_heal
	return {
		"passed": passed,
		"message": "HealthPickup configured" if passed else "HealthPickup missing components"
	}


func test_weapon_pickup_exists() -> Dictionary:
	if not weapon_pickup_script:
		return {"passed": false, "message": "WeaponPickup.gd not found"}

	var source = weapon_pickup_script.source_code
	var extends_item = "extends Item" in source or "extends" in source
	var has_weapon = "weapon" in source.to_lower()

	var passed = extends_item and has_weapon
	return {
		"passed": passed,
		"message": "WeaponPickup configured" if passed else "WeaponPickup missing components"
	}


func test_item_multiplayer_null_safety() -> Dictionary:
	if not item_script:
		return {"passed": false, "message": "Item not loaded"}

	var source = item_script.source_code
	var has_null_check = "if sync_pickup and multiplayer and multiplayer.has_multiplayer_peer()" in source

	return {
		"passed": has_null_check,
		"message": "Multiplayer null safety present" if has_null_check else "Missing multiplayer null checks"
	}
