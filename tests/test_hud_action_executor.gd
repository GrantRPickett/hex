extends GdUnitTestSuite

var _hud: Node
var _unit_manager: UnitManager
var _input_controller: Node # Mock class won't strictly type match if not defined
var _executor: HudActionExecutor
var _action_emitted: bool = false

func before_test() -> void:
	_hud = auto_free(Node.new())
	_hud.add_user_signal("menu_requested", [{"name": "menu_name", "type": TYPE_STRING}, {"name": "action", "type": TYPE_OBJECT}])
	
	_unit_manager = auto_free(UnitManager.new())
	
	_input_controller = auto_free(Node.new())
	
	_executor = HudActionExecutor.new(_hud, _unit_manager, _input_controller)
	_action_emitted = false

func _on_menu_requested(menu_name: String, action: PlayerAction) -> void:
	if menu_name == "attack_menu":
		_action_emitted = true

func test_execute_action_open_attack_menu() -> void:
	_hud.connect("menu_requested", Callable(self, "_on_menu_requested"))
	
	var action: PlayerAction = PlayerAction.new()
	action.type = GameConstants.ActionType.OPEN_ATTACK_MENU
	
	var current_unit: Unit = auto_free(Unit.new())
	var result = _executor.execute_action(action, current_unit, 0)
	
	assert_that(result).is_true()
	assert_that(_action_emitted).is_true()
	current_unit.free()
