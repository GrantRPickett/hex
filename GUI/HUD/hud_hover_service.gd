class_name HUDHoverService
extends Node

## Service for managing hover states and mouse interactions in the HUD
## Extracted from HUDController to reduce complexity.

var _controller: Node
var _hover_states: Array[HoverState] = []
var _active_hover_states: Array[HoverState] = []
var _last_mouse_coord: Vector2i = Vector2i.MAX
var _last_pixel_pos: Vector2 = Vector2.INF

func setup(controller: Node) -> void:
	_controller = controller
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

func process_hover() -> void:
	if not is_instance_valid(_controller._grid):
		return

	var mouse_pos = _controller.get_global_mouse_position()
	if is_instance_valid(_controller._aim_cursor):
		mouse_pos = _controller._aim_cursor.get_effective_cursor_position(mouse_pos)

	# Block hover if mouse is over UI
	var hovered_control = _controller.get_viewport().gui_get_hovered_control()
	if hovered_control and hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_clear_all_hover_states()
		if is_instance_valid(_controller._grid_visuals):
			_controller._grid_visuals.update_hover_indicator(Vector2.INF, _controller._grid, _controller._unit_manager, _controller._terrain_map)
		return

	if mouse_pos == _last_pixel_pos:
		return

	_last_pixel_pos = mouse_pos
	var grid = _controller._grid
	var current_coord: Vector2i = grid.local_to_map(grid.to_local(mouse_pos))

	if current_coord != _last_mouse_coord:
		_last_mouse_coord = current_coord
		# print_debug("[HUDHoverService] Hovering over cell: ", current_coord)
		if is_instance_valid(_controller._grid_visuals):
			_controller._grid_visuals.update_hover_indicator(mouse_pos, grid, _controller._unit_manager, _controller._terrain_map)
			_controller._grid_visuals.update_path_preview(mouse_pos, grid, _controller._unit_manager, _controller._terrain_map)
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
	return is_instance_valid(_controller._unit_manager) and is_instance_valid(_controller._grid)

func _clear_all_hover_states() -> void:
	for state in _active_hover_states:
		state.exit(_controller)
	_active_hover_states.clear()

func force_hover_update() -> void:
	if not is_instance_valid(_controller._grid):
		if not _controller._logged_warnings.has("force_hover_grid_missing"):
			_controller._logged_warnings["force_hover_grid_missing"] = true
			push_warning("[HUDController] Cannot force hover update; Grid is missing.")
		return
	var mouse_pos = _controller.get_global_mouse_position()
	if is_instance_valid(_controller._aim_cursor):
		mouse_pos = _controller._aim_cursor.get_effective_cursor_position(mouse_pos)
	var current_coord = _controller._grid.local_to_map(_controller._grid.to_local(mouse_pos))
	update_hover_info(current_coord)
