class_name DefaultGameSessionServiceFactory
extends GameSessionServiceFactory

func create_services() -> Dictionary:
	var services := {}
	services[GameConstants.ContextKeys.UNIT_CONTROLLER] = _create_unit_controller()
	services[GameConstants.ContextKeys.UNIT_MANAGER] = services[GameConstants.ContextKeys.UNIT_CONTROLLER].get_unit_manager()
	services[GameConstants.ContextKeys.TASK_MANAGER] = TaskManager.new()
	services[GameConstants.ContextKeys.JOURNAL_MANAGER] = JournalManager
	services[GameConstants.ContextKeys.LOOT_MANAGER] = LootManager.new()
	services[GameConstants.ContextKeys.HEX_NAVIGATOR] = HexNavigator.new()

	services[GameConstants.ContextKeys.GRID_VISUALS] = GridVisuals.new()
	services[GameConstants.ContextKeys.HUD] = Hud.new()
	services[GameConstants.ContextKeys.HUD_CONTROLLER] = HUDController.new()
	services[GameConstants.ContextKeys.INPUT_CONTROLLER] = InputController.new()
	services[GameConstants.ContextKeys.MOVE_CONTROLLER] = MoveController.new()
	services[GameConstants.ContextKeys.ANIMATION_SERVICE] = AnimationRequestService.new()
	services[GameConstants.ContextKeys.CAMERA_CONTROLLER] = CameraController.new()
	services[GameConstants.ContextKeys.TASK_CONTROLLER] = TaskController.new()
	services[GameConstants.ContextKeys.TURN_CONTROLLER] = TurnController.new()
	services[GameConstants.ContextKeys.MAP_CONTROLLER] = MapController.new()
	services[GameConstants.ContextKeys.AI_CONTROLLER] = AIController.new()
	services[GameConstants.ContextKeys.COMBAT_SYSTEM] = CombatSystem.new()
	services[GameConstants.ContextKeys.CHECKPOINT_MANAGER] = CheckpointManager.new()
	services[GameConstants.ContextKeys.DIALOGUE_ACTION_SERVICE] = DialogueActionService.new()
	services[GameConstants.ContextKeys.LOCATION_SERVICE] = LocationService.new()
	services[GameConstants.ContextKeys.ACHIEVEMENT_MANAGER] = AchievementManager
	services[GameConstants.ContextKeys.SAVE_MANAGER] = SaveManager
	services[GameConstants.ContextKeys.WEATHER_MANAGER] = WeatherManager
	return services

func _create_unit_controller() -> UnitController:
	var controller := UnitController.new()
	controller.setup()
	return controller
