extends GdUnitTestSuite

const Hud := preload("res://GUI/hud.gd")

const InputController := preload("res://Gameplay/inputs/input_controller.gd")
const CommandResult := preload("res://Gameplay/commands/command_result.gd")
const Unit := preload("res://Gameplay/targets/unit.gd")
const UnitManager := preload("res://Gameplay/targets/unit_manager.gd")
const UnitMovementBehavior := preload("res://Gameplay/targets/components/unit_movement_behavior.gd")
const UnitAction := preload("res://Gameplay/turn/unit_action.gd")

class StubMovementBehavior extends UnitMovementBehavior:
	var tentative := false

	func _init(_unit_ref: Unit) -> void:
		pass

	func has_tentative_move() -> bool:
		return tentative

	func has_move_available() -> bool:
		return not tentative

class FakeUnitManager extends UnitManager:
	var selected_unit_override: Unit
	var selected_index_override := 0
	var unit_indices := {}
	var coords := {}

	func get_selected_unit() -> Unit:
		return selected_unit_override

	func get_selected_index() -> int:
		return selected_index_override

	func register_unit(unit: Unit, index: int, coord: Vector2i = Vector2i.ZERO) -> void:
		unit_indices[unit] = index
		coords[index] = coord

	func get_unit_index(unit: Unit) -> int:
		return unit_indices.get(unit, -1)

	func get_coord(index: int) -> Vector2i:
		return coords.get(index, Vector2i.ZERO)

class FakeInputController extends InputController:
	var executed_commands: Array = []
	var confirm_move_callback: Callable = Callable()

	func _execute_command(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult:
		executed_commands.append({
			"id": command_id,
			"payload": payload
		})
		if command_id == GameConstants.Commands.CommandID.CONFIRM_MOVE and confirm_move_callback.is_valid():
			confirm_move_callback.call()
		return CommandResult.new()

var _hud: Hud
var _unit: Unit
var _unit_manager: FakeUnitManager
var _input_controller: FakeInputController

func before_test() -> void:
	_hud = auto_free(Hud.new())
	get_tree().root.add_child(_hud)
	_unit = _create_test_unit()
	_unit_manager = FakeUnitManager.new()
	_unit_manager.selected_unit_override = _unit
	_unit_manager.selected_index_override = 0
	_unit_manager.register_unit(_unit, 0)
	_input_controller = FakeInputController.new()
	_hud._unit_manager = _unit_manager
	_hud._input_controller = _input_controller
	_hud._action_executor = HudActionExecutor.new(_hud, _unit_manager, _input_controller)

func after_test() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()

func test_wait_action_executes_wait_command() -> void:
	monitor_signals(_hud)
	var wait_action := UnitAction.new(UnitAction.Type.WAIT)
	await _hud.on_action_selected(wait_action)
	assert_array(_get_command_ids()).is_equal([GameConstants.Commands.CommandID.WAIT])
	assert_signal(_hud).is_emitted("action_executed", [UnitAction.Type.WAIT])

func test_action_aborts_when_no_selected_unit() -> void:
	_unit_manager.selected_unit_override = null
	var wait_action := UnitAction.new(UnitAction.Type.WAIT)
	await _hud.on_action_selected(wait_action)
	assert_int(_input_controller.executed_commands.size()).is_equal(0)

func test_wait_action_confirms_tentative_move_before_wait() -> void:
	var movement := _unit.movement as StubMovementBehavior
	movement.tentative = true
	_input_controller.confirm_move_callback = func():
		movement.tentative = false
	var wait_action := UnitAction.new(UnitAction.Type.WAIT)
	await _hud.on_action_selected(wait_action)
	assert_array(_get_command_ids()).is_equal([GameConstants.Commands.CommandID.CONFIRM_MOVE, GameConstants.Commands.CommandID.WAIT])

func test_attack_action_routes_payload_to_input_controller() -> void:
	var enemy := _create_test_unit()
	_unit_manager.register_unit(enemy, 1)
	monitor_signals(_hud)
	
	var attack_action := UnitAction.new(UnitAction.Type.ATTACK)
	attack_action.target = enemy
	attack_action.attribute_index = 2
	
	await _hud.on_action_selected(attack_action)
	
	var last_command = _input_controller.executed_commands.back()
	assert_int(last_command.get("id")).is_equal(GameConstants.Commands.CommandID.ATTACK)
	assert_dict(last_command.get("payload")).is_equal({
		"attacker_index": 0,
		"target_index": 1,
		"attribute_index": 2
	})
	assert_signal(_hud).is_emitted("action_executed", [UnitAction.Type.ATTACK])

func test_show_warning_message_creates_overlay() -> void:
	await get_tree().process_frame
	_hud.show_warning_message("Danger")
	await get_tree().process_frame
	var overlay = _hud.get_node_or_null("WarningOverlay")
	assert_object(overlay).is_not_null()
	assert_int(overlay.get_child_count()).is_greater(0)

func _create_test_unit() -> Unit:
	var unit: Unit = Unit.new()
	unit.movement = StubMovementBehavior.new(unit)
	return unit

func _get_command_ids() -> Array:
	var ids: Array = []
	for entry in _input_controller.executed_commands:
		ids.append(entry.get("id"))
	return ids
