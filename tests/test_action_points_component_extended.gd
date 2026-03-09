extends GdUnitTestSuite

# Tests for ActionPointsComponent.consume_reaction() — the one function
# from this Resource that lacks test coverage.
# Extends coverage of the existing test_unit_components.gd tests.

const APCScript := preload("res://Gameplay/targets/components/action_points_component.gd")

func _make_component() -> ActionPointsComponent:
	var c: ActionPointsComponent = APCScript.new()
	auto_free(c)
	return c

# ---------------------------------------------------------------------------
# consume_reaction (via .res sub-object in real code, but the raw Resource works)
# ---------------------------------------------------------------------------

func test_consume_reaction_decrements_available() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 2
	c._reactions_available = 2
	c.consume_reaction()
	assert_int(c._reactions_available).is_equal(1)

func test_consume_reaction_does_not_go_below_zero() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 1
	c._reactions_available = 0
	c.consume_reaction()
	# Should clamp at 0, not go negative
	assert_int(c._reactions_available).is_equal(0)

func test_consume_reaction_from_one_to_zero() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 1
	c._reactions_available = 1
	assert_bool(c.has_reaction_available()).is_true()
	c.consume_reaction()
	assert_bool(c.has_reaction_available()).is_false()

func test_consume_reaction_twice_from_two() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 2
	c._reactions_available = 2
	c.consume_reaction()
	c.consume_reaction()
	assert_int(c._reactions_available).is_equal(0)
	assert_bool(c.has_reaction_available()).is_false()

func test_refresh_restores_reactions_after_consume() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 1
	c._reactions_available = 1
	c.consume_reaction()
	assert_bool(c.has_reaction_available()).is_false()
	# refresh_for_new_round needs _owner_unit; call the internals directly
	c._reactions_available = c.max_reactions
	assert_bool(c.has_reaction_available()).is_true()

func test_get_reactions_available_matches_remaining() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 3
	c._reactions_available = 3
	assert_int(c.get_reactions_available()).is_equal(3)
	c.consume_reaction()
	assert_int(c.get_reactions_available()).is_equal(2)

func test_get_max_reactions_unaffected_by_consume() -> void:
	var c: ActionPointsComponent = _make_component()
	c.max_reactions = 2
	c._reactions_available = 2
	c.consume_reaction()
	assert_int(c.get_max_reactions()).is_equal(2)

func test_set_max_reactions() -> void:
	var c: ActionPointsComponent = _make_component()
	c.set_max_reactions(5)
	assert_int(c.max_reactions).is_equal(5)
