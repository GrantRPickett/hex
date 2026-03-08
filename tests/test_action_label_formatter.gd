extends GdUnitTestSuite

const ActionLabelFormatter := preload("res://Gameplay/turn/action_label_formatter.gd")

# Tests for ActionLabelFormatter.format()
# This is a pure static function with no dependencies.

func test_format_no_counts_returns_base() -> void:
	var result = ActionLabelFormatter.format("Attack", 0, 0)
	assert_str(result).is_equal("Attack")

func test_format_adjacent_only() -> void:
	var result = ActionLabelFormatter.format("Attack", 3, 0)
	assert_str(result).is_equal("Attack (3 adjacent)")

func test_format_reachable_only() -> void:
	var result = ActionLabelFormatter.format("Move", 0, 5)
	assert_str(result).is_equal("Move (5 reachable)")

func test_format_both_counts() -> void:
	var result = ActionLabelFormatter.format("Attack", 2, 4)
	assert_str(result).is_equal("Attack (2 adjacent, 4 reachable)")

func test_format_adjacent_one() -> void:
	var result = ActionLabelFormatter.format("Interact", 1, 0)
	assert_str(result).is_equal("Interact (1 adjacent)")

func test_format_empty_base_no_counts() -> void:
	var result = ActionLabelFormatter.format("", 0, 0)
	assert_str(result).is_equal("")

func test_format_empty_base_with_counts() -> void:
	var result = ActionLabelFormatter.format("", 1, 2)
	assert_str(result).is_equal(" (1 adjacent, 2 reachable)")

func test_format_zero_adjacent_is_not_shown() -> void:
	# adjacent_count == 0 should NOT appear in the label
	var result = ActionLabelFormatter.format("Skill", 0, 3)
	assert_str(result).is_not_contains("adjacent")
	assert_str(result).is_contains("3 reachable")

func test_format_zero_reachable_is_not_shown() -> void:
	# reachable_count == 0 should NOT appear in the label
	var result = ActionLabelFormatter.format("Skill", 2, 0)
	assert_str(result).is_not_contains("reachable")
	assert_str(result).is_contains("2 adjacent")

func test_format_large_counts() -> void:
	var result = ActionLabelFormatter.format("Ability", 100, 999)
	assert_str(result).is_equal("Ability (100 adjacent, 999 reachable)")
