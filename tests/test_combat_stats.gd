extends GdUnitTestSuite

# Tests for CombatStats.set_attribute() and its interaction with get_attribute().
# CombatStats is a pure Resource — no Node/scene dependencies.

const CombatStatsScript := preload("res://level/combat_stats.gd")

func test_set_attribute_grit() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.GRIT, 12)
	assert_int(stats.grit).is_equal(12)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.GRIT)).is_equal(12)

func test_set_attribute_flow() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.FLOW, 3)
	assert_int(stats.flow).is_equal(3)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.FLOW)).is_equal(3)

func test_set_attribute_gusto() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.GUSTO, 8)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.GUSTO)).is_equal(8)

func test_set_attribute_focus() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.FOCUS, 7)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.FOCUS)).is_equal(7)

func test_set_attribute_shine() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.SHINE, 9)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.SHINE)).is_equal(9)

func test_set_attribute_shade() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.SHADE, 4)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.SHADE)).is_equal(4)

func test_set_attribute_willpower() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.WILLPOWER, 15)
	assert_int(stats.get_attribute(GameConstants.AttributeIndex.WILLPOWER)).is_equal(15)

func test_set_attribute_via_constants() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.GRIT, 20)
	assert_int(stats.grit).is_equal(20)
	stats.set_attribute(GameConstants.AttributeIndex.FLOW, 5)
	assert_int(stats.flow).is_equal(5)

func test_set_attribute_zero() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.GRIT, 0)
	assert_int(stats.grit).is_equal(0)

func test_set_attribute_negative() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute(GameConstants.AttributeIndex.FLOW, -5)
	assert_int(stats.flow).is_equal(-5)

func test_init_with_custom_values() -> void:
	var stats: CombatStats = CombatStatsScript.new(1, 2, 3, 4, 5, 6, 20)
	auto_free(stats)
	assert_int(stats.grit).is_equal(1)
	assert_int(stats.flow).is_equal(2)
	assert_int(stats.gusto).is_equal(3)
	assert_int(stats.focus).is_equal(4)
	assert_int(stats.shine).is_equal(5)
	assert_int(stats.shade).is_equal(6)
	assert_int(stats.willpower).is_equal(20)
