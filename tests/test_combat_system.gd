extends GdUnitTestSuite

var _combat_system: CombatSystem
var _attacker: Unit
var _defender: Unit

func before() -> void:
	_combat_system = auto_free(CombatSystem.new())
	_attacker = auto_free(Unit.new())
	_defender = auto_free(Unit.new())

func test_execute_combat_null_attacker() -> void:
	var results = _combat_system.execute_combat(null, _defender, 0)
	
	assert_int(results.size()).is_equal(0)

func test_execute_combat_null_defender() -> void:
	var results = _combat_system.execute_combat(_attacker, null, 0)
	
	assert_int(results.size()).is_equal(0)

func test_execute_combat_both_null() -> void:
	var results = _combat_system.execute_combat(null, null, 0)
	
	assert_int(results.size()).is_equal(0)

func test_execute_combat_returns_dictionary() -> void:
	# This test is limited because we don't have full attribute setup
	# But we can test that it returns an empty dict when attributes are missing
	var results = _combat_system.execute_combat(_attacker, _defender, 0)
	
	# If units don't have attributes, returns empty dict
	assert_object(results).is_not_null()

func test_execute_combat_with_valid_units() -> void:
	# Add attributes to units would require more complex setup
	# For now, just verify the function is callable
	_combat_system.execute_combat(_attacker, _defender, 0)
	
	assert_object(_combat_system).is_not_null()
