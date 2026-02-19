class_name HUDController
extends Node2D

signal round_updated(current_round: int)
signal turn_updated(is_player_turn: bool)
signal locations_updated(locations_data: Array)
signal unit_details_visibility_changed(visible: bool)
signal unit_details_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager)
signal combat_preview_shown(attacker: Unit, defender: Unit)
signal combat_preview_hidden()
signal location_details_updated(location_data)
signal tasks_updated(tasks_data: Array)
signal task_details_updated(task_data)
signal loot_details_updated(loot: Loot)
signal actions_updated(unit: Unit, terrain_map, unit_manager: UnitManager)
signal terrain_details_updated(terrain: TerrainTile, distance: String)
signal auto_battle_toggle_requested(enabled: bool)

const HoverStateResource := preload("HUD/HoverStates/hover_state.gd")
const CombatPreviewStateResource := preload("HUD/HoverStates/combat_preview_state.gd")
const UnitHoverStateResource := preload("HUD/HoverStates/unit_hover_state.gd")
const LocationHoverStateResource := preload("res://Gameplay/HUD/HoverStates/location_hover_state.gd")
const LootHoverStateResource := preload("HUD/HoverStates/loot_hover_state.gd")
const TerrainHoverStateResource := preload("HUD/HoverStates/terrain_hover_state.gd")
const IdleStateResource := preload("HUD/HoverStates/idle_state.gd")


var _components: HUDComponentFactory.Components
var _hover_states: Array[HoverState] = []
var _active_hover_states: Array[HoverState] = []
var _is_safe_zone_mode := false

var _turn_system: TurnSystem
var _unit_manager: UnitManager
var _task_manager: TaskManager
var _loot_manager: LootManager
var _combat_system: CombatSystem
var _pause_handler: PauseHandler
var _grid: Node2D
var _hud: Hud
var _terrain_map: TerrainMap
var _grid_visuals: GridVisuals
var _aim_cursor: AimCursor
var _last_mouse_coord: Vector2i = Vector2i.MAX
var _auto_battle_button: Button
var _auto_battle_button_sync := false
var _logged_warnings: Dictionary = {}
var _animation_service
var _location_service: LocationService
var _task_controller: TaskController

class Config:
	var components: HUDComponentFactory.Components
	var turn_system: TurnSystem
	var unit_manager: UnitManager
	var task_manager: TaskManager
	var loot_manager: LootManager
	var combat_system: CombatSystem
	var pause_handler: PauseHandler
	var grid: Node2D
	var hud: Hud
	var terrain_map: TerrainMap
	var grid_visuals: GridVisuals
	var aim_cursor: AimCursor
	var animation_service
	var locations_list_panel: LocationsListPanel
	var location_details_panel: LocationDetailsPanel
	var tasks_list_panel: TasksListPanel
	var task_details_panel: TaskDetailsPanel
	var location_service: LocationService
	var task_controller: TaskController

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

	func with_task_manager(value: TaskManager) -> Builder:
		_config.task_manager = value
		return self

	func with_combat_system(value: CombatSystem) -> Builder:
		_config.combat_system = value
		return self

	func with_pause_handler(value: PauseHandler) -> Builder:
		_config.pause_handler = value
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

	func with_animation_service(value) -> Builder:
		_config.animation_service = value
		return self

	func with_locations_list_panel(value: LocationsListPanel) -> Builder:
		_config.locations_list_panel = value
		return self

	func with_location_details_panel(value: LocationDetailsPanel) -> Builder:
		_config.location_details_panel = value
		return self

	func with_tasks_list_panel(value: TasksListPanel) -> Builder:
		_config.tasks_list_panel = value
		return self

	func with_task_details_panel(value: TaskDetailsPanel) -> Builder:
		_config.task_details_panel = value
		return self

	func with_task_controller(value: TaskController) -> Builder:
		_config.task_controller = value
		return self

	func with_location_service(value: LocationService) -> Builder:
		_config.location_service = value
		return self

	func build() -> Config:
		return _config

func _ready() -> void:
	if is_instance_valid(_aim_cursor):
		_aim_cursor.set_initial_position(get_global_mouse_position())

func setup(config: Config) -> void:
	_components = config.components
	_components.locations_list = config.locations_list_panel
	_components.location_details = config.location_details_panel
	_components.tasks_list = config.tasks_list_panel
	_components.task_details = config.task_details_panel
	_turn_system = config.turn_system
	_unit_manager = config.unit_manager
	_task_manager = config.task_manager
	_loot_manager = config.loot_manager
	_connect_task_manager_signals()
	_combat_system = config.combat_system
	_pause_handler = config.pause_handler
	_grid = config.grid
	_hud = config.hud
	_terrain_map = config.terrain_map
	_grid_visuals = config.grid_visuals
	_aim_cursor = config.aim_cursor
	_animation_service = config.animation_service
	_location_service = config.location_service
	_task_controller = config.task_controller
	_connect_components()
	_init_hover_states()
	_apply_safe_zone_visibility()
	set_auto_battle_state(false)

func set_aim_cursor(cursor: AimCursor) -> void:
	_aim_cursor = cursor

func set_safe_zone_mode(is_safe_zone: bool) -> void:
	_is_safe_zone_mode = is_safe_zone
	_apply_safe_zone_visibility()

func set_auto_battle_state(enabled: bool) -> void:
	if is_instance_valid(_auto_battle_button):
		_auto_battle_button_sync = true
		_auto_battle_button.button_pressed = enabled
		_auto_battle_button.text = "Auto Act (On)" if enabled else "Auto Act"
		_auto_battle_button_sync = false
	if _components and is_instance_valid(_components.actions_panel) and _components.actions_panel.has_method("set_auto_battle_mode"):
		_components.actions_panel.set_auto_battle_mode(enabled)

func _process(_delta: float) -> void:
	_update_hud()

	if not is_instance_valid(_grid):
		if not _logged_warnings.has("grid_missing"):
			_logged_warnings["grid_missing"] = true
			push_warning("[HUDController] Skipping hover update because Grid is missing.")
		return
	_logged_warnings.erase("grid_missing")

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
	_force_hover_update()


func handle_dialogue_finished(_flag_id: StringName) -> void:
	var unit = _unit_manager.get_selected_unit() if is_instance_valid(_unit_manager) else null
	actions_updated.emit(unit, _terrain_map, _unit_manager)


func _force_hover_update() -> void:
	if not is_instance_valid(_grid):
		if not _logged_warnings.has("force_hover_grid_missing"):
			_logged_warnings["force_hover_grid_missing"] = true
			push_warning("[HUDController] Cannot force hover update; Grid is missing.")
		return
	var mouse_pos = get_global_mouse_position()
	# Recalculate cell even if mouse didn't move
	var current_coord: Vector2i = _grid.local_to_map(_grid.to_local(mouse_pos))
	update_hover_info(mouse_pos, current_coord)

func _update_hud() -> void:
	_update_round_and_turn()
	_update_task_progress()
	_update_objective_from_manager()

func refresh_after_state_restore() -> void:
	_update_round_and_turn()
	_update_task_progress()
	_update_objective_from_manager()
	var selected_idx := _unit_manager.get_selected_index() if is_instance_valid(_unit_manager) else -1
	_on_unit_manager_selection_changed(selected_idx)

func _init_hover_states() -> void:
	_hover_states = [
		CombatPreviewStateResource.new() as HoverState,
		UnitHoverStateResource.new() as HoverState,
		LocationHoverStateResource.new() as HoverState,
		LootHoverStateResource.new() as HoverState,
		TerrainHoverStateResource.new() as HoverState,
		IdleStateResource.new() as HoverState
	]
	_active_hover_states = []


func set_ui_navigation_mode(enabled: bool) -> void:
	if not _components:
		if not _logged_warnings.has("ui_nav_components_missing"):
			_logged_warnings["ui_nav_components_missing"] = true
			push_warning("[HUDController] UI navigation mode ignored; HUD components not configured.")
		return
	_logged_warnings.erase("ui_nav_components_missing")
	var panel = _components.actions_panel
	if not is_instance_valid(panel):
		if not _logged_warnings.has("ui_nav_panel_missing"):
			_logged_warnings["ui_nav_panel_missing"] = true
			push_warning("[HUDController] UI navigation mode ignored; actions panel is missing.")
		return
	_logged_warnings.erase("ui_nav_panel_missing")
	if enabled and panel.has_method("enable_navigation_mode"):
		panel.enable_navigation_mode()
	elif not enabled and panel.has_method("disable_navigation_mode"):
		panel.disable_navigation_mode()

func _connect_task_manager_signals() -> void:
	if not is_instance_valid(_task_manager):
		if not _logged_warnings.has("task_manager_missing"):
			_logged_warnings["task_manager_missing"] = true
			push_warning("[HUDController] task manager unavailable; task signals not connected.")
		return
	_logged_warnings.erase("task_manager_missing")
	if not _task_manager.objective_updated.is_connected(_on_objective_updated):
		_task_manager.objective_updated.connect(_on_objective_updated)
	if not _task_manager.objective_completed.is_connected(_on_objective_completed):
		_task_manager.objective_completed.connect(_on_objective_completed)

func _connect_components() -> void:
	if not _components:
		if not _logged_warnings.has("components_missing"):
			_logged_warnings["components_missing"] = true
			push_warning("[HUDController] Cannot connect HUD components; config missing.")
		return
	_logged_warnings.erase("components_missing")

	_connect_info_panels()
	_connect_interaction_panels()
	_connect_action_panel()
	_connect_system_controls()

	_apply_safe_zone_visibility()


func _connect_info_panels() -> void:
	if is_instance_valid(_components.round_info):
		round_updated.connect(_components.round_info.update_round)
		turn_updated.connect(_components.round_info.update_turn)

	if is_instance_valid(_components.locations_list):
		locations_updated.connect(_components.locations_list.update_locations)

	if is_instance_valid(_components.terrain_details):
		terrain_details_updated.connect(_components.terrain_details.update_details)

	if is_instance_valid(_components.tasks_list):
		tasks_updated.connect(_components.tasks_list.update_tasks)


func _connect_interaction_panels() -> void:
	if is_instance_valid(_components.unit_details):
		unit_details_updated.connect(_components.unit_details.update_details)
		unit_details_visibility_changed.connect(_components.unit_details.set_visible)

	if is_instance_valid(_components.combat_preview):
		combat_preview_shown.connect(_components.combat_preview.show_preview)
		combat_preview_hidden.connect(_components.combat_preview.hide_preview)

	if is_instance_valid(_components.location_details):
		location_details_updated.connect(_components.location_details.update_details)

	if is_instance_valid(_components.task_details):
		task_details_updated.connect(_components.task_details.update_details)

	if is_instance_valid(_components.loot_details):
		loot_details_updated.connect(_components.loot_details.update_details)


func _connect_action_panel() -> void:
	if is_instance_valid(_components.actions_panel):
		print_debug("HUDController - Connecting actions_panel signals")
		actions_updated.connect(_components.actions_panel.update_actions)
		_components.actions_panel.action_selected.connect(_hud.on_action_selected)
		_components.actions_panel.attribute_hovered.connect(_on_attribute_hovered)
	else:
		print_debug("HUDController - WARNING: actions_panel is NOT valid!")


func _connect_system_controls() -> void:
	if is_instance_valid(_components.auto_battle_button):
		_auto_battle_button = _components.auto_battle_button
		_auto_battle_button.toggled.connect(func(pressed: bool):
			if not _auto_battle_button_sync:
				auto_battle_toggle_requested.emit(pressed)
		)

	if is_instance_valid(_components.pause_button):
		_components.pause_button.pressed.connect(func():
			_hud.menu_requested.emit("pause", {})
		)

	if is_instance_valid(_hud):
		_hud.menu_requested.connect(_on_menu_requested)
		if not _hud.action_executed.is_connected(_on_hud_action_executed):
			_hud.action_executed.connect(_on_hud_action_executed)

	if is_instance_valid(_unit_manager):
		_unit_manager.selection_changed.connect(_on_unit_manager_selection_changed)

func _apply_safe_zone_visibility() -> void:
	if not _components:
		if not _logged_warnings.has("safe_zone_components_missing"):
			_logged_warnings["safe_zone_components_missing"] = true
			push_warning("[HUDController] Safe zone visibility update skipped; components unavailable.")
		return
	_logged_warnings.erase("safe_zone_components_missing")
	var combat_visible := not _is_safe_zone_mode
	# Keep primary action panel available even in safe zones so players can access utility actions.
	_set_panel_visible(_components.actions_panel, true)
	_set_panel_visible(_components.combat_preview, combat_visible)
	_set_panel_visible(_components.morale_panel, combat_visible)

func _set_panel_visible(panel: Node, p_visible: bool) -> void:
	if not is_instance_valid(panel):
		return
	panel.visible = p_visible

func _update_round_and_turn() -> void:
	if is_instance_valid(_turn_system):
		round_updated.emit(_turn_system.get_current_round())
		turn_updated.emit(_turn_system.get_current_side() == TurnSystem.Side.PLAYER)

func _on_objective_updated(objective: Objective) -> void:
	_update_objective_display(objective)

func _on_objective_completed(objective: Objective) -> void:
	_update_objective_display(objective)

func _update_objective_from_manager() -> void:
	if is_instance_valid(_task_manager):
		_update_objective_display(_task_manager.get_active_objective())

func _update_objective_display(objective: Objective) -> void:
	var tasks_data: Array = []
	if objective and objective.is_active and objective.current_stage:
		var stage = objective.current_stage
		var completed_count = 0

		for task in stage.active_tasks:
			var status_str = Task.Status.keys()[task.status] if task.status >= 0 else "UNKNOWN"
			tasks_data.append({
				"title": task.title,
				"description": task.description if task is Task else "N/A",
				"current": task.current_effort,
				"required": task.effort_required,
				"completed": task.status == Task.Status.COMPLETED,
				"icon": task.icon,
				"stage_id": stage.id,
				"status": status_str
			})
			if task.status == Task.Status.COMPLETED:
				completed_count += 1

		# Log stage status update
		print_debug("[HUD] Stage display updated: '%s' | %d/%d tasks complete" %
			[stage.id, completed_count, stage.active_tasks.size()])

	tasks_updated.emit(tasks_data)

func _update_task_progress() -> void:
	if is_instance_valid(_location_service):
		var locations_data = _location_service.get_all_locations_data()
		locations_updated.emit(locations_data)
	else:
		if not _logged_warnings.has("location_service_missing_update"):
			_logged_warnings["location_service_missing_update"] = true
			push_warning("[HUDController] Cannot update locations; location service is missing.")

func _on_unit_manager_selection_changed(index: int) -> void:
	var unit: Unit = _unit_manager.get_unit(index) if is_instance_valid(_unit_manager) and index != -1 else null
	unit_details_updated.emit(unit, _terrain_map, _unit_manager)
	actions_updated.emit(unit, _terrain_map, _unit_manager)

func update_hover_info(_mouse_pos: Vector2, cell: Vector2i) -> void:
	if not _are_hover_dependencies_valid():
		if not _logged_warnings.has("hover_dependency_missing"):
			_logged_warnings["hover_dependency_missing"] = true
			push_warning("[HUDController] Hover updates disabled; missing unit manager or grid.")
		_clear_all_hover_states()
		return
	_logged_warnings.erase("hover_dependency_missing")

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

var _pending_combat_target: Unit

func _on_menu_requested(type: String, data: Dictionary) -> void:
	print_debug("HUDController: Received menu_requested, type=", type)
	if type == "pause":
		if is_instance_valid(_pause_handler) and _pause_handler.has_method("show_pause_menu"):
			_pause_handler.show_pause_menu()
		return

	if type == "attack_menu":
		var target = data.get("target")
		var selected_idx = _unit_manager.get_selected_index()
		var targets = data.get("targets", [])
		var reachable_targets = data.get("reachable_targets", [])
		print_debug("HUDController: target=", target, " selected_idx=", selected_idx, " panel_valid=", is_instance_valid(_components.actions_panel))
		if target and selected_idx != -1 and is_instance_valid(_components.actions_panel):
			var attacker = _unit_manager.get_unit(selected_idx)
			print_debug("HUDController: Calling show_attack_menu with attacker=", attacker.unit_name if attacker else "null")
			_pending_combat_target = target
			_components.actions_panel.show_attack_menu(attacker, target, targets, reachable_targets)
		else:
			print_debug("HUDController: Skipping show_attack_menu - conditions not met")

func update_compass(p_rotation: float) -> void:
	if _components and _components.weather_panel:
		_components.weather_panel.update_compass(p_rotation)

func show_feedback(text: String) -> void:
	FeedbackDisplay.new().show_feedback(text, _hud, _animation_service)

func _on_hud_action_executed(action_type: String) -> void:
	if action_type == "open_attack_menu":
		return
	_pending_combat_target = null
	var unit = _unit_manager.get_selected_unit() if is_instance_valid(_unit_manager) else null
	actions_updated.emit(unit, _terrain_map, _unit_manager)

func _on_attribute_hovered(idx: int) -> void:
	if idx == -1:
		if is_instance_valid(_components.combat_preview):
			_components.combat_preview.hide_preview()
		return

	var target: Unit = _pending_combat_target
	if _components and is_instance_valid(_components.actions_panel):
		var panel_target = null
		if _components.actions_panel.has_method("get_current_attack_target"):
			panel_target = _components.actions_panel.get_current_attack_target()
		if panel_target:
			target = panel_target
			_pending_combat_target = panel_target

	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx == -1 or not target or _combat_system == null or not is_instance_valid(_components.combat_preview):
		return

	var attacker = _unit_manager.get_unit(selected_idx)
	# Assuming attribute index maps to pair index?
	# CombatSystem pairs: 0:[0,1], 1:[2,3], 2:[4,5] (indices into attributes)
	# OR CombatSystem input is PAIR INDEX.
	# UnitAttributes: Grit(0), Flow(1), Gusto(2), Focus(3), Shine(4), Shade(5).
	# Pair 0 uses indices 0,1. Pair 1 uses 2,3.
	# So if I click Grit(0) -> Pair 0. Flow(1) -> Pair 0.
	# Pair index = idx / 2.
	var pair_idx: int = idx / 2
	var forecast = _combat_system.get_combat_forecast(attacker, target, pair_idx)
	_components.combat_preview.show_forecast(attacker, target, forecast)


func calculate_distance_to_cell(cell: Vector2i) -> String:
	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx != -1:
		var unit = _unit_manager.get_unit(selected_idx)
		if unit is Unit and is_instance_valid(_grid):
			var unit_coord = unit.get_grid_location()
			var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
			if _grid is TileMapLayer and _grid.tile_set:
				axis = _grid.tile_set.tile_offset_axis
			elif _grid.has_method("get_tile_set") and _grid.get_tile_set():
				axis = _grid.get_tile_set().tile_offset_axis
			return str(HexNavigator.get_hex_distance(unit_coord, cell, axis))
	return ""
