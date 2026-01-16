class_name GameSessionBuilder
extends RefCounted

const Info := preload("res://GUI/info.gd")
const GridVisuals := preload("res://Gameplay/grid_visuals.gd")
const HUDController := preload("res://Gameplay/hud_controller.gd")
const InputController := preload("res://Gameplay/input_controller.gd")
const UnitController := preload("res://Gameplay/unit_controller.gd")
const MoveController := preload("res://Gameplay/move_controller.gd")
const GridController := preload("res://Gameplay/grid_controller.gd")
const CameraController := preload("res://Gameplay/camera_controller.gd")
const GoalController := preload("res://Gameplay/goal_controller.gd")
const TurnController := preload("res://Gameplay/turn_controller.gd")
const MapController := preload("res://Gameplay/map_controller.gd")
const GoalManager := preload("res://Gameplay/goal_manager.gd")
const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
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
	var hex_navigator := HexNavigator.new()
	var hud := Info.new()
	var grid_visuals := GridVisuals.new()
	var hud_controller := HUDController.new()
	var input_controller := InputController.new()
	var move_controller := MoveController.new()
	var grid_controller := GridController.new()
	var camera_controller := CameraController.new()
	var goal_controller := GoalController.new()
	var turn_controller := TurnController.new()
	var map_controller := MapController.new()

	grid_controller.setup(config.grid)
	map_controller.setup(config.grid)
	turn_controller.setup(unit_manager)
	camera_controller.setup(config.camera, config.camera_handler, unit_manager)
	goal_controller.setup(goal_manager, unit_manager)
	move_controller.setup(unit_manager, unit_controller, hex_navigator, turn_controller, goal_controller, config.grid)

	var turn_system := turn_controller.get_turn_system()
	hud_controller.setup(hud, turn_system, unit_manager, config.grid)
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

	var tree_nodes: Array[Node] = [hud, grid_visuals, hud_controller, move_controller]
	return GameState.new(
		unit_controller,
		goal_manager,
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
		tree_nodes
	)
