extends GdUnitTestSuite

# Tests for weather_manager.gd (Node script).
# We instantiate it directly to avoid manipulating the global Autoload state.

const WeatherManagerScript := preload("res://Autoloads/weather_manager.gd")

func _make_manager() -> Node:
	var m: Node = WeatherManagerScript.new()
	add_child(m)
	return m

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# add_pressure / remove_pressure / clear_pressures
# ---------------------------------------------------------------------------

func test_add_pressure_adds_to_forecast_by_default() -> void:
	var mgr: Node = _make_manager()
	var monitor := monitor_signals(mgr)
	mgr.add_pressure(mgr.SHINE)
	assert_array(mgr.forecast_pressures).contains(mgr.SHINE)
	assert_signal(monitor).is_emitted("forecast_pressures_changed")
	assert_signal(monitor).is_not_emitted("pressures_changed")

func test_add_pressure_adds_to_current_if_specified() -> void:
	var mgr: Node = _make_manager()
	var monitor := monitor_signals(mgr)
	mgr.add_pressure(mgr.SHINE, false)
	assert_array(mgr.current_pressures).contains(mgr.SHINE)
	assert_signal(monitor).is_emitted("pressures_changed")

func test_add_pressure_cancels_opposite() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE) # adds shine
	mgr.add_pressure(mgr.SHADE) # shade cancels shine
	assert_array(mgr.forecast_pressures).is_empty()

func test_add_pressure_limits_to_two_by_removing_oldest() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE)
	mgr.add_pressure(mgr.GUSTO)
	mgr.add_pressure(mgr.FLOW) # Should push out SHINE
	assert_array(mgr.forecast_pressures).contains(mgr.GUSTO)
	assert_array(mgr.forecast_pressures).contains(mgr.FLOW)
	assert_int(mgr.forecast_pressures.size()).is_equal(2)

func test_remove_pressure_removes_from_forecast() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE)
	mgr.remove_pressure(mgr.SHINE)
	assert_array(mgr.forecast_pressures).is_empty()

func test_clear_pressures_clears_forecast() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE)
	mgr.add_pressure(mgr.GUSTO)
	mgr.clear_pressures(true)
	assert_array(mgr.forecast_pressures).is_empty()

func test_clear_pressures_clears_current() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE, false)
	mgr.clear_pressures(false)
	assert_array(mgr.current_pressures).is_empty()

# ---------------------------------------------------------------------------
# get_weather_info / apply_weather_effects
# ---------------------------------------------------------------------------

func test_get_weather_info_empty_pressures_returns_temperate() -> void:
	var mgr: Node = _make_manager()
	var info: Dictionary = mgr.get_weather_info([])
	assert_str(info.name).is_equal("Temperate")
	assert_int(info.bonuses["focus"]).is_equal(1)

func test_get_weather_info_single_pressure_focus_returns_calm() -> void:
	var mgr: Node = _make_manager()
	var info: Dictionary = mgr.get_weather_info([mgr.FOCUS])
	assert_str(info.name).is_equal("Calm")
	assert_int(info.bonuses["focus"]).is_equal(2)

func test_get_weather_info_single_pressure_returns_condition() -> void:
	var mgr: Node = _make_manager()
	var info: Dictionary = mgr.get_weather_info([mgr.SHINE])
	assert_str(info.name).is_equal("Shine Condition")
	assert_int(info.bonuses["shine"]).is_equal(1)

func test_get_weather_info_combo() -> void:
	var mgr: Node = _make_manager()
	# SHINE + GRIT = "Parched"
	var info: Dictionary = mgr.get_weather_info([mgr.SHINE, mgr.GRIT])
	assert_str(info.name).is_equal("Parched")
	assert_int(info.bonuses["shine"]).is_equal(1)
	assert_int(info.bonuses["grit"]).is_equal(1)

func test_apply_weather_effects_emits_signals() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE, false) # make current weather Shine
	var monitor := monitor_signals(mgr)
	mgr.apply_weather_effects()
	assert_signal(monitor).is_emitted("weather_effect_applied")
	assert_signal(monitor).is_emitted("weather_changed")

# ---------------------------------------------------------------------------
# advance_weather
# ---------------------------------------------------------------------------

func test_advance_weather_with_no_channeler_does_nothing() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHINE) # forecast = shine, current = empty
	var monitor := monitor_signals(mgr)
	mgr.advance_weather()
	# Current remains empty
	assert_array(mgr.current_pressures).is_empty()
	assert_signal(monitor).is_not_emitted("pressures_changed")

func test_advance_weather_with_living_channeler_applies_forecast() -> void:
	var mgr: Node = _make_manager()
	var unit = auto_free(Unit.new())
	add_child(unit)
	unit.willpower = 10
	mgr.start_channeling(unit)
	mgr.add_pressure(mgr.SHADE) # forecast = shade
	mgr.advance_weather()
	assert_array(mgr.current_pressures).contains(mgr.SHADE)
	assert_object(mgr.get_channeling_unit()).is_null()

# ---------------------------------------------------------------------------
# get_current_weather_attribute
# ---------------------------------------------------------------------------

func test_get_current_weather_attribute_returns_weather_attribute_resource() -> void:
	var mgr: Node = _make_manager()
	mgr.add_pressure(mgr.SHADE, false)
	mgr.add_pressure(mgr.FLOW, false) # Drizzle
	var attr: WeatherAttribute = mgr.get_current_weather_attribute()
	assert_str(attr.attribute_name).is_equal("Drizzle")
	assert_float(attr.humidity_effect).is_equal(0.7)
	assert_float(attr.temperature_effect).is_equal(-0.3)
