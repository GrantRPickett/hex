class_name GameSessionBuilder
extends RefCounted

const InputMapper := preload("res://Autoloads/input_mapper.gd")

class Config extends RefCounted:
	var grid: Node2D
	var camera: Camera2D
	var camera_handler: CameraHandler
	var input_handler: InputHandler
	var controls: Node
	var input_mapper: Node

func build(config: Config) -> GameState:
	assert(config != null, "GameSessionBuilder requires a config object.")
	assert(config.grid != null, "GameSessionBuilder requires a grid reference.")
	var unit_controller := UnitController.new()
	unit_controller.setup()
	var unit_manager := unit_controller.get_unit_manager()

	var goal_manager := GoalManager.new()
	var loot_manager := LootManager.new()
	var hex_navigator: HexNavigator = HexNavigator.new()
	var hud: Info = Info.new()
	var grid_visuals: GridVisuals = GridVisuals.new()
	var hud_controller: HUDController = HUDController.new()
	var input_controller: InputController = InputController.new()
	var move_controller: MoveController = MoveController.new()
	var grid_controller := GridController.new()
	var camera_controller := CameraController.new()
	var goal_controller := GoalController.new()
	var turn_controller := TurnController.new()
	var map_controller := MapController.new()
	var ai_controller := AIController.new()
	var combat_system := CombatSystem.new()

	grid_controller.setup(config.grid)
	map_controller.setup(config.grid)
	turn_controller.setup(unit_manager, ai_controller)
	camera_controller.setup(config.camera, config.camera_handler, unit_manager)
	goal_controller.setup(goal_manager, unit_manager)
	move_controller.setup(unit_manager, unit_controller, hex_navigator, turn_controller, goal_controller, map_controller, config.grid, hud)

	ai_controller.setup(unit_manager, map_controller, combat_system, unit_controller, goal_manager, loot_manager)

	var turn_system := turn_controller.get_turn_system()
	hud_controller.setup(hud, turn_system, unit_manager, goal_manager, config.grid)
	input_controller.setup(
		config.input_handler,
		unit_manager,
		hex_navigator,
		camera_controller,
		move_controller,
		turn_controller,
		goal_controller,
		config.grid,
		config.controls,
		config.input_mapper if config.input_mapper != null else InputMapper.new()
	)
	# Setup hud AFTER input_controller is configured
	hud.setup(unit_manager, turn_controller, input_controller)

	var tree_nodes: Array[Node] = [hud, grid_visuals, hud_controller, move_controller, loot_manager, ai_controller, combat_system]
	return GameState.new(
		unit_controller,
		goal_manager,
		loot_manager,
		hex_navigator,
		hud,
		grid_visuals,
		hud_controller,
		input_controller,
		move_controller,
		grid_controller,
		camera_controller,
		goal_controller,
		turn_controller,
		map_controller,
		ai_controller,
		combat_system,
		tree_nodes
	)
