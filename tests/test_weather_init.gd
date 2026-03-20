extends GdUnitTestSuite

# Tests for weather initialization from level data.

const WeatherManagerScript := preload("res://Autoloads/weather_manager.gd")

func _make_manager() -> Node:
	var m: Node = WeatherManagerScript.new()
	add_child(m)
	return m

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

func test_set_current_pressures_initializes_weather() -> void:
	var mgr = _make_manager()
	
	# Initial state should be empty
	assert_array(mgr.current_pressures).is_empty()
	
	# Set pressures
	var new_pressures: Array[String] = ["Shine", "Gusto"]
	mgr.set_current_pressures(new_pressures)
	
	assert_array(mgr.current_pressures).is_equal(["Shine", "Gusto"])
	
func test_set_current_pressures_clears_previous() -> void:
	var mgr = _make_manager()
	
	mgr.add_pressure("Flow", false)
	assert_array(mgr.current_pressures).contains("Flow")
	
	mgr.set_current_pressures(["Gusto"])
	assert_array(mgr.current_pressures).is_equal(["Gusto"])
	assert_array(mgr.current_pressures).not_contains("Flow")

func test_set_current_pressures_emits_signal() -> void:
	var mgr = _make_manager()
	var monitor := monitor_signals(mgr)
	
	mgr.set_current_pressures(["Shade"])
	
	assert_signal(monitor).is_emitted("pressures_changed")
	assert_signal(monitor).is_emitted("weather_changed")
