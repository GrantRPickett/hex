extends GdUnitTestSuite

const UnitQueryService := preload("res://Gameplay/targets/components/unit_query_service.gd")

func test_get_units_in_range_without_full_willpower_filters_full_units() -> void:
	var source: Unit = auto_free(Unit.new())
	source.set_external_grid_coord(Vector2i(0, 0))
	# Mock action points component so max_willpower works
	source.res = auto_free(ActionPointsComponent.new())
	var service := UnitQueryService.new(source)

	var ally_low: Unit = auto_free(Unit.new())
	ally_low.res = auto_free(ActionPointsComponent.new())
	ally_low.set_external_grid_coord(Vector2i(1, 0))
	ally_low.willpower = 5

	var ally_full: Unit = auto_free(Unit.new())
	ally_full.res = auto_free(ActionPointsComponent.new())
	ally_full.set_external_grid_coord(Vector2i(2, 0))
	ally_full.willpower = ally_full.max_willpower

	var result: Array = service.get_units_in_range_without_full_willpower([ally_low, ally_full], 10.0)
	assert_array(result).contains(ally_low)
	assert_array(result).not_contains(ally_full)

func test_get_units_in_range_without_full_willpower_respects_range() -> void:
	var source: Unit = auto_free(Unit.new())
	source.set_external_grid_coord(Vector2i(0, 0))
	source.res = auto_free(ActionPointsComponent.new())
	var service := UnitQueryService.new(source)

	var in_range: Unit = auto_free(Unit.new())
	in_range.res = auto_free(ActionPointsComponent.new())
	in_range.set_external_grid_coord(Vector2i(1, 0))
	in_range.willpower = 5

	var out_of_range: Unit = auto_free(Unit.new())
	out_of_range.res = auto_free(ActionPointsComponent.new())
	out_of_range.set_external_grid_coord(Vector2i(10, 10))
	out_of_range.willpower = 1

	var result: Array = service.get_units_in_range_without_full_willpower([in_range, out_of_range], 2.0)
	assert_array(result).contains(in_range)
	assert_array(result).not_contains(out_of_range)

# ---------------------------------------------------------------------------
# invalidate_cache — pure state reset, no Unit needed
# ---------------------------------------------------------------------------

func test_invalidate_cache_sets_all_dirty_flags() -> void:
	var source: Unit = auto_free(Unit.new())
	var svc: UnitQueryService = UnitQueryService.new(source)
	# Simulate clean state
	svc.set("_hostiles_dirty", false)
	svc.set("_friendlies_dirty", false)
	svc.set("_neutrals_dirty", false)
	svc.invalidate_cache()
	assert_bool(svc.get("_hostiles_dirty")).is_true()
	assert_bool(svc.get("_friendlies_dirty")).is_true()
	assert_bool(svc.get("_neutrals_dirty")).is_true()

func test_invalidate_cache_clears_cached_arrays() -> void:
	var source: Unit = auto_free(Unit.new())
	var svc: UnitQueryService = UnitQueryService.new(source)
	svc.invalidate_cache()
	assert_int(svc.get("_cached_hostiles").size()).is_equal(0)
	assert_int(svc.get("_cached_friendlies").size()).is_equal(0)
	assert_int(svc.get("_cached_neutrals").size()).is_equal(0)

func test_invalidate_cache_idempotent() -> void:
	var source: Unit = auto_free(Unit.new())
	var svc: UnitQueryService = UnitQueryService.new(source)
	svc.invalidate_cache()
	svc.invalidate_cache()
	assert_bool(svc.get("_hostiles_dirty")).is_true()
