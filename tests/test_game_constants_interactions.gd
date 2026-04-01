extends GdUnitTestSuite

func test_get_interaction_for_primary_action() -> void:
	var interaction = GameConstants.get_interaction_from_type(GameConstants.ActionType.CONVINCE)
	assert_str(interaction).is_equal(GameConstants.Activity.CONVINCE)

func test_get_interaction_for_move_variant() -> void:
	var interaction = GameConstants.get_interaction_from_type(GameConstants.ActionType.MOVE_TO_TRAPPED)
	assert_str(interaction).is_equal(GameConstants.Activity.TRAPPED)

	assert_str(interaction).is_equal(GameConstants.Activity.MOVE)

func test_get_interaction_for_unmapped_action_returns_empty() -> void:
	var interaction = GameConstants.get_interaction_from_type(GameConstants.ActionType.NONE)
	assert_str(interaction).is_empty()
