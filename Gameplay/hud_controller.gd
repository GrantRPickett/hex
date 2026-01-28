class_name HUDController
extends Node2D

signal round_updated(current_round: int)
signal turn_updated(is_player_turn: bool)
signal goals_updated(goals_data: Array)
signal unit_details_visibility_changed(visible: bool)
signal unit_details_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager)
signal combat_preview_shown(attacker: Unit, defender: Unit)
signal combat_preview_hidden()
signal goal_details_updated(goal: Goal)
signal loot_details_updated(loot: Loot)
signal actions_updated(unit: Unit, terrain_map, unit_manager: UnitManager)
signal terrain_details_updated(terrain: TerrainTile, distance: String)


var _components: HUDComponentFactory.Components
var _hover_states: Array[HoverState] = []
var _active_hover_states: Array[HoverState] = []

var _turn_system: TurnSystem
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _loot_manager: LootManager
var _grid: Node2D
var _hud: Hud
var _terrain_map: TerrainMap
var _grid_visuals: GridVisuals
var _aim_cursor: AimCursor
var _last_mouse_coord: Vector2i = Vector2i.MAX

class Config:
	var components: HUDComponentFactory.Components
	var turn_system: TurnSystem
	var unit_manager: UnitManager
	var goal_manager: GoalManager
	var loot_manager: LootManager
	var grid: Node2D
	var hud: Hud
	var terrain_map: TerrainMap
	var grid_visuals: GridVisuals
	var aim_cursor: AimCursor

class Builder:
	var _config := Config.new()

	func with_components(value: HUDComponentFactory.Components) -> Builder:
		_config.components = value
		return self

	func with_turn_system(value: TurnSystem) -> Builder:
		_config.turn_system = value
		return self

	func with_unit_manager(value: UnitManager) -> Builder:
		_config.unit_manager = value
		return self

	func with_goal_manager(value: GoalManager) -> Builder:
		_config.goal_manager = value
		return self

	func with_loot_manager(value: LootManager) -> Builder:
		_config.loot_manager = value
		return self

	func with_grid(value: Node2D) -> Builder:
		_config.grid = value
		return self

	func with_hud(value: Hud) -> Builder:
		_config.hud = value
		return self

	func with_terrain_map(value: TerrainMap) -> Builder:
		_config.terrain_map = value
		return self

	func with_grid_visuals(value: GridVisuals) -> Builder:
		_config.grid_visuals = value
		return self

	func with_aim_cursor(value: AimCursor) -> Builder:
		_config.aim_cursor = value
		return self

	func build() -> Config:
		return _config

func _ready() -> void:
	if is_instance_valid(_aim_cursor):
		_aim_cursor.set_initial_position(get_global_mouse_position())

func setup(config: Config) -> void:
	_components = config.components
	_turn_system = config.turn_system
	_unit_manager = config.unit_manager
	_goal_manager = config.goal_manager
	_loot_manager = config.loot_manager
	_grid = config.grid
	_hud = config.hud
	_terrain_map = config.terrain_map
	_grid_visuals = config.grid_visuals
	_aim_cursor = config.aim_cursor
	_connect_components()
	_init_hover_states()

func set_aim_cursor(cursor: AimCursor) -> void:
	_aim_cursor = cursor

func _process(_delta: float) -> void:
	_update_hud()

	if not is_instance_valid(_grid):
		return

	var mouse_pos = get_global_mouse_position()
	if is_instance_valid(_aim_cursor):
		mouse_pos = _aim_cursor.get_effective_cursor_position(mouse_pos)

	var current_coord: Vector2i = _grid.local_to_map(_grid.to_local(mouse_pos))

	if current_coord != _last_mouse_coord:
		_last_mouse_coord = current_coord
		if is_instance_valid(_grid_visuals):
			_grid_visuals.update_hover_indicator(mouse_pos, _grid, _unit_manager, _terrain_map)
			_grid_visuals.update_path_preview(mouse_pos, _grid, _unit_manager, _terrain_map)
		update_hover_info(mouse_pos, current_coord)

func handle_actions_updated(unit: Unit, terrain_map, unit_manager: UnitManager, _unit_index: int = -1) -> void:
	actions_updated.emit(unit, terrain_map, unit_manager)

func _update_hud() -> void:
	_update_round_and_turn()
	_update_goals_progress()

func _init_hover_states() -> void:
	_hover_states = [
		CombatPreviewState.new(),
		UnitHoverState.new(),
		GoalHoverState.new(),
		LootHoverState.new(),
		TerrainHoverState.new(),
		IdleState.new()
	]
	_active_hover_states = []

func _connect_components() -> void:
	if not _components:
		return

	if is_instance_valid(_components.round_info):
		round_updated.connect(_components.round_info.update_round)
		turn_updated.connect(_components.round_info.update_turn)

	if is_instance_valid(_components.goals_list):
		goals_updated.connect(_components.goals_list.update_goals)

	if is_instance_valid(_components.unit_details):
		unit_details_updated.connect(_components.unit_details.update_details)
		unit_details_visibility_changed.connect(_components.unit_details.set_visible)

	if is_instance_valid(_components.combat_preview):
		combat_preview_shown.connect(_components.combat_preview.show_preview)
		combat_preview_hidden.connect(_components.combat_preview.hide_preview)

	if is_instance_valid(_components.goal_details):
		goal_details_updated.connect(_components.goal_details.update_details)

	if is_instance_valid(_components.loot_details):
		loot_details_updated.connect(_components.loot_details.update_details)


	if is_instance_valid(_components.actions_panel):
		actions_updated.connect(_components.actions_panel.update_actions)
		_components.actions_panel.action_selected.connect(_hud.on_action_selected)

	if is_instance_valid(_components.terrain_details):
		terrain_details_updated.connect(_components.terrain_details.update_details)

	if is_instance_valid(_unit_manager):
		_unit_manager.selection_changed.connect(_on_unit_manager_selection_changed)

func _update_round_and_turn() -> void:
	if is_instance_valid(_turn_system):
		round_updated.emit(_turn_system.get_current_round())
		turn_updated.emit(_turn_system.get_current_side() == TurnSystem.Side.PLAYER)

func _update_goals_progress() -> void:
	if is_instance_valid(_goal_manager):
		var goals_data = []
		for i in range(_goal_manager.get_goal_count()):
			goals_data.append({
				"player_progress": _goal_manager.get_progress(i, Unit.Faction.PLAYER),
				"enemy_progress": _goal_manager.get_progress(i, Unit.Faction.ENEMY),
				"max": _goal_manager.get_required_amount(i),
				"type": _goal_manager.get_required_type(i)
			})
		goals_updated.emit(goals_data)

func _on_unit_manager_selection_changed(index: int) -> void:
	if index != -1:
		var sprite = _unit_manager.get_unit(index)
		if sprite is Unit:
			unit_details_updated.emit(sprite, _terrain_map, _unit_manager)
		else:
			unit_details_updated.emit(null, _terrain_map, _unit_manager)
	else: # No unit selected
		unit_details_updated.emit(null, _terrain_map, _unit_manager)
func update_hover_info(_mouse_pos: Vector2, cell: Vector2i) -> void:
	if not _are_hover_dependencies_valid():
		_clear_all_hover_states()
		return

	var new_active_states: Array[HoverState] = []
	for state in _hover_states:
		if state.can_enter(self, cell):
			new_active_states.append(state)

	# States to exit: currently active but not in new active states
	for state in _active_hover_states:
		if not new_active_states.has(state):
			state.exit(self)

	# States to enter or update
	for state in new_active_states:
		if not _active_hover_states.has(state):
			state.enter(self, cell)
		else:
			state.update(self, cell)

	_active_hover_states = new_active_states

func _are_hover_dependencies_valid() -> bool:
	return is_instance_valid(_unit_manager) and is_instance_valid(_grid)

func _clear_all_hover_states() -> void:
	for state in _active_hover_states:
		state.exit(self)
	_active_hover_states.clear()

func _get_mouse_grid_cell() -> Vector2i:
	var mouse_pos = get_global_mouse_position()
	return _grid.local_to_map(_grid.to_local(mouse_pos))

func _calculate_distance_string(cell: Vector2i) -> String:
	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx != -1:
		var unit = _unit_manager.get_unit(selected_idx)
		if unit is Unit and is_instance_valid(_grid):
			var unit_coord = unit.get_grid_location()
			var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
			if _grid.tile_set:
				axis = _grid.tile_set.tile_offset_axis
			return str(HexNavigator.get_hex_distance(unit_coord, cell, axis))
	return ""

class HoverState:
	func can_enter(_controller: HUDController, _cell: Vector2i) -> bool:
		return false

	func enter(controller: HUDController, cell: Vector2i) -> void:
		update(controller, cell)

	func update(_controller: HUDController, _cell: Vector2i) -> void:
		pass

	func exit(_controller: HUDController) -> void:
		pass

class CombatPreviewState extends HoverState:
	func can_enter(controller: HUDController, cell: Vector2i) -> bool:
		if not controller._components or not is_instance_valid(controller._components.combat_preview):
			return false
		var selected_idx = controller._unit_manager.get_selected_index()
		if selected_idx == -1:
			return false
		var attacker = controller._unit_manager.get_unit(selected_idx)
		if not (attacker is Unit) or not controller._unit_manager.is_player_controlled(selected_idx):
			return false
		var target_idx = controller._unit_manager.index_of_unit_at(cell)
		if target_idx == -1 or target_idx == selected_idx:
			return false
		var defender = controller._unit_manager.get_unit(target_idx)
		if not (defender is Unit) or defender.faction == attacker.faction:
			return false
		return true

	func update(controller: HUDController, cell: Vector2i) -> void:
		var selected_idx = controller._unit_manager.get_selected_index()
		var attacker = controller._unit_manager.get_unit(selected_idx)
		var target_idx = controller._unit_manager.index_of_unit_at(cell)
		var defender = controller._unit_manager.get_unit(target_idx)
		controller.combat_preview_shown.emit(attacker, defender)

	func exit(controller: HUDController) -> void:
		controller.combat_preview_hidden.emit()

class UnitHoverState extends HoverState:
	func can_enter(controller: HUDController, cell: Vector2i) -> bool:
		if not controller._components or not is_instance_valid(controller._components.unit_details):
			return false
		var idx = controller._unit_manager.index_of_unit_at(cell)
		if idx == -1: return false
		return controller._unit_manager.get_unit(idx) is Unit

	func update(controller: HUDController, cell: Vector2i) -> void:
		var hovered_unit_idx = controller._unit_manager.index_of_unit_at(cell)
		if hovered_unit_idx != -1:
			var hovered_unit = controller._unit_manager.get_unit(hovered_unit_idx)
			if hovered_unit is Unit:
				controller.unit_details_updated.emit(hovered_unit, controller._terrain_map, controller._unit_manager)
	func exit(controller: HUDController) -> void:
		controller.unit_details_updated.emit(null, null, null)

class GoalHoverState extends HoverState:
	func can_enter(controller: HUDController, cell: Vector2i) -> bool:
		if not controller._components or not is_instance_valid(controller._components.goal_details):
			return false
		if not is_instance_valid(controller._goal_manager):
			return false
		return controller._goal_manager.get_goal_at_cell(cell) != null

	func update(controller: HUDController, cell: Vector2i) -> void:
		var hovered_goal = controller._goal_manager.get_goal_at_cell(cell)
		controller.goal_details_updated.emit(hovered_goal)

	func exit(controller: HUDController) -> void:
		controller.goal_details_updated.emit(null)

class TerrainHoverState extends HoverState:
	func can_enter(controller: HUDController, cell: Vector2i) -> bool:
		if not controller._components or not is_instance_valid(controller._components.terrain_details):
			return false
		if not controller._terrain_map:
			return false
		var terrain = controller._terrain_map.get_terrain(cell)
		return terrain and not (terrain is TerrainTile.NullTerrain)

	func update(controller: HUDController, cell: Vector2i) -> void:
		var terrain = controller._terrain_map.get_terrain(cell)
		var dist_str = controller._calculate_distance_string(cell)
		controller.terrain_details_updated.emit(terrain, dist_str)

	func exit(controller: HUDController) -> void:
		controller.terrain_details_updated.emit(null, "")

class LootHoverState extends HoverState:
	func can_enter(controller: HUDController, cell: Vector2i) -> bool:
		if not controller._components or not is_instance_valid(controller._components.loot_details):
			return false
		if not is_instance_valid(controller._loot_manager):
			return false
		return controller._loot_manager.has_loot_at(cell)

	func update(controller: HUDController, cell: Vector2i) -> void:
		var hovered_loot = controller._loot_manager.get_loot_at(cell)
		controller.loot_details_updated.emit(hovered_loot)

	func exit(controller: HUDController) -> void:
		controller.loot_details_updated.emit(null)

class IdleState extends HoverState:
	func can_enter(_controller: HUDController, _cell: Vector2i) -> bool:
		return true
