class_name DefaultGameSessionServiceFactory
extends GameSessionServiceFactory

const DialogueActionService := preload("res://Gameplay/dialogue_action_service.gd")

func create_services() -> GameSessionServices:
	var services := GameSessionServices.new()
	services.unit_controller = _create_unit_controller()
	services.unit_manager = services.unit_controller.get_unit_manager()
	services.goal_manager = GoalManager.new()
	services.loot_manager = LootManager.new()
	services.hex_navigator = HexNavigator.new()

	services.grid_visuals = GridVisuals.new()
	services.hud_controller = HUDController.new()
	services.input_controller = InputController.new()
	services.move_controller = MoveController.new()
	services.grid_controller = GridController.new()
	services.camera_controller = CameraController.new()
	services.goal_controller = GoalController.new()
	services.turn_controller = TurnController.new()
	services.map_controller = MapController.new()
	services.ai_controller = AIController.new()
	services.combat_system = CombatSystem.new()
	services.checkpoint_manager = CheckpointManager.new()
	services.dialogue_action_service = DialogueActionService.new()
	return services

func _create_unit_controller() -> UnitController:
	var controller := UnitController.new()
	controller.setup()
	return controller
