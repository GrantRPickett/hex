extends GdUnitTestSuite

const UnitScript := preload("res://Gameplay/targets/unit.gd")

func test_is_player_leader_access() -> void:
	var unit: Unit = UnitScript.new()
	add_child(unit)
	auto_free(unit)
	
	# This should not crash or error now
	unit.set_player_leader(true)
	assert_bool(unit.is_player_leader()).is_true()
	
	unit.set_player_leader(false)
	assert_bool(unit.is_player_leader()).is_false()

func test_is_faction_leader_with_player_faction() -> void:
	var unit: Unit = UnitScript.new()
	add_child(unit)
	auto_free(unit)
	
	unit.set_faction_leader(GameConstants.Faction.PLAYER, true)
	assert_bool(unit.is_player_leader()).is_true()
	
	unit.set_faction_leader(GameConstants.Faction.PLAYER, false)
	assert_bool(unit.is_player_leader()).is_false()
