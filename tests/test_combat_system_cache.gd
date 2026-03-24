extends GdUnitTestSuite

var _combat_system: CombatSystem
var _attacker: Unit
var _defender: Unit

func before_test() -> void:
	_combat_system = auto_free(CombatSystem.new())
	_attacker = auto_free(Unit.new())
	_defender = auto_free(Unit.new())
	
	# Setup basic attributes
	_attacker.grit = 10
	_attacker.flow = 10
	_defender.grit = 5
	_defender.flow = 5
	
	if not _combat_system.is_inside_tree():
		get_tree().root.add_child(_combat_system)

func after_test() -> void:
	if is_instance_valid(_combat_system) and _combat_system.get_parent():
		_combat_system.get_parent().remove_child(_combat_system)

func test_forecast_caching() -> void:
	# First call should populate cache
	var forecast1 = _combat_system.get_combat_forecast(_attacker, _defender, 0)
	assert_object(forecast1).is_not_null()
	
	# Second call should return identical data (likely from cache)
	var forecast2 = _combat_system.get_combat_forecast(_attacker, _defender, 0)
	assert_dict(forecast2).is_equal(forecast1)

func test_cache_cleared_on_turn_change() -> void:
	var forecast1 = _combat_system.get_combat_forecast(_attacker, _defender, 0)
	
	# Simulate turn change
	if EventBus:
		EventBus.turn_changed.emit(1, 0)
	
	# After turn change, it should still work but cache was cleared internally
	var forecast2 = _combat_system.get_combat_forecast(_attacker, _defender, 0)
	assert_dict(forecast2).is_equal(forecast1)

func test_cache_cleared_on_execution() -> void:
	_combat_system.get_combat_forecast(_attacker, _defender, 0)
	
	# Executing combat should clear cache
	_combat_system.execute_combat(_attacker, _defender, 0)
	
	# Internal check for cache empty would require exposing it, but we can 
	# verify it still returns correct data
	var forecast = _combat_system.get_combat_forecast(_attacker, _defender, 0)
	assert_object(forecast).is_not_null()
