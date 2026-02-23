extends GdUnitTestSuite

const LevelManagerGameplay := preload("res://Gameplay/level_manager_gameplay.gd")
class StubLevelManagerGameplay extends LevelManagerGameplay:
	var hometown := false

	func _is_hometown_level(_level: Resource) -> bool:
		return hometown

class FreeRoamUnit extends RefCounted:
	var calls: Array[bool] = []
	var last_enabled := false

	func set_free_roam_mode(enabled: bool) -> void:
		calls.append(enabled)
		last_enabled = enabled

class UnitManagerStub extends UnitManager:
	var _stub_units: Array = []
	var _stub_player_indices: Array[int] = []

	func _init(units: Array, player_indices: Array[int]) -> void:
		_stub_units = units
		_stub_player_indices = player_indices

	func get_unit_count() -> int:
		return _stub_units.size()

	func is_player_controlled(index: int) -> bool:
		return _stub_player_indices.has(index)

	func get_unit(index: int):
		if index < 0 or index >= _stub_units.size():
			return null
		return _stub_units[index]

class FakeGameState extends GameState:
	func _init() -> void:
		pass

func test_handle_selected_unit_move_emits_once_exit() -> void:
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

func test_apply_hometown_rules_toggle_free_roam_for_player_unit() -> void:
	var manager := _make_manager()
	var fake_unit := FreeRoamUnit.new()
	var unit_manager := UnitManagerStub.new([fake_unit], [0])
	var fake_state := FakeGameState.new()
	fake_state.unit_manager = unit_manager
	manager._game_state = fake_state
	manager.hometown = true
	manager._apply_hometown_exploration_rules()
	assert_array(fake_unit.calls).is_equal([true])
	manager.hometown = false
	manager._apply_hometown_exploration_rules()
	assert_array(fake_unit.calls).is_equal([true, false])
	_cleanup_manager(manager)

func _make_manager() -> StubLevelManagerGameplay:
	var coordinator := Node2D.new()
	var manager := StubLevelManagerGameplay.new(null, coordinator, null)
	manager._level_resource = Resource.new()
	return manager

func _cleanup_manager(manager: StubLevelManagerGameplay) -> void:
	if manager and manager._coordinator:
		manager._coordinator.queue_free()
