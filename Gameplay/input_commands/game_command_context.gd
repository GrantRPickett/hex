class_name GameCommandContext
extends RefCounted

var unit_manager: UnitManager
var hex_navigator: HexNavigator
var camera_controller: CameraController
var move_controller: MoveController
var turn_controller: TurnController
var task_controller: TaskController
var grid: Node2D
var grid_visuals: GridVisuals
var terrain_map: TerrainMap
var binding_service: InputBindingService
var dialogue_action_service: DialogueActionService

func _init(
	p_unit_manager: UnitManager,
	p_hex_navigator: HexNavigator,
	p_camera_controller: CameraController,
	p_move_controller: MoveController,
	p_turn_controller: TurnController,
	p_task_controller: TaskController,
	p_grid: Node2D,
	p_grid_visuals: GridVisuals = null,
	p_terrain_map: TerrainMap = null,
	p_binding_service: InputBindingService = null,
	dialogue_action_service: DialogueActionService = null
) -> void:
	unit_manager = p_unit_manager
	hex_navigator = p_hex_navigator
	camera_controller = p_camera_controller
	move_controller = p_move_controller
	turn_controller = p_turn_controller
	task_controller = p_task_controller
	grid = p_grid
	grid_visuals = p_grid_visuals
	terrain_map = p_terrain_map
	binding_service = p_binding_service
	dialogue_action_service = dialogue_action_service

## Validates that all required dependencies are present
func is_valid() -> bool:
	return (unit_manager != null and hex_navigator != null and
			camera_controller != null and move_controller != null and
			turn_controller != null and task_controller != null and grid != null)

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
	if task_controller == null:
		missing.append("task_controller")
	if grid == null:
		missing.append("grid")
	return missing

## Get a specific field by name (used by validators)
func get_field(field_name: String):
	match field_name:
		"unit_manager": return unit_manager
		"hex_navigator": return hex_navigator
		"camera_controller": return camera_controller
		"move_controller": return move_controller
		"turn_controller": return turn_controller
		"task_controller": return task_controller
		"grid": return grid
		"grid_visuals": return grid_visuals
		"terrain_map": return terrain_map
		"binding_service": return binding_service
		"dialogue_action_service": return dialogue_action_service
		_: return null

## Gets the grid dimensions
func get_grid_dimensions() -> Vector2i:
	if grid == null or not grid.has_meta("grid_width") or not grid.has_meta("grid_height"):
		return Vector2i.ZERO
	return Vector2i(grid.get_meta("grid_width"), grid.get_meta("grid_height"))

## Gets the selected unit index
func get_selected_unit_index() -> int:
	if unit_manager == null:
		return -1
	return unit_manager.get_selected_index()

## Gets the selected unit
func get_selected_unit() -> Unit:
	if unit_manager == null:
		return null
	return unit_manager.get_unit(unit_manager.get_selected_index())
