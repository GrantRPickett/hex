extends GdUnitTestSuite

const ActionsPanelScene := preload("res://GUI/actions_panel.tscn")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const UnitAttributesClass := preload("res://Gameplay/targets/unit_attributes.gd")
const TargetClass := preload("res://Gameplay/targets/target.gd")
const UnitManager := preload("res://Gameplay/targets/unit_manager.gd")

var _panel: ActionsPanel

func before_test() -> void:
	_panel = auto_free(ActionsPanelScene.instantiate() as ActionsPanel)
	get_tree().root.add_child(_panel)

func after_test() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()

func test_show_attack_menu_displays_targets_and_attributes() -> void:
	await get_tree().process_frame
	var attacker := _make_unit("Attacker")
	var target_a := _make_unit("Enemy A")
	var target_b := _make_unit("Enemy B")
	_panel.show_attack_menu(attacker, target_a, [target_a, target_b], [target_b])
	await get_tree().process_frame
	var buttons := _get_buttons()
	# 2 targets + 6 attributes + back = 9
	assert_int(buttons.size()).is_equal(9)
	assert_str(buttons[0].text).is_equal("Enemy A")
	assert_str(buttons[1].text).is_equal("Enemy B (Move)")
	assert_str(buttons[2].text).starts_with("Grit")
	assert_str(buttons[buttons.size() - 1].text).is_equal("Back")

func test_attack_menu_emits_action_for_selected_target() -> void:
	await get_tree().process_frame
	var attacker := _make_unit("Attacker")
	var target_a := _make_unit("Enemy A")
	var target_b := _make_unit("Enemy B")
	_panel.show_attack_menu(attacker, target_a, [target_a, target_b], [target_b])
	await get_tree().process_frame
	var target_b_button := _find_button_with_text("Enemy B (Move)")
	assert_object(target_b_button).is_not_null()
	target_b_button.pressed.emit()
	await get_tree().process_frame
	var attr_button := _find_button_starting_with("Grit")
	assert_object(attr_button).is_not_null()
	var emitted: Array = []
	_panel.action_selected.connect(func(action): emitted.append(action))
	attr_button.pressed.emit()
	await get_tree().process_frame
	assert_int(emitted.size()).is_equal(1)
	assert_object(emitted[0].get("target")).is_equal(target_b)

func test_get_current_attack_target_tracks_selection() -> void:
	await get_tree().process_frame
	var attacker := _make_unit("Attacker")
	var target_a := _make_unit("Enemy A")
	var target_b := _make_unit("Enemy B")
	_panel.show_attack_menu(attacker, target_a, [target_a, target_b], [target_b])
	await get_tree().process_frame
	assert_object(_panel.get_current_attack_target()).is_equal(target_a)
	var target_b_button := _find_button_with_text("Enemy B (Move)")
	assert_object(target_b_button).is_not_null()
	target_b_button.pressed.emit()
	await get_tree().process_frame
	assert_object(_panel.get_current_attack_target()).is_equal(target_b)

func _make_unit(p_name: String) -> Stubs.FakeUnit:
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	unit.unit_name = p_name
	unit.set_attribute_values(_default_attribute_values())
	return unit

func _default_attribute_values() -> Dictionary:
	var values: Dictionary = {}
	for attr_name in TargetClass.ATTRIBUTE_NAMES:
		values[attr_name] = 5
	return values

func _get_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var to_check: Array[Node] = _panel.actions_container.get_children()
	while to_check.size() > 0:
		var node = to_check.pop_back()
		if node is Button:
			buttons.append(node)
		to_check.append_array(node.get_children())
	buttons.reverse()
	return buttons

func _find_button_with_text(text: String) -> Button:
	for button in _get_buttons():
		if button.text == text:
			return button
	return null

func _find_button_starting_with(prefix: String) -> Button:
	for button in _get_buttons():
		if button.text.begins_with(prefix):
			return button
	return null

func test_enable_navigation_mode_focuses_first_button() -> void:
	_panel.show()
	var focus_button := Button.new()
	_panel.actions_container.add_child(focus_button)
	# Need to set focus_mode to enable grab_focus in tests
	focus_button.focus_mode = Control.FOCUS_ALL

	_panel.enable_navigation_mode()
	await get_tree().process_frame
	assert_bool(focus_button.has_focus()).is_true()
	_panel.disable_navigation_mode()

func test_set_auto_battle_mode_hides_hint_and_dims_panel() -> void:
	await get_tree().process_frame
	_panel.set_auto_battle_mode(true)
	await get_tree().process_frame
	assert_bool(_panel.hint_label.visible).is_false()
	assert_float(_panel.actions_container.modulate.a).is_between(0.5, 0.7)

	_panel.set_auto_battle_mode(false)
	await get_tree().process_frame
	assert_bool(_panel.hint_label.visible).is_true()
func test_should_defer_update_records_pending_request() -> void:
	var panel: ActionsPanel = auto_free(ActionsPanelScene.instantiate() as ActionsPanel)
	var unit := _make_unit("Deferred")
	var deferred: bool = panel._should_defer_update(unit, null, null, true)
	assert_bool(deferred).is_true()
	assert_object(panel._pending_update.unit).is_equal(unit)

func test_handle_missing_unit_returns_hint_when_unit_invalid() -> void:
	await get_tree().process_frame
	assert_bool(_panel._handle_missing_unit(null)).is_true()
	var expected: String = _panel._loc.get_text(_panel._loc.HUD_NO_UNIT_SELECTED)
	assert_str(_panel.hint_label.text).is_equal(expected)

func test_handle_missing_unit_returns_false_for_valid_unit() -> void:
	await get_tree().process_frame
	var unit := _make_unit("Hero")
	assert_bool(_panel._handle_missing_unit(unit)).is_false()

func test_handle_enemy_unit_shows_hint_for_non_player_unit() -> void:
	await get_tree().process_frame
	var manager := TestUnitManager.new(false)
	var unit := _make_unit("Enemy")
	assert_bool(_panel._handle_enemy_unit(manager, unit)).is_true()
	var expected: String = _panel._loc.get_text(_panel._loc.HUD_ENEMY_UNIT_SELECTED)
	assert_str(_panel.hint_label.text).is_equal(expected)

func test_handle_enemy_unit_returns_false_for_player_unit() -> void:
	await get_tree().process_frame
	var manager := TestUnitManager.new(true)
	var unit := _make_unit("Hero")
	assert_bool(_panel._handle_enemy_unit(manager, unit)).is_false()

func test_handle_no_actions_shows_hint_for_empty_actions() -> void:
	await get_tree().process_frame
	var unit := _make_unit("Hero")
	assert_bool(_panel._handle_no_actions(unit, [])).is_true()
	var expected: String = _panel._loc.get_text(_panel._loc.HUD_NO_ACTIONS_AVAILABLE)
	assert_str(_panel.hint_label.text).is_equal(expected)

func test_handle_no_actions_returns_false_when_actions_exist() -> void:
	await get_tree().process_frame
	var unit := _make_unit("Hero")
	assert_bool(_panel._handle_no_actions(unit, [ {}])).is_false()

func test_add_action_button_creates_button_with_label() -> void:
	await get_tree().process_frame
	var unit := _make_unit("Hero")
	var action := {"label": "Test Action", "available": true}
	var button := _panel._add_action_button(unit, action)
	assert_object(button).is_not_null()
	assert_str(button.text).is_equal("Test Action")

class TestUnitManager extends UnitManager:
	var _player_controlled := true
	func _init(player_controlled := true):
		_player_controlled = player_controlled
	func get_unit_index(_unit) -> int:
		return 0
	func is_player_controlled(_index: int) -> bool:
		return _player_controlled

func test_show_attribute_menu_using_action_dictionary() -> void:
	await get_tree().process_frame
	var attacker := _make_unit("Attacker")
	var target_a := _make_unit("Enemy A")
	var action := {
		"type": "attack",
		"label": "Attack",
		"target": target_a,
		"targets": [target_a],
		"needs_attribute": true
	}
	_panel.show_attribute_menu(attacker, action)
	await get_tree().process_frame
	assert_object(_panel.get_current_attack_target()).is_equal(target_a)
