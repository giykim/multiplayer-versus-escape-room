extends Node
class_name TestRunner
## TestRunner - E2E Testing framework for automated game validation
## Run tests from command line: godot --headless -s tests/TestRunner.gd

signal all_tests_completed(passed: int, failed: int, total: int)
signal test_completed(test_name: String, passed: bool, message: String)

var test_results: Array[Dictionary] = []
var current_test_index: int = 0
var test_classes: Array[Script] = []

# Test configuration
var verbose: bool = true
var stop_on_fail: bool = false

func _ready() -> void:
	print("\n========================================")
	print("  MULTIPLAYER PUZZLE GAME - E2E TESTS")
	print("========================================\n")

	# Discover and register test classes
	_discover_tests()

	# Run all tests
	await _run_all_tests()

	# Print summary
	_print_summary()

	# Exit with appropriate code
	var failed_count = test_results.filter(func(r): return not r.passed).size()
	get_tree().quit(0 if failed_count == 0 else 1)


func _discover_tests() -> void:
	# Register test classes (add new test files here)
	var test_paths = [
		"res://tests/unit/TestPlayer.gd",
		"res://tests/unit/TestCombatSystem.gd",
		"res://tests/unit/TestPuzzles.gd",
		"res://tests/unit/TestDungeon.gd",
		"res://tests/unit/TestItems.gd",
		"res://tests/integration/TestGameFlow.gd",
	]

	for path in test_paths:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script:
				test_classes.append(script)
				print("[TestRunner] Discovered: %s" % path)
		else:
			print("[TestRunner] Warning: Test file not found: %s" % path)


func _run_all_tests() -> void:
	for test_script in test_classes:
		var test_instance = test_script.new()

		if not test_instance.has_method("get_test_methods"):
			push_warning("Test class missing get_test_methods()")
			continue

		var test_name = test_script.resource_path.get_file().get_basename()
		print("\n--- Running: %s ---" % test_name)

		# Setup
		if test_instance.has_method("setup"):
			await test_instance.setup()

		# Get and run test methods
		var methods = test_instance.get_test_methods()
		for method in methods:
			await _run_single_test(test_instance, method, test_name)

			if stop_on_fail and test_results.size() > 0 and not test_results[-1].passed:
				break

		# Teardown
		if test_instance.has_method("teardown"):
			await test_instance.teardown()

		# Clean up
		if test_instance is Node:
			test_instance.queue_free()


func _run_single_test(instance: Object, method: String, class_name: String) -> void:
	var full_name = "%s.%s" % [class_name, method]
	var result = {
		"name": full_name,
		"passed": false,
		"message": "",
		"time_ms": 0
	}

	var start_time = Time.get_ticks_msec()

	# Run test with error handling
	if instance.has_method(method):
		var test_result = await instance.call(method)

		if test_result is Dictionary:
			result.passed = test_result.get("passed", false)
			result.message = test_result.get("message", "")
		elif test_result is bool:
			result.passed = test_result
			result.message = "OK" if test_result else "Test returned false"
		elif test_result == null:
			# Assume passed if no exception and no return value
			result.passed = true
			result.message = "OK"
	else:
		result.message = "Method not found: %s" % method

	result.time_ms = Time.get_ticks_msec() - start_time
	test_results.append(result)

	# Print result
	var status = "PASS" if result.passed else "FAIL"
	var color = "\u001b[32m" if result.passed else "\u001b[31m"
	var reset = "\u001b[0m"

	if verbose:
		print("  [%s%s%s] %s (%dms) - %s" % [color, status, reset, full_name, result.time_ms, result.message])

	test_completed.emit(full_name, result.passed, result.message)


func _print_summary() -> void:
	var passed = test_results.filter(func(r): return r.passed).size()
	var failed = test_results.filter(func(r): return not r.passed).size()
	var total = test_results.size()
	var total_time = test_results.reduce(func(acc, r): return acc + r.time_ms, 0)

	print("\n========================================")
	print("  TEST SUMMARY")
	print("========================================")
	print("  Passed: %d / %d" % [passed, total])
	print("  Failed: %d" % failed)
	print("  Time:   %dms" % total_time)
	print("========================================")

	if failed > 0:
		print("\nFailed tests:")
		for result in test_results:
			if not result.passed:
				print("  - %s: %s" % [result.name, result.message])

	print("")
	all_tests_completed.emit(passed, failed, total)
