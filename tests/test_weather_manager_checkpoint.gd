extends GdUnitTestSuite

const WeatherManagerScript := preload("res://Autoloads/weather_manager.gd")

func test_weather_checkpoint_restores_pressures_and_channeling() -> void:
	var weather := auto_free(WeatherManagerScript.new())
	get_tree().root.add_child(weather)
	var initial_manager := auto_free(UnitManager.new())
	var unit_a := auto_free(Unit.new())
	var unit_b := auto_free(Unit.new())
	initial_manager.add_unit(unit_a, Vector2i(0, 0), true)
	initial_manager.add_unit(unit_b, Vector2i(1, 0), true)
	weather.current_pressures = ["shine", "flow"]
	weather.forecast_pressures = ["gusto"]
	weather.start_channeling(unit_b)
	var snapshot := weather.create_memento(initial_manager)
	var restored_manager := auto_free(UnitManager.new())
	var restored_a := auto_free(Unit.new())
	var restored_b := auto_free(Unit.new())
	restored_manager.add_unit(restored_a, Vector2i(0, 0), true)
	restored_manager.add_unit(restored_b, Vector2i(1, 0), true)
	weather.current_pressures = []
	weather.forecast_pressures = []
	weather.restore_from_memento(snapshot, restored_manager)
	assert_array(weather.current_pressures).is_equal(["shine", "flow"])
	assert_array(weather.forecast_pressures).is_equal(["gusto"])
	assert_object(weather.get_channeling_unit()).is_equal(restored_b)
