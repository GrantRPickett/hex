extends GdUnitTestSuite

const LocationServiceScript = preload("res://Gameplay/targets/location_service.gd")

func test_location_service_explore_location() -> void:
	var service = auto_free(LocationServiceScript.new())
	var test_unit = auto_free(Unit.new())
	var test_loc = auto_free(Location.new())

	service.explore_location(test_unit, test_loc)
	# Asserts no crash, actually we don't have complex state.

func test_location_service_visit_location() -> void:
	var service = auto_free(LocationServiceScript.new())
	var test_unit = auto_free(Unit.new())
	var test_loc = auto_free(Location.new())

	service.visit_location(test_unit, test_loc)
