extends GdUnitTestSuite

const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const CommandResult := preload("res://Gameplay/commands/command_result.gd")
const PlayerAction := preload("res://Gameplay/turn/player_action.gd")
const UnitMovementBehavior := preload("res://Gameplay/targets/components/unit_movement_behavior.gd")

class TestInputController extends InputController:
	var last_command: GameConstants.Commands.CommandID = GameConstants.Commands.CommandID.NONE
	var last_payload
	var tentative_stub
	func _execute_command(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult:
		last_command = command_id
		last_payload = payload
		if command_id == GameConstants.Commands.CommandID.CONFIRM_MOVE and tentative_stub:
			tentative_stub.pending = false
		return CommandResult.success()

class TentativeMovement extends UnitMovementBehavior:
	var pending := true

	func _init(unit: Unit) -> void:
		super (unit)

	func has_tentative_move() -> bool:
		return pending

class TentativeUnit extends Unit:
	var movement_stub: TentativeMovement
	func _init():
		super._init()
		movement_stub = TentativeMovement.new(self )
		movement = movement_stub

var _hud: Hud
var _unit_manager: Stubs.FakeUnitManager
var _controller: TestInputController
var _actor: Stubs.FakeUnit
var _target: Stubs.FakeUnit

func before_test() -> void:
	_hud = auto_free(Hud.new())
	get_tree().root.add_child(_hud)
	_unit_manager = Stubs.FakeUnitManager.new()
	_controller = TestInputController.new()
	_hud._unit_manager = _unit_manager
	_hud._input_controller = _controller
	_hud._action_executor = HudActionExecutor.new(_hud, _unit_manager, _controller)
	_actor = Stubs.FakeUnit.new()
	_target = Stubs.FakeUnit.new()
	_unit_manager.add_unit(_actor, Vector2i.ZERO)
	_unit_manager.add_unit(_target, Vector2i(1, 0))
	_unit_manager.select_index(0)
	_hud._current_unit = _unit_manager.get_selected_unit()
	_hud._current_unit_index = _unit_manager.get_selected_index()

func after_test() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()

func test_sync_selected_unit_tracks_manager() -> void:
	_unit_manager.select_index(1)
	assert_bool(_hud._sync_selected_unit()).is_true()
	assert_object(_hud._current_unit).is_equal(_target)

func test_command_success_helper_detects_status() -> void:
	assert_bool(_hud._action_executor._command_success(CommandResult.failed())).is_false()
	assert_bool(_hud._action_executor._command_success(CommandResult.success())).is_true()

func test_run_input_command_returns_null_without_controller() -> void:
	_hud._action_executor._input_controller = null
	assert_object(_hud._action_executor._run_input_command(GameConstants.Commands.CommandID.WAIT)).is_null()
	_hud._action_executor._input_controller = _controller
	assert_object(_hud._action_executor._run_input_command(GameConstants.Commands.CommandID.WAIT)).is_not_null()

func test_resolve_tentative_move_confirms_command() -> void:
	var unit := TentativeUnit.new()
	_hud._current_unit = unit
	_hud._current_unit_index = 0
	_controller.tentative_stub = unit.movement_stub
	assert_bool(await _hud._resolve_tentative_move_if_needed()).is_true()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.CONFIRM_MOVE)

	attack_action.command_id = GameConstants.Commands.CommandID.INTERACT
	attack_action.command_payload = {"type": GameConstants.Interactions.ATTACK}
	
	assert_bool(_hud._action_executor.execute_action(attack_action, _actor, 0)).is_true()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.INTERACT)
	
	var aid_action := PlayerAction.new()
	aid_action.type = GameConstants.ActionType.AID
	aid_action.target_object = _target
	aid_action.command_id = GameConstants.Commands.CommandID.AID
	assert_bool(_hud._action_executor.execute_action(aid_action, _actor, 0)).is_true()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.AID)
	
	var convince_action := PlayerAction.new()
	convince_action.type = GameConstants.ActionType.CONVINCE
	convince_action.target_object = _target
	convince_action.command_id = GameConstants.Commands.CommandID.INTERACT
	convince_action.command_payload = {"type": GameConstants.Interactions.CONVINCE}
	assert_bool(_hud._action_executor.execute_action(convince_action, _actor, 0)).is_true()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.INTERACT)

	var loot_action := PlayerAction.new()
	loot_action.type = GameConstants.ActionType.GATHER
	loot_action.command_id = GameConstants.Commands.CommandID.INTERACT
	loot_action.command_payload = {"type": GameConstants.Interactions.LOOT}
	assert_bool(_hud._action_executor.execute_action(loot_action, _actor, 0)).is_true()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.INTERACT)
	
	var skill_action := PlayerAction.new()
	skill_action.type = GameConstants.ActionType.SKILL
	skill_action.command_id = GameConstants.Commands.CommandID.USE_SKILL
	skill_action.command_payload = {GameConstants.Payload.SKILL: "Focus"}
	assert_bool(_hud._action_executor.execute_action(skill_action, _actor, 0)).is_true()
	
	var talk_action := PlayerAction.new()
	talk_action.type = GameConstants.ActionType.TALK
	talk_action.command_id = GameConstants.Commands.CommandID.INTERACT
	talk_action.command_payload = {"type": GameConstants.Interactions.TALK, "dialogue_id": "dlg_1"}
	assert_bool(_hud._action_executor.execute_action(talk_action, _actor, 0)).is_true()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.INTERACT)
