# tests/test_unit_attribute_cache.gd
extends GdUnitTestSuite

func test_attribute_caching_and_invalidation() -> void:
	var actor: Unit = auto_free(Unit.new())
	actor.unit_name = "Test Unit"
	assert_object(actor.attributes).is_not_null()
	assert_object(actor.round_state).is_not_null()
	
	# Mock dependencies
	var query: UnitQueryService = auto_free(UnitQueryService.new(actor))
	actor.query = query
	
	# Initial value (base Grit is 6 by default in Target.gd)
	var grit = actor.get_attribute(GameConstants.AttributeIndex.GRIT)
	assert_int(grit).is_equal(6)
	
	# Apply a modifier
	actor.apply_attribute_modifier("test_mod", {"grit": 5})
	
	# Check if cache invalidated and new value returned
	grit = actor.get_attribute(GameConstants.AttributeIndex.GRIT)
	assert_int(grit).is_equal(11)
	
	# Check if cache is used (we can't easily check internal state without making it public, 
	# but we can verify the value remains stable)
	grit = actor.get_attribute(GameConstants.AttributeIndex.GRIT)
	assert_int(grit).is_equal(11)
	
	# Add aid buff (pair 0 is Grit/Flow)
	actor.add_aid_buff(3, 0)
	
	# Check if total is base(6) + mod(5) + buff(3) = 14
	grit = actor.get_attribute(GameConstants.AttributeIndex.GRIT)
	assert_int(grit).is_equal(14)
	
	# Verify that getting another attribute (e.g. Flow) remains consistent
	var flow = actor.get_attribute(GameConstants.AttributeIndex.FLOW)
	assert_int(flow).is_equal(9) # Base 6 + Buff 3
	
	# Remove modifier
	actor.remove_attribute_modifier("test_mod")
	grit = actor.get_attribute(GameConstants.AttributeIndex.GRIT)
	assert_int(grit).is_equal(9) # Only buff remains
	
	# Verify forecast keys
	var combat: CombatSystem = auto_free(CombatSystem.new())
	var forecast: CombatResult = combat.get_preview_forecast(actor, actor, GameConstants.AttributeIndex.GRIT, GameConstants.Activity.CONVINCE)
	assert_int(forecast.damage).is_greater_equal(0)
	assert_int(forecast.counter_damage).is_equal(0)
	assert_bool(forecast.is_opposed).is_false() # CONVINCE is unopposed
	
	# Break circular reference
	actor.query = null
