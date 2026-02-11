extends GdUnitTestSuite

const TalkToUnitCommand := preload("res://Gameplay/input_commands/talk_to_unit_command.gd")
const GameCommandContext := preload("res://Gameplay/input_commands/game_command_context.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd")
const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const CameraController := preload("res://Gameplay/camera_controller.gd")
const MoveController := preload("res://Gameplay/move_controller.gd")
const TurnController := preload("res://Gameplay/turn_controller.gd")
const locationController := preload("res://Gameplay/location_controller.gd")

class MockDialogueService extends RefCounted:
	var last_call: Dictionary
	var result := CommandResult.success()

	func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
		last_call = {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index,
		}
		return result

func _create_context(service = null) -> GameCommandContext:
	return GameCommandContext.new(
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
		service
	)

func test_execute_requires_dialogue_service() -> void:
	var command := TalkToUnitCommand.new()
	var context := _create_context()
	var payload := {
		"initiator_index": 0,
		"target_index": 1,
		"dialogue_id": StringName("intro")
	}
	var result := command.execute(context, payload)
	assert_that(result.status).is_equal(CommandResult.Status.INVALID_CONTEXT)

func test_execute_invokes_service_with_payload() -> void:
	var command := TalkToUnitCommand.new()
	var mock_service := MockDialogueService.new()
	var context := _create_context(mock_service)
	var payload := {
		"initiator_index": 2,
		"target_index": 3,
		"dialogue_id": StringName("hometown")
	}
	var result := command.execute(context, payload)
	assert_that(result.is_success()).is_true()
	assert_that(mock_service.last_call.get("initiator_index")).is_equal(2)
	assert_that(mock_service.last_call.get("target_index")).is_equal(3)
	assert_that(mock_service.last_call.get("dialogue_id")).is_equal(StringName("hometown"))
