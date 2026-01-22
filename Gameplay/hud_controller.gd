class_name HUDController
extends Node2D

var _hud: Info
var _turn_system: TurnSystem
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _grid: Node2D
var _terrain_map: TerrainMap

func setup(hud: Info, turn_system: TurnSystem, unit_manager: UnitManager, goal_manager: GoalManager, grid: Node2D, terrain_map: TerrainMap = null) -> void:
	_hud = hud
	_turn_system = turn_system
	_unit_manager = unit_manager
	_goal_manager = goal_manager
	_grid = grid
	_terrain_map = terrain_map

func _process(_delta: float) -> void:
	_update_hud()
	_update_hover_info()

func _update_hud() -> void:
	if not is_instance_valid(_hud):
		return

	if is_instance_valid(_turn_system):
		_hud.update_round(_turn_system.get_current_round())
		_hud.update_turn(_turn_system.get_current_side() == TurnSystem.Side.PLAYER)

	if is_instance_valid(_goal_manager) and _hud.has_method("update_goals"):
		var goals_data = []
		for i in range(_goal_manager.get_goal_count()):
			goals_data.append({
				"player_progress": _goal_manager.get_progress(i, Unit.Faction.PLAYER),
				"enemy_progress": _goal_manager.get_progress(i, Unit.Faction.ENEMY),
				"max": _goal_manager.get_required_amount(i),
				"type": _goal_manager.get_required_type(i)
			})
		_hud.update_goals(goals_data)

	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx != -1:
		var sprite = _unit_manager.get_unit(selected_idx)
		if sprite is Unit:
			_hud.update_unit_details(sprite)
		else:
			_hud.update_unit_details(null)

func _update_hover_info() -> void:
	if not is_instance_valid(_hud) or not is_instance_valid(_unit_manager) or not is_instance_valid(_grid):
		return

	var mouse_pos = get_global_mouse_position()

	var cell = _grid.local_to_map(_grid.to_local(mouse_pos))

	var displayed_hover_info = false

	# --- Combat Preview Logic ---

	if _attempt_combat_preview(cell):
		displayed_hover_info = true
	else:
		_hud.hide_combat_preview()

	if displayed_hover_info:
		# If combat preview is active, it takes precedence. Hide other hover info.
		_hud.update_unit_details(null)

		if _hud.has_method("update_goal_details"):
			_hud.update_goal_details(null)

		return

	# --- Unit Hover Logic ---

	var hovered_unit_idx = _unit_manager.index_of_unit_at(cell)

	if hovered_unit_idx != -1:
		var hovered_unit = _unit_manager.get_unit(hovered_unit_idx)

		if hovered_unit is Unit:
			_hud.update_unit_details(hovered_unit)

			displayed_hover_info = true

		else:
			_hud.update_unit_details(null)

	else:
		_hud.update_unit_details(null)

	if displayed_hover_info:
		# If unit details are active (from hover), it takes precedence over goal hover.
		if _hud.has_method("update_goal_details"):
			_hud.update_goal_details(null)

		return

	# --- Goal Hover Logic ---

	var hovered_goal: Goal = null
	if is_instance_valid(_goal_manager):
		hovered_goal = _goal_manager.get_goal_at_cell(cell)

	if _hud.has_method("update_goal_details"): # Check if the method exists in Info.gd
		if hovered_goal:
			_hud.update_goal_details(hovered_goal)

			displayed_hover_info = true

		else:
			_hud.update_goal_details(null)

	if not displayed_hover_info:
		# If nothing else was hovered (unit/goal), show terrain info
		if _hud.has_method("update_terrain_details"):
			var terrain: TerrainTile = null
			if _terrain_map:
				terrain = _terrain_map.get_terrain(cell)

			if terrain and not (terrain is TerrainTile.NullTerrain):
				var dist_str = ""
				var selected_idx = _unit_manager.get_selected_index()
				if selected_idx != -1:
					var unit = _unit_manager.get_unit(selected_idx)
					if unit is Unit and is_instance_valid(_grid):
						var unit_coord = unit.get_grid_location()
						var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
						if _grid.tile_set:
							axis = _grid.tile_set.tile_offset_axis

						var hex_dist = HexNavigator.get_hex_distance(unit_coord, cell, axis)
						dist_str = str(hex_dist)

				_hud.update_terrain_details(terrain, dist_str)
				displayed_hover_info = true
			else:
				_hud.update_terrain_details(null)

	if not displayed_hover_info:
		# If nothing was hovered, ensure all hover panels are hidden
		_hud.update_unit_details(null)
		if _hud.has_method("update_goal_details"):
			_hud.update_goal_details(null)

func _attempt_combat_preview(cell: Vector2i) -> bool:
	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx == -1:
		return false

	var attacker = _unit_manager.get_unit(selected_idx)
	if not (attacker is Unit) or not _unit_manager.is_player_controlled(selected_idx):
		return false

	var target_idx = _unit_manager.index_of_unit_at(cell)
	if target_idx == -1 or target_idx == selected_idx:
		return false

	var defender = _unit_manager.get_unit(target_idx)
	if not (defender is Unit) or defender.faction == attacker.faction:
		return false

	_hud.show_combat_preview(attacker, defender)
	return true
