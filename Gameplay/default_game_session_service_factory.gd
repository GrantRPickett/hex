class_name DefaultGameSessionServiceFactory
extends GameSessionServiceFactory

func create_services() -> Dictionary:
	var services := {}
	services["unit_controller"] = _create_unit_controller()
	services["unit_manager"] = services["unit_controller"].get_unit_manager()
	services["task_manager"] = TaskManager.new()
	services["journal_manager"] = JournalManager
	services["loot_manager"] = LootManager.new()
	services["hex_navigator"] = HexNavigator.new()

	services["grid_visuals"] = GridVisuals.new()
	services["hud"] = Hud.new()
	services["hud_controller"] = HUDController.new()
	services["input_controller"] = InputController.new()
	services["move_controller"] = MoveController.new()
	services["animation_service"] = AnimationRequestService.new()
	services["grid_controller"] = GridController.new()
	services["camera_controller"] = CameraController.new()
	services["task_controller"] = TaskController.new()
	services["turn_controller"] = TurnController.new()
	services["map_controller"] = MapController.new()
	services["ai_controller"] = AIController.new()
	services["combat_system"] = CombatSystem.new()
	services["checkpoint_manager"] = CheckpointManager.new()
	services["dialogue_action_service"] = DialogueActionService.new()
	services["location_service"] = LocationService.new()
	services["achievement_manager"] = AchievementManager
	services["save_manager"] = SaveManager
	services["weather_manager"] = WeatherManager
	return services

func _create_unit_controller() -> UnitController:
	var controller := UnitController.new()
	controller.setup()
	return controller
