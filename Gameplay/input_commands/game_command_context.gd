class_name GameCommandContext
extends RefCounted

var unit_manager: UnitManager
var hex_navigator: HexNavigator
var camera_controller: CameraController
var move_controller: MoveController
var turn_controller: TurnController
var goal_controller: GoalController
var grid: Node2D

func _init(
	p_unit_manager: UnitManager,
	p_hex_navigator: HexNavigator,
	p_camera_controller: CameraController,
	p_move_controller: MoveController,
	p_turn_controller: TurnController,
	p_goal_controller: GoalController,
	p_grid: Node2D
) -> void:
	unit_manager = p_unit_manager
	hex_navigator = p_hex_navigator
	camera_controller = p_camera_controller
	move_controller = p_move_controller
	turn_controller = p_turn_controller
	goal_controller = p_goal_controller
	grid = p_grid

## Validates that all required dependencies are present
func is_valid() -> bool:
	return (unit_manager != null and hex_navigator != null and
			camera_controller != null and move_controller != null and
			turn_controller != null and goal_controller != null and grid != null)

## Gets list of missing dependencies for debugging
func get_missing_dependencies() -> PackedStringArray:
	var missing: PackedStringArray = []
	if unit_manager == null:
		missing.append("unit_manager")
	if hex_navigator == null:
		missing.append("hex_navigator")
	if camera_controller == null:
		missing.append("camera_controller")
	if move_controller == null:
		missing.append("move_controller")
	if turn_controller == null:
		missing.append("turn_controller")
	if goal_controller == null:
		missing.append("goal_controller")
	if grid == null:
		missing.append("grid")
	return missing


