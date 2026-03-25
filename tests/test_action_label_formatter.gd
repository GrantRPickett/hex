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
	assert_str(result).is_equal("Move (5 far)")

func test_format_both_counts() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 2, 4)
	assert_str(result).is_equal("Attack (2 near, 4 far)")

func test_format_near_one() -> void:
	var result: String = ActionLabelFormatter.format("Interact", 1, 0)
	assert_str(result).is_equal("Interact (1 near)")

func test_format_empty_base_no_counts() -> void:
	var result: String = ActionLabelFormatter.format("", 0, 0)
	assert_str(result).is_equal("")

func test_format_empty_base_with_counts() -> void:
	var result: String = ActionLabelFormatter.format("", 1, 2)
	assert_str(result).is_equal(" (1 near, 2 far)")

func test_format_zero_near_is_not_shown() -> void:
	# near_count == 0 should NOT appear in the label
	var result: String = ActionLabelFormatter.format("Skill", 0, 3)
	assert_bool(result.contains("near")).is_false()
	assert_bool(result.contains("3 far")).is_true()

func test_format_zero_reachable_is_not_shown() -> void:
	# reachable_count == 0 should NOT appear in the label
	var result: String = ActionLabelFormatter.format("Skill", 2, 0)
	assert_bool(result.contains("reachable")).is_false()
	assert_bool(result.contains("2 near")).is_true()

func test_format_large_counts() -> void:
	var result: String = ActionLabelFormatter.format("Ability", 100, 999)
	assert_str(result).is_equal("Ability (100 near, 999 far)")

func test_format_with_group_suffixes() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 2, 1, "", "★", "◆")
	assert_str(result).is_equal("Attack (2 near★, 1 far◆)")

func test_format_with_group_suffixes_near_only_single() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 1, 0, "", "★")
	assert_str(result).is_equal("Attack (1 near★)")

func test_format_with_group_suffixes_near_only_multiple() -> void:
	var result: String = ActionLabelFormatter.format("Attack", 2, 0, "", "★")
	assert_str(result).is_equal("Attack (2 near★)")

func test_get_label_adds_ellipsis_for_multi_target() -> void:
	var action := PlayerAction.new(GameConstants.ActionType.ATTACK)
	action.action_id = "action_attack"
	action.ui_label_params = {"near": 2, "near_suffix": "★"}
	action.targets = [null, null] # needs size > 1
	
	var result := ActionLabelFormatter.get_label(action)
	# "Attack" translated is "Attack" in default locale usually
	# Result should contain "Attack…"
	assert_bool(result.contains("…")).is_true()
	assert_bool(result.contains("★")).is_true()

func test_get_label_adds_ellipsis_for_attribute_needed() -> void:
	var action := PlayerAction.new(GameConstants.ActionType.ATTACK)
	action.action_id = "action_attack"
	action.needs_attribute = true
	action.ui_label_params = {"near": 1}
	
	var result := ActionLabelFormatter.get_label(action)
	assert_bool(result.contains("…")).is_true()

func test_get_label_wait_adds_circle() -> void:
	var action := PlayerAction.new(GameConstants.ActionType.WAIT)
	action.action_id = GameConstants.ActionIds.WAIT
	
	var result := ActionLabelFormatter.get_label(action)
	assert_bool(result.contains(GameConstants.UI.Indicators.IDLE)).is_true()
	assert_bool(result.contains("Wait")).is_true()
