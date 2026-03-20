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
var loot_manager: LootManager
var task_manager: TaskManager
var map_controller: MapController
var auto_battle_active: bool = false

func _init(p_params: Dictionary = {}) -> void:
	if p_params.is_empty():
		return

	unit_manager = p_params.get(GameConstants.ContextKeys.UNIT_MANAGER)
	hex_navigator = p_params.get(GameConstants.ContextKeys.HEX_NAVIGATOR)
	camera_controller = p_params.get(GameConstants.ContextKeys.CAMERA_CONTROLLER)
	move_controller = p_params.get(GameConstants.ContextKeys.MOVE_CONTROLLER)
	turn_controller = p_params.get(GameConstants.ContextKeys.TURN_CONTROLLER)
	task_controller = p_params.get(GameConstants.ContextKeys.TASK_CONTROLLER)
	grid = p_params.get(GameConstants.ContextKeys.GRID)
	grid_visuals = p_params.get(GameConstants.ContextKeys.GRID_VISUALS)
	terrain_map = p_params.get(GameConstants.ContextKeys.TERRAIN_MAP)
	binding_service = p_params.get(GameConstants.ContextKeys.BINDING_SERVICE)
	dialogue_action_service = p_params.get(GameConstants.ContextKeys.DIALOGUE_ACTION_SERVICE)
	loot_manager = p_params.get(GameConstants.ContextKeys.LOOT_MANAGER)
	map_controller = p_params.get(GameConstants.ContextKeys.MAP_CONTROLLER)
	task_manager = p_params.get(GameConstants.ContextKeys.TASK_MANAGER)
	auto_battle_active = p_params.get(GameConstants.ContextKeys.AUTO_BATTLE_ACTIVE, false)

## Validates that all required dependencies are present
func is_valid() -> bool:
	return (unit_manager != null and hex_navigator != null and
			camera_controller != null and move_controller != null and
			turn_controller != null and task_controller != null and grid != null and
			loot_manager != null and map_controller != null and task_manager != null)

## Gets list of missing dependencies for debugging
func get_missing_dependencies() -> PackedStringArray:
	var missing: PackedStringArray = []
	if unit_manager == null:
		missing.append(GameConstants.ContextKeys.UNIT_MANAGER)
	if hex_navigator == null:
		missing.append(GameConstants.ContextKeys.HEX_NAVIGATOR)
	if camera_controller == null:
		missing.append(GameConstants.ContextKeys.CAMERA_CONTROLLER)
	if move_controller == null:
		missing.append(GameConstants.ContextKeys.MOVE_CONTROLLER)
	if turn_controller == null:
		missing.append(GameConstants.ContextKeys.TURN_CONTROLLER)
	if task_controller == null:
		missing.append(GameConstants.ContextKeys.TASK_CONTROLLER)
	if grid == null:
		missing.append(GameConstants.ContextKeys.GRID)
	if loot_manager == null:
		missing.append(GameConstants.ContextKeys.LOOT_MANAGER)
	if task_manager == null:
		missing.append(GameConstants.ContextKeys.TASK_MANAGER)
	if map_controller == null:
		missing.append(GameConstants.ContextKeys.MAP_CONTROLLER)
	return missing

## Get a specific field by name (used by validators)
func get_field(field_name: String):
	match field_name:
		GameConstants.ContextKeys.UNIT_MANAGER: return unit_manager
		GameConstants.ContextKeys.HEX_NAVIGATOR: return hex_navigator
		GameConstants.ContextKeys.CAMERA_CONTROLLER: return camera_controller
		GameConstants.ContextKeys.MOVE_CONTROLLER: return move_controller
		GameConstants.ContextKeys.TURN_CONTROLLER: return turn_controller
		GameConstants.ContextKeys.TASK_CONTROLLER: return task_controller
		GameConstants.ContextKeys.GRID: return grid
		GameConstants.ContextKeys.GRID_VISUALS: return grid_visuals
		GameConstants.ContextKeys.TERRAIN_MAP: return terrain_map
		GameConstants.ContextKeys.BINDING_SERVICE: return binding_service
		GameConstants.ContextKeys.DIALOGUE_ACTION_SERVICE: return dialogue_action_service
		GameConstants.ContextKeys.LOOT_MANAGER: return loot_manager
		GameConstants.ContextKeys.TASK_MANAGER: return task_manager
		GameConstants.ContextKeys.MAP_CONTROLLER: return map_controller
		GameConstants.ContextKeys.AUTO_BATTLE_ACTIVE: return auto_battle_active
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
