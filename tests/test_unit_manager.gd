extends GdUnitTestSuite

var _manager: UnitManager
var _sprite1: Sprite2D
var _sprite2: Sprite2D

func before_test() -> void:
	_manager = auto_free(UnitManager.new())
	_sprite1 = auto_free(Sprite2D.new())
	_sprite2 = auto_free(Sprite2D.new())

func test_reset() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	assert_int(_manager.get_unit_count()).is_equal(1)
	_manager.reset()
	assert_int(_manager.get_unit_count()).is_equal(0)
	assert_int(_manager.get_selected_index()).is_equal(0)

func test_get_unit_count() -> void:
	assert_int(_manager.get_unit_count()).is_equal(0)
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	assert_int(_manager.get_unit_count()).is_equal(1)

func test_get_selected_index() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	assert_int(_manager.get_selected_index()).is_equal(0)

func test_get_selected_coord() -> void:
	_manager.add_unit(_sprite1, Vector2i(1, 2), true)
	assert_vector(_manager.get_selected_coord()).is_equal(Vector2i(1, 2))
	_manager.reset()
	assert_vector(_manager.get_selected_coord()).is_equal(Vector2i.ZERO)

func test_get_selected_sprite() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	assert_object(_manager.get_selected_sprite()).is_equal(_sprite1)
	_manager.reset()
	assert_object(_manager.get_selected_sprite()).is_null()

func test_get_unit_sprite() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	assert_object(_manager.get_unit_sprite(0)).is_equal(_sprite1)
	assert_object(_manager.get_unit_sprite(1)).is_null()

func test_get_coord() -> void:
	_manager.add_unit(_sprite1, Vector2i(5, 5), true)
	assert_vector(_manager.get_coord(0)).is_equal(Vector2i(5, 5))
	assert_vector(_manager.get_coord(1)).is_equal(Vector2i.ZERO)

func test_set_coord() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	var monitor := monitor_signals(_manager)
	_manager.set_coord(0, Vector2i(3, 3))
	assert_vector(_manager.get_coord(0)).is_equal(Vector2i(3, 3))
	await assert_signal(monitor).is_emitted("unit_moved", [0, Vector2i(3, 3)])

func test_is_occupied() -> void:
	_manager.add_unit(_sprite1, Vector2i(2, 2), true)
	assert_bool(_manager.is_occupied(Vector2i(2, 2))).is_true()
	assert_bool(_manager.is_occupied(Vector2i(2, 2), 0)).is_false() # Ignore self
	assert_bool(_manager.is_occupied(Vector2i(3, 3))).is_false()

func test_is_player_controlled() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	_manager.add_unit(_sprite2, Vector2i(1, 1), false)
	assert_bool(_manager.is_player_controlled(0)).is_true()
	assert_bool(_manager.is_player_controlled(1)).is_false()

func test_set_player_controlled() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	_manager.set_player_controlled(0, false)
	assert_bool(_manager.is_player_controlled(0)).is_false()

func test_goals_reached() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	_manager.add_unit(_sprite2, Vector2i(1, 1), true)

	assert_bool(_manager.is_goal_reached(0)).is_false()
	assert_bool(_manager.are_all_goals_reached()).is_false()

	_manager.set_goal_reached(0, true)
	assert_bool(_manager.is_goal_reached(0)).is_true()
	assert_bool(_manager.are_all_goals_reached()).is_false()

	_manager.set_goal_reached(1, true)
	assert_bool(_manager.are_all_goals_reached()).is_true()

func test_select_index() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	_manager.add_unit(_sprite2, Vector2i(1, 1), true)

	var monitor := monitor_signals(_manager)
	_manager.select_index(1)
	assert_int(_manager.get_selected_index()).is_equal(1)
	await assert_signal(monitor).is_emitted("selection_changed", [1])

func test_cycle_selection() -> void:
	_manager.add_unit(_sprite1, Vector2i(0, 0), true)
	_manager.add_unit(_sprite2, Vector2i(1, 1), true)

	_manager.cycle_selection(1)
	assert_int(_manager.get_selected_index()).is_equal(1)
	_manager.cycle_selection(1)
	assert_int(_manager.get_selected_index()).is_equal(0)

func test_index_of_unit_at() -> void:
	_manager.add_unit(_sprite1, Vector2i(10, 10), true)
	assert_int(_manager.index_of_unit_at(Vector2i(10, 10))).is_equal(0)
	assert_int(_manager.index_of_unit_at(Vector2i(0, 0))).is_equal(-1)