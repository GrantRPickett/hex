extends GdUnitTestSuite

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")
const GameCommandContext := preload("res://Gameplay/input_commands/game_command_context.gd")
const InputCommandRouter := preload("res://Gameplay/input_commands/input_command_router.gd")
const InputController := preload("res://Gameplay/input_controller.gd")
const InputHandler := preload("res://Gameplay/input_handler.gd")
const MoveActionCommand := preload("res://Gameplay/input_commands/move_action_command.gd")
const SelectionCycleCommand := preload("res://Gameplay/input_commands/selection_cycle_command.gd")
const WaitCommand := preload("res://Gameplay/input_commands/wait_command.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd")
const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const CameraController := preload("res://Gameplay/camera_controller.gd")
const MoveController := preload("res://Gameplay/move_controller.gd")
const TurnController := preload("res://Gameplay/turn_controller.gd")
const GoalController := preload("res://Gameplay/goal_controller.gd")

class StubUnitManager extends Node:
	var selected_index := 0
	var coords: Dictionary = {0: Vector2i.ZERO, 1: Vector2i.ONE}
	var player_flags: Dictionary = {0: true, 1: true}
	var selection_history: Array = []

	func get_selected_coord() -> Vector2i:
		return coords.get(selected_index, Vector2i.ZERO)

	func get_selected_index() -> int:
		return selected_index

	func get_unit_count() -> int:
		return coords.size()

	func is_player_controlled(index: int) -> bool:
		return player_flags.get(index, false)

	func select_index(index: int) -> void:
		selected_index = index
		selection_history.append(index)

	func cycle_selection(_direction: int) -> void:
		selection_history.append(-1)

	func index_of_unit_at(_cell: Vector2i) -> int:
		return -1

class StubHexNavigator extends Node:
	func map_action_by_camera(action: String, _from: Vector2i, _rotation: float, _grid) -> String:
		return action + "_mapped"

class StubCameraController extends Node:
	func get_rotation() -> float:
		return 0.0

class StubMoveController extends Node:
	var requested: Array[String] = []
	var move_locked := false

	func request_move(action: String) -> void:
		requested.append(action)

	func is_move_locked() -> bool:
		return move_locked

class StubTurnController extends Node:
	var enabled := true
	var allowed_indexes: Dictionary = {}
	var completed: Array[int] = []

	func is_enabled() -> bool:
		return enabled

	func can_act_on_index(index: int) -> bool:
		return allowed_indexes.get(index, false)

	func complete_player_activation(index: int) -> void:
		completed.append(index)

class StubGoalController extends Node:
	var reached := false

	func is_goal_reached() -> bool:
		return reached

	func reset_goal_state() -> void:
		reached = false

class RecordingCommand extends GameCommand:
	var executions: Array = []

	func execute(context: GameCommandContext, payload = null) -> void:
		executions.append({"context": context, "payload": payload})

class StubInputMapper extends Node:
	func apply_configs(_configs, _defaults) -> void:
		pass

func test_move_action_command_requests_mapped_direction() -> void:
	var unit_manager := StubUnitManager.new()
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), StubMoveController.new(), StubTurnController.new(), StubGoalController.new(), TileMapLayer.new())
	var command := MoveActionCommand.new()
	command.execute(context, "move_a")
	assert_that(context.move_controller.requested).contains_exactly(["move_a_mapped"])

func test_selection_cycle_command_skips_units_without_actions() -> void:
	var unit_manager := StubUnitManager.new()
	unit_manager.player_flags = {0: true, 1: true}
	var turn_controller := StubTurnController.new()
	turn_controller.allowed_indexes = {0: false, 1: true}
	var context := GameCommandContext.new(unit_manager, StubHexNavigator.new(), StubCameraController.new(), StubMoveController.new(), turn_controller, StubGoalController.new(), TileMapLayer.new())
	var command := SelectionCycleCommand.new()
	command.execute(context, 1)
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
	var controller := InputController.new()
	var command := RecordingCommand.new()
	controller.setup(input_handler, UnitManager.new(), HexNavigator.new(), CameraController.new(), MoveController.new(), TurnController.new(), GoalController.new(), TileMapLayer.new(), _make_control_settings(), StubInputMapper.new())
	controller.apply_command_set({"wait": command})
	input_handler.wait_requested.emit()
	assert_that(command.executions.size()).is_equal(1)

func test_input_controller_default_command_set_includes_wait() -> void:
	var controller := InputController.new()
	var defaults := controller._default_command_set()
	assert_that(defaults.has("wait")).is_true()

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
