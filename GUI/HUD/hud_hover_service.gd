class_name HUDHoverService
extends Node

## Service for managing hover states and mouse interactions in the HUD
## Extracted from HUDController to reduce complexity.

var _controller: HUDController
var _unit_manager: UnitManager
var _grid: TileMapLayer
var _terrain_map: TerrainMap
var _grid_visuals: GridVisuals
var _aim_cursor: AimCursor

var _hover_states: Array[HoverState] = []
var _active_hover_states: Array[HoverState] = []
var _last_mouse_coord: Vector2i = Vector2i.MAX
var _last_pixel_pos: Vector2 = Vector2.INF

func setup(p_controller: HUDController, p_unit_manager: UnitManager, p_grid: TileMapLayer, p_terrain_map: TerrainMap, p_visuals: GridVisuals, p_aim_cursor: AimCursor) -> void:
	_controller = p_controller
	_unit_manager = p_unit_manager
	_grid = p_grid
	_terrain_map = p_terrain_map
	_grid_visuals = p_visuals
	_aim_cursor = p_aim_cursor
	_init_hover_states()

func _init_hover_states() -> void:
	# These classes are assumed to be available via class_name
	_hover_states = [
		CombatPreviewState.new() as HoverState,
		UnitHoverState.new() as HoverState,
		TaskHoverState.new() as HoverState,
		LocationHoverState.new() as HoverState,
		LootHoverState.new() as HoverState,
		TerrainHoverState.new() as HoverState,
		IdleState.new() as HoverState
	]
	_active_hover_states = []

func process_hover(mouse_pos: Vector2, hovered_control: Control) -> void:
	if not is_instance_valid(_grid):
		return

	if is_instance_valid(_aim_cursor):
		mouse_pos = _aim_cursor.get_effective_cursor_position(mouse_pos)

	# Block hover if mouse is over UI
	if hovered_control and hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_clear_all_hover_states()
		if is_instance_valid(_grid_visuals):
			_grid_visuals.update_hover_indicator(Vector2.INF, _grid, _unit_manager, _terrain_map)
		return

	if mouse_pos == _last_pixel_pos:
		return

	_last_pixel_pos = mouse_pos
	var current_coord: Vector2i = _grid.local_to_map(_grid.to_local(mouse_pos))

	if current_coord != _last_mouse_coord:
		_last_mouse_coord = current_coord
		if is_instance_valid(_grid_visuals):
			_grid_visuals.update_hover_indicator(mouse_pos, _grid, _unit_manager, _terrain_map)

			var selected_idx = _unit_manager.get_selected_index()
			var unit = _unit_manager.get_unit(selected_idx)
			var path: Array[Vector2i] = []
			var is_tentative := false

			if is_instance_valid(unit) and unit.movement and unit.movement.has_tentative_move():
				is_tentative = true
				var start_cell: Vector2i = unit.movement.get_start_of_turn_grid_coord()
				if start_cell == Vector2i.MAX or start_cell == GameConstants.INVALID_COORD:
					start_cell = unit.get_grid_location()
				path.append(start_cell)
				for cell: Vector2i in unit.movement.get_tentative_path():
					path.append(cell)
				# If a tentative move exists, allow hover preview to extend from the tentative destination
				# using remaining movement points (useful for planning follow-up movement after confirming).
				var tentative_dest: Vector2i = unit.movement.get_tentative_grid_coord()
				if _terrain_map and _terrain_map.is_within_bounds(tentative_dest) and _terrain_map.is_within_bounds(current_coord) and current_coord != tentative_dest:
					var remaining_budget: int = max(0, unit.movement.get_remaining_movement_points() - unit.movement.get_tentative_cost())
					if remaining_budget > 0:
						var extension: Array[Vector2i] = MovementRangeService.find_path(tentative_dest, current_coord, remaining_budget, _terrain_map, _unit_manager, selected_idx)
						if not extension.is_empty():
							for cell: Vector2i in extension:
								path.append(cell)
			elif is_instance_valid(unit):
				var budget = unit.movement.get_remaining_movement_points()
				path = MovementRangeService.find_path(unit.get_grid_location(), current_coord, budget, _terrain_map, _unit_manager, selected_idx)

			_grid_visuals.update_path_preview(_grid, path, is_tentative)
		update_hover_info(current_coord)

func update_hover_info(cell: Vector2i) -> void:
	if not _are_hover_dependencies_valid():
		_clear_all_hover_states()
		return

	var new_active_states: Array[HoverState] = []
	for state in _hover_states:
		if state.can_enter(_controller, cell):
			new_active_states.append(state)

	# States to exit: currently active but not in new active states
	for state in _active_hover_states:
		if not new_active_states.has(state):
			state.exit(_controller)

	# States to enter or update
	for state in new_active_states:
		if not _active_hover_states.has(state):
			state.enter(_controller, cell)
		else:
			state.update(_controller, cell)

	_active_hover_states = new_active_states

func _are_hover_dependencies_valid() -> bool:
	return is_instance_valid(_unit_manager) and is_instance_valid(_grid)

func _clear_all_hover_states() -> void:
	for state in _active_hover_states:
		state.exit(_controller)
	_active_hover_states.clear()

func force_hover_update(mouse_pos: Vector2) -> void:
	if not is_instance_valid(_grid):
		return
	if is_instance_valid(_aim_cursor):
		mouse_pos = _aim_cursor.get_effective_cursor_position(mouse_pos)
	var current_coord: Vector2i = _grid.local_to_map(_grid.to_local(mouse_pos))
	if is_instance_valid(_grid_visuals):
		_grid_visuals.update_hover_indicator(mouse_pos, _grid, _unit_manager, _terrain_map)

		var selected_idx = _unit_manager.get_selected_index()
		var unit = _unit_manager.get_unit(selected_idx)
		var path: Array[Vector2i] = []
		var is_tentative := false

		if is_instance_valid(unit) and unit.movement and unit.movement.has_tentative_move():
			is_tentative = true
			var start_cell: Vector2i = unit.movement.get_start_of_turn_grid_coord()
			if start_cell == Vector2i.MAX or start_cell == GameConstants.INVALID_COORD:
				start_cell = unit.get_grid_location()
			path.append(start_cell)
			for cell: Vector2i in unit.movement.get_tentative_path():
				path.append(cell)
		elif is_instance_valid(unit):
			var budget = unit.movement.get_remaining_movement_points()
			path = MovementRangeService.find_path(unit.get_grid_location(), current_coord, budget, _terrain_map, _unit_manager, selected_idx)

		_grid_visuals.update_path_preview(_grid, path, is_tentative)
	update_hover_info(current_coord)
