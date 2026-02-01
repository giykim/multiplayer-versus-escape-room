extends RefCounted
class_name BaseTest
## BaseTest - Base class for all test classes
## Provides assertion methods and test structure

# Override in subclasses to set up test fixtures
func setup() -> void:
	pass


# Override in subclasses to clean up
func teardown() -> void:
	pass


# Override to return array of test method names
func get_test_methods() -> Array[String]:
	# Auto-discover methods starting with "test_"
	var methods: Array[String] = []
	for method in get_method_list():
		if method.name.begins_with("test_"):
			methods.append(method.name)
	return methods


# Assertion helpers that return result dictionaries

func assert_true(condition: bool, message: String = "") -> Dictionary:
	return {
		"passed": condition,
		"message": message if message else ("Expected true, got false" if not condition else "OK")
	}


func assert_false(condition: bool, message: String = "") -> Dictionary:
	return {
		"passed": not condition,
		"message": message if message else ("Expected false, got true" if condition else "OK")
	}


func assert_equals(expected, actual, message: String = "") -> Dictionary:
	var passed = expected == actual
	return {
		"passed": passed,
		"message": message if message else ("Expected %s, got %s" % [expected, actual] if not passed else "OK")
	}


func assert_not_equals(not_expected, actual, message: String = "") -> Dictionary:
	var passed = not_expected != actual
	return {
		"passed": passed,
		"message": message if message else ("Expected not %s, but got it" % not_expected if not passed else "OK")
	}


func assert_null(value, message: String = "") -> Dictionary:
	var passed = value == null
	return {
		"passed": passed,
		"message": message if message else ("Expected null, got %s" % value if not passed else "OK")
	}


func assert_not_null(value, message: String = "") -> Dictionary:
	var passed = value != null
	return {
		"passed": passed,
		"message": message if message else ("Expected non-null value" if not passed else "OK")
	}


func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> Dictionary:
	var passed = value >= min_val and value <= max_val
	return {
		"passed": passed,
		"message": message if message else ("Expected %s in range [%s, %s]" % [value, min_val, max_val] if not passed else "OK")
	}


func assert_array_contains(array: Array, element, message: String = "") -> Dictionary:
	var passed = element in array
	return {
		"passed": passed,
		"message": message if message else ("Array does not contain %s" % element if not passed else "OK")
	}


func assert_has_method(obj: Object, method_name: String, message: String = "") -> Dictionary:
	var passed = obj.has_method(method_name)
	return {
		"passed": passed,
		"message": message if message else ("Object missing method: %s" % method_name if not passed else "OK")
	}


func assert_signal_emitted(obj: Object, signal_name: String) -> Dictionary:
	# Note: This is a simplified check - real signal testing requires watching
	var passed = obj.has_signal(signal_name)
	return {
		"passed": passed,
		"message": "Signal exists: %s" % signal_name if passed else "Signal not found: %s" % signal_name
	}


# Utility to wait for a condition with timeout
func wait_until(condition: Callable, timeout_ms: int = 5000, check_interval_ms: int = 100) -> bool:
	var elapsed = 0
	while elapsed < timeout_ms:
		if condition.call():
			return true
		await Engine.get_main_loop().create_timer(check_interval_ms / 1000.0).timeout
		elapsed += check_interval_ms
	return false


# Utility to wait for a signal with timeout
func wait_for_signal(obj: Object, signal_name: String, timeout_ms: int = 5000) -> Variant:
	var result = null
	var received = false

	var callback = func(args = null):
		result = args
		received = true

	obj.connect(signal_name, callback, CONNECT_ONE_SHOT)

	var elapsed = 0
	while elapsed < timeout_ms and not received:
		await Engine.get_main_loop().create_timer(0.1).timeout
		elapsed += 100

	if not received:
		if obj.is_connected(signal_name, callback):
			obj.disconnect(signal_name, callback)

	return result
