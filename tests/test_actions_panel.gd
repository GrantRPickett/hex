extends GdUnitTestSuite

const ActionsPanelScene := preload("res://GUI/actions_panel.tscn")
const HUDControllerClass := preload("res://GUI/HUD/hud_controller.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")

var _panel: ActionsPanel
var _hud: Node
var _unit_manager: Stubs.FakeUnitManager
var _terrain_map: Stubs.FakeTerrainMap


func before_test() -> void:
	_hud = auto_free(Node.new())
	get_tree().root.add_child(_hud)
	_panel = auto_free(ActionsPanelScene.instantiate())
	_hud.add_child(_panel)
	_unit_manager = auto_free(Stubs.FakeUnitManager.new())
	_terrain_map = auto_free(Stubs.FakeTerrainMap.new())
	_unit_manager.set_loot_manager(auto_free(Stubs.FakeLootManager.new()))
	_unit_manager.set_task_manager(auto_free(Stubs.FakeTaskManager.new()))


func after_test() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()

func _make_unit(player := true) -> Unit:
	var unit: Unit = auto_free(Unit.new())
	unit.unit_name = "Hero" if player else "Enemy"
	unit.faction = GameConstants.Faction.PLAYER if player else GameConstants.Faction.ENEMY

	unit.grit = 10
	unit.flow = 10
	unit.focus = 10
	unit.base_willpower = 10
	unit.gusto = 10
	unit.shade = 10
	unit.shine = 10

	# Setup components
	unit._ready()
	if unit.res:
		unit.res.set_willpower(10)
		unit.res.set_max_willpower(10)
	
	_unit_manager.add_unit(unit, Vector2i(0, 0), player)
	return unit


func test_show_attack_menu_displays_targets_and_attributes() -> void:
	var attacker := _make_unit(true)
	var _targets = [_make_unit(false), _make_unit(false)]

	# update_actions(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool = true)
	_panel.update_actions(attacker, _terrain_map, _unit_manager)


	# Assuming its standard list of actions + potential overhead
	# Just verify it's showing something and then show_attribute_menu
	var action: PlayerAction = PlayerAction.new(GameConstants.ActionType.ATTACK)
	_panel.show_attribute_menu(attacker, action)

	# HintLabel (1) + GridContainer (1) + Back Button (1) = 3
	# Filter out queued-for-deletion children to avoid lifecycle race conditions
	var active_children = _panel.actions_container.get_children().filter(func(c): return not c.is_queued_for_deletion())
	assert_int(active_children.size()).is_equal(3) # HintLabel, GridContainer, BackButton

func test_set_auto_battle_mode_hides_hint_and_dims_panel() -> void:
	_panel.set_auto_battle_mode(true)

	assert_bool(_panel.hint_label.visible).is_false()
	# Use is_equal_approx for float precision
	assert_float(_panel.actions_container.modulate.a).is_equal_approx(0.6, 0.01)

func test_enable_navigation_mode_focuses_first_button() -> void:
	var attacker := _make_unit(true)
	_panel.update_actions(attacker, _terrain_map, _unit_manager)


	_panel.enable_navigation_mode()

	# First child is usually HintLabel if not hidden, then buttons
	var button = null
	for child in _panel.actions_container.get_children():
		if child is Button:
			button = child
			break

	assert_object(button).is_not_null()
	if button:
		assert_bool(button.has_focus()).is_true()

# Force re-import 202603112000
