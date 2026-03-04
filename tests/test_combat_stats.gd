extends GdUnitTestSuite

# Tests for CombatStats.set_attribute() and its interaction with get_attribute().
# CombatStats is a pure Resource — no Node/scene dependencies.

const CombatStatsScript := preload("res://level/combat_stats.gd")

func test_set_attribute_grit() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("grit", 12)
	assert_int(stats.grit).is_equal(12)
	assert_int(stats.get_attribute("grit")).is_equal(12)

func test_set_attribute_flow() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("flow", 3)
	assert_int(stats.flow).is_equal(3)
	assert_int(stats.get_attribute("flow")).is_equal(3)

func test_set_attribute_gusto() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("gusto", 8)
	assert_int(stats.get_attribute("gusto")).is_equal(8)

func test_set_attribute_focus() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("focus", 7)
	assert_int(stats.get_attribute("focus")).is_equal(7)

func test_set_attribute_shine() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("shine", 9)
	assert_int(stats.get_attribute("shine")).is_equal(9)

func test_set_attribute_shade() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("shade", 4)
	assert_int(stats.get_attribute("shade")).is_equal(4)

func test_set_attribute_willpower() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("willpower", 15)
	assert_int(stats.get_attribute("willpower")).is_equal(15)

func test_set_attribute_case_insensitive() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("GRIT", 20)
	assert_int(stats.grit).is_equal(20)
	stats.set_attribute("Flow", 5)
	assert_int(stats.flow).is_equal(5)

func test_set_attribute_unknown_name_is_noop() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	var before_grit := stats.grit
	stats.set_attribute("unknown_stat", 99)
	# All stats should be unchanged
	assert_int(stats.grit).is_equal(before_grit)

func test_set_attribute_zero() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("grit", 0)
	assert_int(stats.grit).is_equal(0)

func test_set_attribute_negative() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	stats.set_attribute("flow", -5)
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

func test_get_attribute_unknown_returns_zero() -> void:
	var stats: CombatStats = CombatStatsScript.new()
	auto_free(stats)
	assert_int(stats.get_attribute("nonsense")).is_equal(0)
