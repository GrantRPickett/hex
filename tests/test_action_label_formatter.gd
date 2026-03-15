extends GdUnitTestSuite

const ActionLabelFormatter := preload("res://Gameplay/turn/action_label_formatter.gd")

# Tests for ActionLabelFormatter.format()
# This is a pure static function with no dependencies.

func test_format_no_counts_returns_base() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 0, 0)
	assert_str(result).is_equal("Attack")

func test_format_near_only() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 3, 0)
	assert_str(result).is_equal("Attack (3 near)")

func test_format_reachable_only() -> void:
	var result: String = ActionLabelFormatter.format("Move", 0, 5)
	assert_str(result).is_equal("Move (5 reachable)")

func test_format_both_counts() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 2, 4)
	assert_str(result).is_equal("Attack (2 near, 4 reachable)")

func test_format_near_one() -> void:
	var result: String = ActionLabelFormatter.format("Interact", 1, 0)
	assert_str(result).is_equal("Interact (1 near)")

func test_format_empty_base_no_counts() -> void:
	var result: String = ActionLabelFormatter.format("", 0, 0)
	assert_str(result).is_equal("")

func test_format_empty_base_with_counts() -> void:
	var result: String = ActionLabelFormatter.format("", 1, 2)
	assert_str(result).is_equal(" (1 near, 2 reachable)")

func test_format_zero_near_is_not_shown() -> void:
	# near_count == 0 should NOT appear in the label
	var result: String = ActionLabelFormatter.format("Skill", 0, 3)
	assert_bool(result.contains("near")).is_false()
	assert_bool(result.contains("3 reachable")).is_true()

func test_format_zero_reachable_is_not_shown() -> void:
	# reachable_count == 0 should NOT appear in the label
	var result: String = ActionLabelFormatter.format("Skill", 2, 0)
	assert_bool(result.contains("reachable")).is_false()
	assert_bool(result.contains("2 near")).is_true()

func test_format_large_counts() -> void:
	var result: String = ActionLabelFormatter.format("Ability", 100, 999)
	assert_str(result).is_equal("Ability (100 near, 999 reachable)")
