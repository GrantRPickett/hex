# tests/test_narrative_feedback.gd
extends GdUnitTestSuite

var _combat_system: CombatSystem
var _attacker: Unit
var _defender: Unit

func before_test() -> void:
	_combat_system = auto_free(CombatSystem.new())
	_attacker = auto_free(Unit.new())
	_defender = auto_free(Unit.new())
	
	# Add to tree to trigger _ready and component creation
	get_tree().root.add_child(_attacker)
	get_tree().root.add_child(_defender)
	
	_attacker.unit_name = "Attacker"
	_defender.unit_name = "Defender"
	_attacker.set_combat_system(_combat_system)

func after_test() -> void:
	if is_instance_valid(_attacker) and _attacker.get_parent():
		_attacker.get_parent().remove_child(_attacker)
	if is_instance_valid(_defender) and _defender.get_parent():
		_defender.get_parent().remove_child(_defender)

func test_combat_action_performed_signal() -> void:
	# Execute combat
	_combat_system.execute_combat(_attacker, _defender, 0)
	
	# Verify EventBus signal
	assert_signal(EventBus).is_emitted("combat_action_performed")

func test_aid_action_performed_signal() -> void:
	# Setup query mock
	var mock_query = mock(UnitQueryService)
	do_return([_defender]).on(mock_query).get_near_units(any())
	_attacker.query = mock_query
	
	# Setup action points
	_attacker.res.set_action_points(1)
	
	# Execute aid
	_attacker.combat.aid_ally(_defender, 0)
	
	# Verify EventBus signal
	assert_signal(EventBus).is_emitted("aid_action_performed")
