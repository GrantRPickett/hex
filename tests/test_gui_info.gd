extends GdUnitTestSuite

const Hud := preload("res://GUI/hud.gd")
const GameConstants := preload("res://Autoloads/game_constants.gd")
const InputController := preload("res://Gameplay/inputs/input_controller.gd")
const CommandResult := preload("res://Gameplay/commands/command_result.gd")
const Unit := preload("res://Gameplay/targets/unit.gd")
const UnitManager := preload("res://Gameplay/targets/unit_manager.gd")
const UnitMovementBehavior := preload("res://Gameplay/targets/components/unit_movement_behavior.gd")

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

	func _execute_command(command_name: String, payload = null) -> CommandResult:
		executed_commands.append({
			"name": command_name,
			"payload": payload
		})
		if command_name == "confirm_move" and confirm_move_callback.is_valid():
			confirm_move_callback.call()
		return CommandResult.new()

var _hud: Hud
var _unit: Unit
var _unit_manager: FakeUnitManager
var _input_controller: FakeInputController

func before() -> void:
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

func after() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()

func test_wait_action_executes_wait_command() -> void:
	monitor_signals(_hud)
	await _hud.on_action_selected({"type": GameConstants.Commands.WAIT})
	assert_array(_get_command_names()).is_equal([GameConstants.Commands.WAIT])
	assert_signal(_hud).is_emitted("action_executed", [GameConstants.Commands.WAIT])

func test_action_aborts_when_no_selected_unit() -> void:
	_unit_manager.selected_unit_override = null
	await _hud.on_action_selected({"type": GameConstants.Commands.WAIT})
	assert_int(_input_controller.executed_commands.size()).is_equal(0)

func test_wait_action_confirms_tentative_move_before_wait() -> void:
	var movement := _unit.movement as StubMovementBehavior
	movement.tentative = true
	_input_controller.confirm_move_callback = func():
		movement.tentative = false
	await _hud.on_action_selected({"type": GameConstants.Commands.WAIT})
	assert_array(_get_command_names()).is_equal(["confirm_move", GameConstants.Commands.WAIT])

func test_attack_action_routes_payload_to_input_controller() -> void:
	var enemy := _create_test_unit()
	_unit_manager.register_unit(enemy, 1)
	monitor_signals(_hud)
	await _hud.on_action_selected({
		"type": GameConstants.Interactions.ATTACK,
		"target": enemy,
		"attribute_index": 2
	})
	var last_command = _input_controller.executed_commands.back()
	assert_str(last_command.get("name")).is_equal(GameConstants.Commands.ATTACK)
	assert_dict(last_command.get("payload")).is_equal({
		"attacker_index": 0,
		"target_index": 1,
		"attribute_index": 2
	})
	assert_signal(_hud).is_emitted("action_executed", [GameConstants.Interactions.ATTACK])

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

func _get_command_names() -> Array:
	var names: Array = []
	for entry in _input_controller.executed_commands:
		names.append(entry.get("name"))
	return names
