extends GdUnitTestSuite

const LevelManagerGameplay := preload("res://Gameplay/level_manager_gameplay.gd")
class StubLevelManagerGameplay extends LevelManagerGameplay:
	var hometown := false

	func _is_hometown_level(_level: Resource) -> bool:
		return hometown

func test_handle_selected_unit_move_emits_once_for_hometown_exit() -> void:
	var manager := _make_manager()
	manager.hometown = true
	var emitted := false
	manager.quit_to_level_select.connect(func(): emitted = true)
	manager.handle_selected_unit_move(Vector2i(1, 1))
	assert_bool(emitted).is_true()

	emitted = false
	manager.handle_selected_unit_move(Vector2i(1, 1))
	assert_bool(emitted).is_false()

	_cleanup_manager(manager)

func test_handle_selected_unit_move_ignores_non_hometown_or_coord() -> void:
	var manager := _make_manager()
	var emitted := false
	manager.quit_to_level_select.connect(func(): emitted = true)

	manager.handle_selected_unit_move(Vector2i(1, 1))
	assert_bool(emitted).is_false()

	manager.hometown = true
	manager.handle_selected_unit_move(Vector2i(0, 0))
	assert_bool(emitted).is_false()

	_cleanup_manager(manager)

func _make_manager() -> StubLevelManagerGameplay:
	var coordinator := Node2D.new()
	var manager := StubLevelManagerGameplay.new(null, coordinator, null)
	manager._level_resource = Resource.new()
	return manager

func _cleanup_manager(manager: StubLevelManagerGameplay) -> void:
	if manager and manager._coordinator:
		manager._coordinator.queue_free()
