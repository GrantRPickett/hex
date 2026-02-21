extends GdUnitTestSuite

const UnitQueryService := preload("res://Gameplay/targets/components/unit_query_service.gd")

func test_get_units_in_range_without_full_willpower_filters_full_units() -> void:
	var source := auto_free(Unit.new())
	source.global_position = Vector2.ZERO
	var service := UnitQueryService.new(source)

	var ally_low := auto_free(Unit.new())
	ally_low.global_position = Vector2(10, 0)
	ally_low.willpower = 5

	var ally_full := auto_free(Unit.new())
	ally_full.global_position = Vector2(20, 0)
	ally_full.willpower = ally_full.max_willpower

	var result := service.get_units_in_range_without_full_willpower([ally_low, ally_full], 1.0)
	assert_array(result).contains(ally_low)
	assert_array(result).not_contains(ally_full)

func test_get_units_in_range_without_full_willpower_respects_range() -> void:
	var source := auto_free(Unit.new())
	source.global_position = Vector2.ZERO
	var service := UnitQueryService.new(source)

	var in_range := auto_free(Unit.new())
	in_range.global_position = Vector2(10, 0)
	in_range.willpower = 5

	var out_of_range := auto_free(Unit.new())
	out_of_range.global_position = Vector2(200, 0)
	out_of_range.willpower = 1

	var result := service.get_units_in_range_without_full_willpower([in_range, out_of_range], 1.0)
	assert_array(result).contains(in_range)
	assert_array(result).not_contains(out_of_range)