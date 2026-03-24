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

func test_execute_attack_and_support_commands_route_payloads() -> void:
	var attack_action := PlayerAction.new()
	attack_action.type = PlayerAction.Type.ATTACK
	attack_action.target = _target
	attack_action.attribute_index = 1
	
	assert_object(_hud._action_executor._execute_attack_command(attack_action, 0)).is_not_null()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.ATTACK)
	assert_object(_hud._action_executor._execute_attack_payload(1, 0, 0)).is_not_null()
	
	var aid_action := PlayerAction.new()
	aid_action.type = PlayerAction.Type.AID
	aid_action.target = _target
	assert_object(_hud._action_executor._execute_aid_command(aid_action, 0)).is_not_null()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.AID)
	
	var convince_action := PlayerAction.new()
	convince_action.type = PlayerAction.Type.CONVINCE
	convince_action.target = _target
	assert_object(_hud._action_executor._execute_convince_command(convince_action, 0)).is_not_null()
	assert_int(_controller.last_command).is_equal(GameConstants.Commands.CommandID.CONVINCE)
	assert_object(_hud._action_executor._execute_convince_payload(1, 0)).is_not_null()

func test_execute_loot_skill_and_talk_commands() -> void:
	var loot_action := PlayerAction.new()
	loot_action.type = PlayerAction.Type.GATHER
	assert_object(_hud._action_executor._execute_loot_command(loot_action, _actor, 0)).is_not_null()
	assert_object(_hud._action_executor._execute_loot_payload(0, Vector2i(2, 2))).is_not_null()
	
	var skill_action := PlayerAction.new()
	skill_action.type = PlayerAction.Type.SKILL
	skill_action.skill = "Focus"
	assert_object(_hud._action_executor._execute_skill_command(skill_action, 0)).is_not_null()
	
	var talk_action := PlayerAction.new()
	talk_action.type = PlayerAction.Type.TALK
	talk_action.target_index = 1
	talk_action.dialogue_id = "dlg_1"
	assert_object(_hud._action_executor._execute_talk_command(talk_action, 0)).is_not_null()
