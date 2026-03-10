extends GdUnitTestSuite

const AimCursorScript = preload("res://GUI/HUD/aim_cursor.gd")

func _make_cursor() -> Node2D:
	var cursor = AimCursorScript.new()
	add_child(cursor)
	return cursor

func test_set_initial_position() -> void:
	var cursor = _make_cursor()
	var test_pos = Vector2(100, 200)
	cursor.set_initial_position(test_pos)
	assert_object(cursor._virtual_cursor_pos).is_equal(test_pos)

func test_get_effective_cursor_position_fallback() -> void:
	var cursor = _make_cursor()
	var fallback = Vector2(50, 50)
	# Should return fallback when virtual cursor is not active
	assert_object(cursor.get_effective_cursor_position(fallback)).is_equal(fallback)

func test_get_effective_cursor_position_virtual() -> void:
	var cursor = _make_cursor()
	var test_pos = Vector2(100, 200)
	cursor._virtual_cursor_pos = test_pos
	cursor._using_virtual_cursor = true
	# Should return virtual pos when active
	assert_object(cursor.get_effective_cursor_position(Vector2.ZERO)).is_equal(test_pos)

func test_is_virtual_active() -> void:
	var cursor = _make_cursor()
	assert_bool(cursor.is_virtual_active()).is_false()
	cursor._using_virtual_cursor = true
	assert_bool(cursor.is_virtual_active()).is_true()

func test_joy_aim_activation() -> void:
	var cursor = _make_cursor()
	assert_bool(cursor.is_virtual_active()).is_false()

	# Simulate joystick movement
	cursor._on_joy_aim_held(Vector2(1, 0), 0.016)
	assert_bool(cursor.is_virtual_active()).is_true()
	assert_float(cursor._aim_inactivity_timer).is_equal(0.0)

func test_joy_aim_inactivity_timeout() -> void:
	var cursor = _make_cursor()
	cursor._using_virtual_cursor = true
	cursor._aim_inactivity_timer = 0.0

	# Process should increment timer
	cursor._process(0.1)
	assert_float(cursor._aim_inactivity_timer).is_equal(0.1)
	assert_bool(cursor._using_virtual_cursor).is_true()

	# Process beyond threshold should deactivate
	cursor._process(cursor.aim_inactivity_threshold + 0.1)
	assert_bool(cursor._using_virtual_cursor).is_false()
