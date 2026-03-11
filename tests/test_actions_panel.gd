extends GdUnitTestSuite

const ActionsPanelClass := preload("res://GUI/actions_panel.gd")
const HUDControllerClass := preload("res://GUI/HUD/hud_controller.gd")

var _panel: ActionsPanel
var _hud: Node

func before_test() -> void:
	_hud = auto_free(Node.new())
	_panel = auto_free(ActionsPanelClass.new())
	_hud.add_child(_panel)

func after_test() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	if is_instance_valid(_hud):
		_hud.queue_free()

func _make_unit(player := true) -> Unit:
	var unit: Unit = auto_free(Unit.new())
	unit.unit_name = "Hero" if player else "Enemy"
	unit.faction = Unit.Faction.PLAYER if player else Unit.Faction.ENEMY
	return unit

func test_show_attack_menu_displays_targets_and_attributes() -> void:
	var attacker := _make_unit(true)
	var targets = [_make_unit(false), _make_unit(false)]
	
	_panel.show_attack_menu(attacker, targets)
	
	# Attributes (7 total, but maybe 6 displayed?) + Targets (2) + Back (1)
	# Based on ActionsPanel code, it displays 6 attributes in combat
	# 6 (attributes) + 2 (targets) + 1 (back) = 9
	assert_int(_panel.actions_container.get_child_count()).is_equal(9)

func test_set_auto_battle_mode_hides_hint_and_dims_panel() -> void:
	_panel.set_auto_battle_mode(true)
	
	assert_bool(_panel.hint_label.visible).is_false()
	# Use is_between for float precision
	assert_float(_panel.actions_container.modulate.a).is_between(0.5, 0.7)

func test_enable_navigation_mode_focuses_first_button() -> void:
	var attacker := _make_unit(true)
	_panel.show_attack_menu(attacker, [_make_unit(false)])
	
	_panel.enable_navigation_mode()
	
	var first_button = _panel.actions_container.get_child(0)
	assert_bool(first_button.has_focus()).is_true()

# Force re-import 202603112000
