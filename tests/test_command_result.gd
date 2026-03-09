extends GdUnitTestSuite

const _CommandResult = preload("res://Gameplay/commands/command_result.gd")

func test_success() -> void:
	var result = _CommandResult.success("Good job")
	assert_bool(result.is_success()).is_true()
	assert_bool(result.is_failure()).is_false()
	assert_str(result.message).is_equal("Good job")
	assert_str(result.get_description()).is_equal("SUCCESS: Good job")

func test_failed() -> void:
	var result = _CommandResult.failed("Something went wrong")
	assert_bool(result.is_success()).is_false()
	assert_bool(result.is_failure()).is_true()
	assert_str(result.message).is_equal("Something went wrong")
	assert_str(result.get_description()).is_equal("FAILED: Something went wrong")

func test_invalid_context() -> void:
	var missing = PackedStringArray(["unit_manager", "task_manager"])
	var result = _CommandResult.invalid_context(missing)
	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_error_message()).contains("missing unit_manager, task_manager")

func test_invalid_payload() -> void:
	var result = _CommandResult.invalid_payload("Too many points")
	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_error_message()).is_equal("Too many points")

func test_precondition_failed() -> void:
	var result = _CommandResult.precondition_failed("Unit is dead")
	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_error_message()).is_equal("Unit is dead")

func test_default_values() -> void:
	var result = _CommandResult.new()
	assert_bool(result.is_success()).is_true()
	assert_str(result.message).is_empty()
	assert_str(result.get_description()).is_equal("SUCCESS")
