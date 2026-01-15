class_name GameState
extends Node2D

const Info := preload("res://GUI/info.gd")
const GridVisuals := preload("res://Gameplay/grid_visuals.gd")
const HUDController:= preload("res://Gameplay/hud_controller.gd")
const InputController:= preload("res://Gameplay/input_controller.gd")
const UnitController := preload("res://Gameplay/unit_controller.gd")
const GridController := preload("res://Gameplay/grid_controller.gd")
const CameraController := preload("res://Gameplay/camera_controller.gd")
const GoalController := preload("res://Gameplay/goal_controller.gd")
const TurnController := preload("res://Gameplay/turn_controller.gd")
const MapController := preload("res://Gameplay/map_controller.gd")

var unit_manager: UnitManager
var goal_manager: GoalManager
var hex_navigator: HexNavigator
var hud: Info
var grid_visuals: GridVisuals
var hud_controller: HUDController
var input_controller: InputController
var unit_controller: UnitController
var grid_controller: GridController
var camera_controller: CameraController
var goal_controller: GoalController
var turn_controller: TurnController
var map_controller: MapController

func _ready() -> void:
	unit_controller = UnitController.new()
	add_child(unit_controller)
	unit_controller.setup()
	unit_manager = unit_controller.get_unit_manager()

	goal_manager = GoalManager.new()
	add_child(goal_manager)

	hex_navigator = HexNavigator.new()
	add_child(hex_navigator)

	hud = Info.new()
	add_child(hud)

	grid_visuals = GridVisuals.new()
	add_child(grid_visuals)

	hud_controller = HUDController.new()
	add_child(hud_controller)

	input_controller = InputController.new()
	add_child(input_controller)

	grid_controller = GridController.new()
	add_child(grid_controller)

	camera_controller = CameraController.new()
	add_child(camera_controller)

	goal_controller = GoalController.new()
	add_child(goal_controller)

	turn_controller = TurnController.new()
	add_child(turn_controller)

	map_controller = MapController.new()
	add_child(map_controller)
