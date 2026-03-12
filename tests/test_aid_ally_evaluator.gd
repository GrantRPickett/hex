extends GdUnitTestSuite

const AidAllyEvaluator := preload("res://Gameplay/turn/ai/aid_ally_evaluator.gd")
const UnitScript := preload("res://Gameplay/targets/unit.gd")
const AIContext := preload("res://Gameplay/turn/ai/ai_context.gd")
const CombatPriorityProfile := preload("res://Gameplay/combat/combat_priority_profile.gd")

var evaluator: AidAllyEvaluator
var unit: Unit
var ally: Unit
var enemy: Unit
var context: AIContext

func before_test() -> void:
	evaluator = AidAllyEvaluator.new()
	context = AIContext.new()
	
	unit = auto_free(Unit.new())
	unit.unit_name = "Initiator"
	unit.faction = Unit.Faction.ENEMY
	
	ally = auto_free(Unit.new())
	ally.unit_name = "Ally"
	ally.faction = Unit.Faction.ENEMY
	
	enemy = auto_free(Unit.new())
	enemy.unit_name = "Enemy"
	enemy.faction = Unit.Faction.PLAYER
	
	# Mock dependencies
	var mock_um = mock(preload("res://Gameplay/targets/unit_manager.gd"))
	context.unit_manager = mock_um
	
	# Setup query mock
	_setup_unit_with_mock_query(unit)
	_setup_unit_with_mock_query(ally)

func _setup_unit_with_mock_query(u: Unit) -> void:
	var mock_query = mock(preload("res://Gameplay/targets/components/unit_query_service.gd"))
	u.query = mock_query

func test_evaluate_scores_zero_if_no_actions() -> void:
	unit.res.consume_action()
	var actions = evaluator.evaluate(unit, context)
	assert_array(actions).is_empty()

func test_evaluate_scores_zero_if_ally_has_no_actions() -> void:
	do_return({"enemies": [], "allies": [ally], "neutrals": []}).on(unit.query).get_adjacent_units_categorized(any_float())
	
	ally.res.consume_action() # Use up ally's action
	var actions = evaluator.evaluate(unit, context)
	assert_array(actions).is_empty()

func test_evaluate_lowers_score_if_ally_not_near_enemy() -> void:
	do_return({"enemies": [], "allies": [ally], "neutrals": []}).on(unit.query).get_adjacent_units_categorized(any_float())
	do_return({"enemies": [], "allies": [], "neutrals": []}).on(ally.query).get_adjacent_units_categorized(any_float())
	
	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	
	var base_score = 5.0 * 5.0 # Weight (5) * Multiplier (5.0)
	assert_float(actions[0].score).is_less(30.0)
	# Current penalty is 0.25x
	assert_float(actions[0].score).is_equal(base_score * 0.25)

func test_evaluate_full_score_if_ally_near_enemy() -> void:
	do_return({"enemies": [], "allies": [ally], "neutrals": []}).on(unit.query).get_adjacent_units_categorized(any_float())
	do_return({"enemies": [enemy], "allies": [], "neutrals": []}).on(ally.query).get_adjacent_units_categorized(any_float())
	
	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	
	var base_score = 5.0 * 5.0 # Weight (5) * Multiplier (5.0)
	assert_float(actions[0].score).is_equal(base_score)

func test_evaluate_halves_score_if_ally_already_buffed() -> void:
	do_return({"enemies": [], "allies": [ally], "neutrals": []}).on(unit.query).get_adjacent_units_categorized(any_float())
	do_return({"enemies": [enemy], "allies": [], "neutrals": []}).on(ally.query).get_adjacent_units_categorized(any_float())
	
	ally.add_aid_buff(5, 0) # Already aided
	
	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	
	var base_score = 5.0 * 5.0 # Weight (5) * Multiplier (5.0)
	assert_float(actions[0].score).is_equal(base_score * 0.5)
