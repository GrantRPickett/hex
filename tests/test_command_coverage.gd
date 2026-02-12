## Comprehensive test coverage for command system functions and context accessors
extends GdUnitTestSuite

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")
const GameCommandContext := preload("res://Gameplay/input_commands/game_command_context.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")

# Command implementations to test
const AidAllyCommand := preload("res://Gameplay/input_commands/aid_ally_command.gd")
const AttackUnitCommand := preload("res://Gameplay/input_commands/attack_unit_command.gd")
const JoyMoveCommand := preload("res://Gameplay/input_commands/joy_move_command.gd")
const LootCommand := preload("res://Gameplay/input_commands/loot_command.gd")
const MoveActionCommand := preload("res://Gameplay/input_commands/move_action_command.gd")
const PrimaryActionCommand := preload("res://Gameplay/input_commands/primary_action_command.gd")
const SelectionCycleCommand := preload("res://Gameplay/input_commands/selection_cycle_command.gd")
const SelectIndexCommand := preload("res://Gameplay/input_commands/select_index_command.gd")
const ToggleFreeCamCommand := preload("res://Gameplay/input_commands/toggle_free_cam_command.gd")
const WaitCommand := preload("res://Gameplay/input_commands/wait_command.gd")
const WorkOnTaskCommand := preload("res://Gameplay/input_commands/work_on_task_command.gd")
const ZoomCameraCommand := preload("res://Gameplay/input_commands/zoom_camera_command.gd")


# ============================================================================
# CommandResult Tests
# ============================================================================

func test_command_result_is_success_returns_true_for_success() -> void:
	var result := CommandResult.success()
	assert_that(result.is_success()).is_true()


func test_command_result_is_success_returns_false_for_failure() -> void:
	var result := CommandResult.failed("test failure")
	assert_that(result.is_success()).is_false()


func test_command_result_is_failure_returns_true_for_failure() -> void:
	var result := CommandResult.failed("test failure")
	assert_that(result.is_failure()).is_true()


func test_command_result_is_failure_returns_false_for_success() -> void:
	var result := CommandResult.success()
	assert_that(result.is_failure()).is_false()


func test_command_result_get_description_returns_description() -> void:
	var description := "Command failed due to invalid target"
	var result := CommandResult.failed(description)
	assert_that(result.get_description()).is_not_empty()


func test_command_result_get_description_returns_empty_for_success() -> void:
	var result := CommandResult.success()
	var desc: String = result.get_description()
	assert_that(desc).is_not_null()


# ============================================================================
# GameCommandContext Tests
# ============================================================================

const UnitManager := preload("res://Gameplay/unit_manager.gd")
const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const CameraController := preload("res://Gameplay/camera_controller.gd")
const MoveController := preload("res://Gameplay/move_controller.gd")
const TurnController := preload("res://Gameplay/turn_controller.gd")
const locationController := preload("res://Gameplay/location_controller.gd")
const DialogueActionService := preload("res://Gameplay/dialogue_action_service.gd")

func test_game_command_context_get_field_returns_unit_manager() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var context: GameCommandContext = GameCommandContext.new(
		unit_manager,
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	assert_object(context.get_field("unit_manager")).is_equal(unit_manager)


func test_game_command_context_get_field_returns_hex_navigator() -> void:
	var hex_navigator: HexNavigator = auto_free(HexNavigator.new())
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		hex_navigator,
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	assert_object(context.get_field("hex_navigator")).is_equal(hex_navigator)


func test_game_command_context_get_field_returns_camera_controller() -> void:
	var camera_controller: CameraController = auto_free(CameraController.new())
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		camera_controller,
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	assert_object(context.get_field("camera_controller")).is_equal(camera_controller)


func test_game_command_context_get_field_returns_move_controller() -> void:
	var move_controller: MoveController = auto_free(MoveController.new())
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		move_controller,
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	assert_object(context.get_field("move_controller")).is_equal(move_controller)

func test_game_command_context_get_field_returns_dialogue_service() -> void:
	var dialogue_service := DialogueActionService.new()
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new(),
		null,
		null,
		null,
		dialogue_service
	)
	assert_object(context.get_field("dialogue_action_service")).is_equal(dialogue_service)

func test_game_command_context_get_field_returns_turn_controller() -> void:
	var turn_controller: TurnController = auto_free(TurnController.new())
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		turn_controller,
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	assert_object(context.get_field("turn_controller")).is_equal(turn_controller)


func test_game_command_context_get_field_returns_location_controller() -> void:
	var location_controller: locationController = auto_free(locationController.new())
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		location_controller,
		TileMapLayer.new()
	)
	assert_object(context.get_field("location_controller")).is_equal(location_controller)


func test_game_command_context_get_field_returns_tilemap() -> void:
	var tilemap: TileMapLayer = TileMapLayer.new()
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		tilemap
	)
	assert_object(context.get_field("tilemap")).is_equal(tilemap)


func test_game_command_context_get_field_returns_null_for_invalid() -> void:
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	assert_object(context.get_field("invalid_field")).is_null()


func test_game_command_context_get_grid_dimensions_returns_vector2i() -> void:
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	var dims: Vector2i = context.get_grid_dimensions()
	assert_that(dims).is_not_equal(Vector2i(0,0))


func test_game_command_context_get_selected_unit_index_returns_int() -> void:
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	var index: int = context.get_selected_unit_index()
	assert_int(index).is_greater(-1)


# ============================================================================
# GameCommand Base Tests
# ============================================================================

func test_game_command_get_required_context_fields_returns_packed_string_array() -> void:
	var cmd: GameCommand = auto_free(GameCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_game_command_validate_context_succeeds_with_valid_context() -> void:
	var context: GameCommandContext = GameCommandContext.new(
		auto_free(UnitManager.new()),
		auto_free(HexNavigator.new()),
		auto_free(CameraController.new()),
		auto_free(MoveController.new()),
		auto_free(TurnController.new()),
		auto_free(locationController.new()),
		TileMapLayer.new()
	)
	var cmd: GameCommand = auto_free(GameCommand.new())
	var result: CommandResult = cmd.validate_context(context)
	assert_bool(result.is_success()).is_true()


# ============================================================================
# Command Subclass get_required_context_fields Tests
# ============================================================================

func test_aid_ally_command_get_required_context_fields_returns_array() -> void:
	var cmd: AidAllyCommand = auto_free(AidAllyCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_attack_unit_command_get_required_context_fields_returns_array() -> void:
	var cmd: AttackUnitCommand = auto_free(AttackUnitCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_joy_move_command_get_required_context_fields_returns_array() -> void:
	var cmd: JoyMoveCommand = auto_free(JoyMoveCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_loot_command_get_required_context_fields_returns_array() -> void:
	var cmd: LootCommand = auto_free(LootCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_move_action_command_get_required_context_fields_returns_array() -> void:
	var cmd: MoveActionCommand = auto_free(MoveActionCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_primary_action_command_get_required_context_fields_returns_array() -> void:
	var cmd: PrimaryActionCommand = auto_free(PrimaryActionCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_selection_cycle_command_get_required_context_fields_returns_array() -> void:
	var cmd: SelectionCycleCommand = auto_free(SelectionCycleCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_select_index_command_get_required_context_fields_returns_array() -> void:
	var cmd: SelectIndexCommand = auto_free(SelectIndexCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_toggle_free_cam_command_get_required_context_fields_returns_array() -> void:
	var cmd: ToggleFreeCamCommand = auto_free(ToggleFreeCamCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_that(fields).is_not_empty()


func test_wait_command_get_required_context_fields_returns_array() -> void:
	var cmd: WaitCommand = auto_free(WaitCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_array(fields).is_not_empty()


func test_work_on_task_command_get_required_context_fields_returns_array() -> void:
	var cmd: WorkOnTaskCommand = auto_free(WorkOnTaskCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_array(fields).is_not_empty()


func test_zoom_camera_command_get_required_context_fields_returns_array() -> void:
	var cmd: ZoomCameraCommand = auto_free(ZoomCameraCommand.new())
	var fields := cmd.get_required_context_fields()
	assert_array(fields).is_not_empty()
