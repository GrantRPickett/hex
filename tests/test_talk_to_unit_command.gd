extends GdUnitTestSuite

class MockDialogueService extends DialogueActionService:
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
	return GameCommandContext.new({
		GameConstants.ContextKeys.UNIT_MANAGER: auto_free(UnitManager.new()),
		GameConstants.ContextKeys.HEX_NAVIGATOR: auto_free(HexNavigator.new()),
		GameConstants.ContextKeys.CAMERA_CONTROLLER: auto_free(CameraController.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(MoveController.new()),
		GameConstants.ContextKeys.TURN_CONTROLLER: auto_free(TurnController.new()),
		GameConstants.ContextKeys.TASK_CONTROLLER: auto_free(TaskController.new()),
		GameConstants.ContextKeys.GRID: null,
		GameConstants.ContextKeys.GRID_VISUALS: null,
		GameConstants.ContextKeys.TERRAIN_MAP: null,
		GameConstants.ContextKeys.DIALOGUE_ACTION_SERVICE: service
	})

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
