extends GdUnitTestSuite

# Classes are auto-global in Godot 4, no need for preload constants

class StubUnit extends Unit:
	var tentative := false
	var movement_blocked := false
	var action_blocked := false

	func has_tentative_move() -> bool:
		return tentative

	func block_movement_this_turn() -> void:
		movement_blocked = true

	func block_action_this_turn() -> void:
		action_blocked = true

class StubUnitManager extends UnitManager:
	var selected_index := 0
	var coords: Dictionary = {0: Vector2i.ZERO, 1: Vector2i.ONE}
	var player_flags: Dictionary = {0: true, 1: true}
	var selection_history: Array = []
	var cycle_calls: Array[int] = []
	var units: Dictionary = {0: StubUnit.new()}

	func get_selected_coord() -> Vector2i:
		return coords.get(selected_index, Vector2i.ZERO)

	func get_selected_index() -> int:
		return selected_index

	func get_unit_count() -> int:
		return coords.size()

	func get_unit(index: int):
		return units.get(index, null)

	func is_player_controlled(index: int) -> bool:
		return player_flags.get(index, false)

	func select_index(index: int) -> void:
		selected_index = index
		selection_history.append(index)

	func cycle_selection(direction: int) -> void:
		cycle_calls.append(direction)

	func index_of_unit_at(_cell: Vector2i) -> int:
		return -1

class StubHexNavigator extends HexNavigator:
	func map_action_by_camera(action: String, _from: Vector2i, _rotation: float, _grid) -> String:
		return action + "_mapped"

class StubCameraController extends CameraController:
	func get_rotation() -> float:
		return 0.0

class StubMoveController extends MoveController:
	var requested: Array[String] = []
	var requested_tentative: Array[String] = []
	var move_locked := false
	var cancel_count := 0
	var force_update_called := false

	func request_move(action: String) -> void:
		requested.append(action)

	func request_move_tentative(action: String) -> void:
		requested_tentative.append(action)

	func is_move_locked() -> bool:
		return move_locked

	func cancel_move() -> void:
		cancel_count += 1

	func force_action_menu_update() -> void:
		force_update_called = true

class StubTurnController extends TurnController:
	var enabled := true
	var allowed_indexes: Dictionary = {}
	var completed: Array[int] = []

	func is_enabled() -> bool:
		return enabled

	func can_act_on_index(index: int) -> bool:
		return allowed_indexes.get(index, false)

	func complete_player_activation(index: int) -> void:
		completed.append(index)

class StubGoalController extends GoalController:
	var reached := false

	func is_goal_reached() -> bool:
		return reached

	func reset_goal_state() -> void:
		reached = false

class StubHudController extends Node:
	var states: Array[bool] = []

	func set_ui_navigation_mode(enabled: bool) -> void:
		states.append(enabled)

class RecordingCommand extends GameCommand:
	var executions: Array = []

	func execute(context: GameCommandContext, payload = null) -> CommandResult:
		executions.append({"context": context, "payload": payload})
		return CommandResult.success()

class StubInputMapper extends Node:
	func apply_configs(_configs, _defaults) -> void:
		pass

class StubBindingService extends InputBindingService:
	var apply_calls: Array = []

	func apply_bindings(controls: Node, mapper: Node) -> void:
		apply_calls.append({"controls": controls, "mapper": mapper})

class RecordingInputController extends InputController:
	var select_calls: Array[int] = []
	var cycle_calls: Array[int] = []
	var wait_calls := 0
	var register_calls := 0

	func _on_select_index_requested(index: int) -> void:
		select_calls.append(index)

	func _on_selection_cycle_requested(direction: int) -> void:
		cycle_calls.append(direction)

	func _on_wait_requested() -> void:
		wait_calls += 1

	func _register_input_actions() -> void:
		register_calls += 1

func test_move_action_command_requests_mapped_direction_tentative() -> void:
	var unit_manager := StubUnitManager.new()
	var movec := StubMoveController.new()
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), movec, StubTurnController.new(), StubGoalController.new(), TileMapLayer.new())
	var command := MoveActionCommand.new()
	command.execute(context, "move_a")
	assert_that(movec.requested).contains_exactly(["move_a_mapped"])

func test_selection_cycle_command_cycles_units_even_when_turn_locked() -> void:
	var unit_manager := StubUnitManager.new()
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), StubMoveController.new(), StubTurnController.new(), StubGoalController.new(), TileMapLayer.new())
	var command := SelectionCycleCommand.new()
	var result := command.execute(context, 1)
	assert_bool(result.is_success()).is_true()
	assert_array(unit_manager.cycle_calls).contains_exactly([1])

func test_select_index_command_allows_selection_when_turn_locked() -> void:
	var unit_manager := StubUnitManager.new()
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), StubMoveController.new(), StubTurnController.new(), StubGoalController.new(), TileMapLayer.new())
	var command := SelectIndexCommand.new()
	var result := command.execute(context, 1)
	assert_bool(result.is_success()).is_true()
	assert_int(unit_manager.selection_history[-1]).is_equal(1)

func test_wait_command_respects_goal_and_turn_state() -> void:
	var unit_manager := StubUnitManager.new()
	var move_controller := StubMoveController.new()
	var turn_controller := StubTurnController.new()
	turn_controller.allowed_indexes = {0: true}
	var goal_controller := StubGoalController.new()
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), move_controller, turn_controller, goal_controller, TileMapLayer.new())
	var command := WaitCommand.new()
	command.execute(context)
	assert_array(turn_controller.completed).contains_exactly([0])

	goal_controller.reached = true
	command.execute(context)
	assert_array(turn_controller.completed).contains_exactly([0])

func test_input_command_router_set_commands_and_execute() -> void:
	var context := _build_full_context()
	var router := InputCommandRouter.new()
	router.set_context(context)
	var command := RecordingCommand.new()
	router.set_commands({"custom": command})
	router.execute("custom", 99)
	assert_that(command.executions.size()).is_equal(1)
	assert_that(command.executions[0]["context"]).is_same(context)
	assert_that(command.executions[0]["payload"]).is_equal(99)

func test_input_command_router_register_command_overrides_entry() -> void:
	var context := _build_full_context()
	var initial := RecordingCommand.new()
	var router := InputCommandRouter.new(context, {"wait": initial})
	var override := RecordingCommand.new()
	router.register_command("wait", override)
	router.execute("wait")
	assert_that(initial.executions.size()).is_equal(0)
	assert_that(override.executions.size()).is_equal(1)

func test_input_controller_apply_command_set_overrides_wait_command() -> void:
	var input_handler := InputHandler.new()
	var controller := _build_input_controller_for_signals(input_handler)
	var command := RecordingCommand.new()
	controller.apply_command_set({"wait": command})
	input_handler.wait_requested.emit()
	assert_that(command.executions.size()).is_equal(1)

func test_input_controller_default_command_set_includes_wait() -> void:
	var controller := InputController.new()
	var defaults := controller._default_command_set()
	assert_that(defaults.has("wait")).is_true()

func test_input_controller_request_select_index_invokes_handler() -> void:
	var controller := RecordingInputController.new()
	controller.request_select_index(3)
	assert_that(controller.select_calls).contains_exactly([3])

func test_input_controller_request_selection_cycle_invokes_handler() -> void:
	var controller := RecordingInputController.new()
	controller.request_selection_cycle(-1)
	assert_that(controller.cycle_calls).contains_exactly([-1])

func test_input_controller_request_wait_invokes_handler() -> void:
	var controller := RecordingInputController.new()
	controller.request_wait()
	assert_int(controller.wait_calls).is_equal(1)

func test_input_controller_register_input_actions_invokes_internal_registration() -> void:
	var controller := RecordingInputController.new()
	controller.register_input_actions()
	assert_int(controller.register_calls).is_equal(1)

func test_input_controller_selection_cycle_bypasses_turn_lock() -> void:
	var data := _build_input_controller_with_turn_permissions({})
	var handler: InputHandler = data["input_handler"]
	handler.selection_cycle_requested.emit(1)
	var unit_manager: StubUnitManager = data["unit_manager"]
	assert_array(unit_manager.cycle_calls).contains_exactly([1])

func test_input_controller_select_index_bypasses_turn_lock() -> void:
	var data := _build_input_controller_with_turn_permissions({})
	var handler: InputHandler = data["input_handler"]
	handler.select_index_requested.emit(1)
	var unit_manager: StubUnitManager = data["unit_manager"]
	assert_int(unit_manager.selection_history[-1]).is_equal(1)


func _build_full_context() -> GameCommandContext:
	return GameCommandContext.new(UnitManager.new(), HexNavigator.new(), CameraController.new(), MoveController.new(), TurnController.new(), GoalController.new(), TileMapLayer.new())

func _make_control_settings() -> Node:
	var settings := Node.new()
	settings.set("move_actions", [])
	settings.set("interaction_actions", [])
	settings.set("camera_actions", [])
	settings.set("selection_actions", [])
	settings.set("pause_actions", [])
	return settings

func _build_input_controller_for_signals(input_handler: InputHandler) -> InputController:
	var controller := InputController.new()
	var unit_manager := StubUnitManager.new()
	var hex_navigator := StubHexNavigator.new()
	var camera_controller := StubCameraController.new()
	var move_controller := StubMoveController.new()
	var turn_controller := StubTurnController.new()
	turn_controller.allowed_indexes = {0: true}
	var goal_controller := StubGoalController.new()
	var grid := TileMapLayer.new()
	var binding_service := StubBindingService.new()
	var command_context := GameCommandContext.new(
		unit_manager,
		hex_navigator,
		camera_controller,
		move_controller,
		turn_controller,
		goal_controller,
		grid
	)
	var command_router := InputCommandRouter.new(command_context)
	controller.setup(
		input_handler,
		unit_manager,
		hex_navigator,
		camera_controller,
		move_controller,
		turn_controller,
		goal_controller,
		grid,
		_make_control_settings(),
		StubInputMapper.new(),
		binding_service,
		command_context,
		command_router,
		null,
		null,
		{},
		null,
		StubHudController.new()
	)
	return controller

func _build_input_controller_with_turn_permissions(allowed_indexes: Dictionary) -> Dictionary:
	var input_handler := InputHandler.new()
	var controller := InputController.new()
	var unit_manager := StubUnitManager.new()
	var hex_navigator := StubHexNavigator.new()
	var camera_controller := StubCameraController.new()
	var move_controller := StubMoveController.new()
	var turn_controller := StubTurnController.new()
	turn_controller.allowed_indexes = allowed_indexes
	var goal_controller := StubGoalController.new()
	var grid := TileMapLayer.new()
	var binding_service := StubBindingService.new()
	var command_context := GameCommandContext.new(
		unit_manager,
		hex_navigator,
		camera_controller,
		move_controller,
		turn_controller,
		goal_controller,
		grid
	)
	var command_router := InputCommandRouter.new(command_context)
	var hud_controller := StubHudController.new()
	controller.setup(
		input_handler,
		unit_manager,
		hex_navigator,
		camera_controller,
		move_controller,
		turn_controller,
		goal_controller,
		grid,
		_make_control_settings(),
		StubInputMapper.new(),
		binding_service,
		command_context,
		command_router,
		null,
		null,
		{},
		null,
		hud_controller
	)
	return {
		"controller": controller,
		"input_handler": input_handler,
		"unit_manager": unit_manager,
		"turn_controller": turn_controller,
		"hud_controller": hud_controller
	}


func test_wait_command_blocks_actions_and_updates_ui() -> void:
	var unit_manager := StubUnitManager.new()
	var unit := StubUnit.new()
	unit.tentative = true
	unit_manager.units[0] = unit
	var move_controller := StubMoveController.new()
	var turn_controller := StubTurnController.new()
	turn_controller.allowed_indexes = {0: true}
	var goal_controller := StubGoalController.new()
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), move_controller, turn_controller, goal_controller, TileMapLayer.new())
	var command := WaitCommand.new()
	var result := command.execute(context)
	assert_bool(result.is_success()).is_true()
	assert_array(turn_controller.completed).contains_exactly([0])
	assert_bool(unit.movement_blocked).is_true()
	assert_bool(unit.action_blocked).is_true()
	assert_int(move_controller.cancel_count).is_equal(1)
	assert_bool(move_controller.force_update_called).is_true()



func test_set_ui_navigation_mode_updates_handler_and_hud() -> void:
	var data := _build_input_controller_with_turn_permissions({0: true})
	var controller: InputController = data["controller"]
	var handler: InputHandler = data["input_handler"]
	var hud_controller: StubHudController = data["hud_controller"]
	controller.set_ui_navigation_mode(true)
	assert_bool(handler._ui_nav_mode).is_true()
	assert_array(hud_controller.states).contains_exactly([true])
	controller.set_ui_navigation_mode(false)
	assert_bool(handler._ui_nav_mode).is_false()
	assert_array(hud_controller.states).contains_exactly([true, false])
