class_name HUDController
extends Node2D

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)
const CombatFeedbackServiceScript := preload("res://Gameplay/combat_feedback_service.gd")

signal round_updated(current_round: int)
signal turn_updated(side: int)
signal turn_system_enabled_updated(enabled: bool)
signal locations_updated(locations_data: Array)
signal unit_details_visibility_changed(visible: bool)
signal location_details_visibility_changed(visible: bool)
signal task_details_visibility_changed(visible: bool)
signal unit_details_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager)
signal combat_preview_shown(attacker: Target, defender: Target)
signal combat_preview_hidden()
signal location_details_updated(location_data)
signal tasks_updated(tasks_data: Array)
signal task_details_updated(task_data)
signal loot_details_updated(loot: Loot)
signal actions_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, combat_system: CombatSystem, turn_enabled: bool)
signal terrain_details_updated(terrain: TerrainTile, distance: String)
signal auto_battle_toggle_requested(enabled: bool)
signal turn_status_updated(counts: Dictionary)


func emit_unit_details_visibility_changed(p_visible: bool) -> void:
	unit_details_visibility_changed.emit(p_visible)

func emit_combat_preview_shown(attacker: Target, defender: Target) -> void:
	combat_preview_shown.emit(attacker, defender)

func emit_combat_preview_hidden() -> void:
	combat_preview_hidden.emit()

func emit_location_details_updated(location_data) -> void:
	location_details_updated.emit(location_data)
	if _current_is_portrait and _components and is_instance_valid(_components.location_details):
		_components.location_details.visible = (location_data != null)
		if is_instance_valid(_components.locations_list):
			_components.locations_list.visible = (location_data == null)

func emit_task_details_updated(task_data) -> void:
	task_details_updated.emit(task_data)
	if _current_is_portrait and _components and is_instance_valid(_components.task_details):
		_components.task_details.visible = (task_data != null)
		if is_instance_valid(_components.tasks_list):
			_components.tasks_list.visible = (task_data == null)

func emit_loot_details_updated(loot: Loot) -> void:
	loot_details_updated.emit(loot)

func emit_terrain_details_updated(terrain: TerrainTile, distance: String) -> void:
	terrain_details_updated.emit(terrain, distance)

func emit_auto_battle_toggle_requested(enabled: bool) -> void:
	auto_battle_toggle_requested.emit(enabled)

var _components: HUDComponentFactory.Components
var _grid_visuals: GridVisuals
var _hover_service: HUDHoverService
var _is_safe_zone_mode := false

var _turn_system: TurnSystem
var _turn_controller: TurnController
var _unit_manager: UnitManager
var _task_manager: TaskManager
var _loot_manager: LootManager
var _combat_system: CombatSystem
var _pause_handler: PauseHandler
var _grid: Node2D
var _hud: Hud
var _terrain_map: TerrainMap
var _aim_cursor: AimCursor
var _auto_battle_button: Button
var _auto_battle_button_sync := false
var _logged_warnings: Dictionary = {}
var _animation_service # Type: AnimationService (Dynamic)
var _location_service: LocationService
var _task_controller: TaskController
var _signal_connector: HUDSignalConnector
var _map_controller: MapController
var _state: GameState
var _config: GameSessionBuilder.Config
var _current_is_portrait := false
var _loyalty_refresh_callable: Callable = Callable()

func _ready() -> void:
	if is_instance_valid(_aim_cursor):
		_aim_cursor.set_initial_position(get_global_mouse_position())

func setup(state: GameState, components: HUDComponentFactory.Components, config: GameSessionBuilder.Config) -> void:
	_components = components
	_turn_system = state.turn_controller.get_turn_system()
	_turn_controller = state.turn_controller
	_unit_manager = state.unit_manager
	_task_manager = state.task_manager
	_loot_manager = state.loot_manager
	_combat_system = state.combat_system
	_pause_handler = config.pause_handler
	_grid = config.grid
	_hud = state.hud
	_map_controller = state.map_controller
	_terrain_map = state.terrain_map
	_state = state
	_terrain_map = state.terrain_map
	_grid_visuals = state.grid_visuals
	_animation_service = state.animation_service
	_location_service = state.location_service
	_task_controller = state.task_controller
	_auto_battle_button = components.auto_battle_button

	_components.setup(state, config)

	_signal_connector = load("res://GUI/HUD/hud_signal_connector.gd").new()
	_signal_connector.setup(self , state, components)
	_signal_connector.connect_all()

	_setup_hover_service()
	_apply_safe_zone_visibility()
	set_auto_battle_state(false)

	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)

	_state = state
	_config = config

	_update_layout()

	if is_instance_valid(_components.margin_container) and _components.margin_container.name == "PortraitHUD":
		_connect_portrait_tabs()
		_on_portrait_tab_pressed("locations")

	LocaleService.locale_changed.connect(_on_locale_changed)

	if EventBus:
		if not EventBus.unit_damaged.is_connected(_on_unit_damaged):
			EventBus.unit_damaged.connect(_on_unit_damaged)
		if _loyalty_refresh_callable.is_null():
			_loyalty_refresh_callable = func(_unit: Node, _new_loyalty: int) -> void:
				if is_instance_valid(_grid_visuals):
					_grid_visuals.refresh_visuals(_unit_manager, _terrain_map, _grid)
		if not EventBus.unit_loyalty_changed.is_connected(_loyalty_refresh_callable):
			EventBus.unit_loyalty_changed.connect(_loyalty_refresh_callable)
		if not EventBus.combat_action_performed.is_connected(_on_combat_action_performed):
			EventBus.combat_action_performed.connect(_on_combat_action_performed)
		if not EventBus.aid_action_performed.is_connected(_on_aid_action_performed):
			EventBus.aid_action_performed.connect(_on_aid_action_performed)

	call_deferred("_update_initial_state")

func _on_unit_damaged(target: Node, _amount: int, source: Node) -> void:
	if not is_instance_valid(target): return
	var _target_name = target.unit_name if "unit_name" in target else "Target"
	var _source_name = source.unit_name if source and "unit_name" in source else "Attacker"
	# Keep the old feedback for now, or replace it? The user asked for dialogue.
	# show_feedback("%s hit %s for %d damage!" % [source_name, target_name, amount])
	pass

func _on_combat_action_performed(attacker: Node, defender: Node, attribute_index: int, results: Dictionary) -> void:
	var title = "reaction_feedback" if results.get("is_reaction", false) else "action_feedback"
	_trigger_action_feedback(attacker, defender, attribute_index, results.damage_to_target, title)

func _on_aid_action_performed(helper: Node, ally: Node, attribute_index: int, amount: int) -> void:
	_trigger_action_feedback(helper, ally, attribute_index, amount, "aid_feedback")

func _trigger_action_feedback(initiator: Node, target: Node, attr_idx: int, amount: int, title: String) -> void:
	var dialogue_resource = load("res://Resources/Localization/system_barks.dialogue")
	var attr_name = tr("attr." + GameConstants.get_attribute_name(attr_idx).to_lower())

	var data = {
		"initiator_name": initiator.unit_name if "unit_name" in initiator else tr("hud.unit_unknown"),
		"partner_name": target.unit_name if "unit_name" in target else tr("hud.unit_unknown"),
		"attribute_name": attr_name,
		"amount": amount
	}

	var balloon_state = BarkBalloonState.new()
	balloon_state.setup(data)

	var log_msg = CombatFeedbackServiceScript.format_action_log(data.initiator_name, data.partner_name, data.attribute_name, data.amount)
	EventBus.interaction_logged.emit(log_msg)

	var auto_battle := _state.command_context.auto_battle_active if _state and _state.command_context else false
	if auto_battle:
		return

	DialogueManager.show_dialogue_balloon(dialogue_resource, title, [balloon_state])

class BarkBalloonState extends Object:
	var initiator_name: String = ""
	var partner_name: String = ""
	var attribute_name: String = ""
	var amount: int = 0

	func setup(data: Dictionary) -> void:
		initiator_name = data.get("initiator_name", "")
		partner_name = data.get("partner_name", "")
		attribute_name = data.get("attribute_name", "")
		amount = data.get("amount", 0)

func _on_locale_changed() -> void:
	# Trigger a full refresh of all programmatically set strings in the controller's purview
	_update_objective_from_manager()
	_update_round_and_turn()
	_update_task_progress()

	# Update localized button text
	if is_instance_valid(_auto_battle_button):
		var is_enabled = _auto_battle_button.button_pressed
		_auto_battle_button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE_ON) if is_enabled else LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE)

func _update_initial_state() -> void:
	_update_round_and_turn()
	_update_task_progress()
	_update_objective_from_manager()
	var selected_idx := _unit_manager.get_selected_index() if is_instance_valid(_unit_manager) else -1
	_on_unit_manager_selection_changed(selected_idx)

func set_aim_cursor(cursor: AimCursor) -> void:
	_aim_cursor = cursor

func set_safe_zone_mode(is_safe_zone: bool) -> void:
	_is_safe_zone_mode = is_safe_zone
	_apply_safe_zone_visibility()

func set_auto_battle_state(enabled: bool) -> void:
	if is_instance_valid(_auto_battle_button):
		_auto_battle_button_sync = true
		_auto_battle_button.button_pressed = enabled
		_auto_battle_button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE_ON) if enabled else LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE)
		_auto_battle_button_sync = false

	if _components and is_instance_valid(_components.actions_panel):
		_components.actions_panel.set_auto_battle_mode(enabled)

func set_auto_battle_enabled(interactable: bool) -> void:
	if is_instance_valid(_auto_battle_button):
		_auto_battle_button.disabled = not interactable

func _process(_delta: float) -> void:
	if is_instance_valid(_hover_service):
		_hover_service.process_hover(get_global_mouse_position(), get_viewport().gui_get_hovered_control())

func handle_actions_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, _unit_index: int = -1) -> void:
	var enabled: bool = _turn_controller.is_enabled() if is_instance_valid(_turn_controller) else true
	actions_updated.emit(unit, terrain_map, unit_manager, _combat_system, enabled)
	if is_instance_valid(_hover_service):
		_hover_service.force_hover_update(get_global_mouse_position())

func handle_dialogue_finished(_flag_id: StringName) -> void:
	var unit: Unit = _unit_manager.get_selected_unit() if is_instance_valid(_unit_manager) else null
	var enabled: bool = _turn_controller.is_enabled() if is_instance_valid(_turn_controller) else true
	actions_updated.emit(unit, _terrain_map, _unit_manager, _combat_system, enabled)

func force_hover_update() -> void:
	if is_instance_valid(_hover_service):
		_hover_service.force_hover_update(get_global_mouse_position())

func _on_selection_changed(_unit_index: int) -> void:
	# ... implementation ...
	pass

func _setup_hover_service() -> void:
	_hover_service = HUDHoverService.new()
	_hover_service.setup(self, _unit_manager, _grid, _terrain_map, _grid_visuals, _aim_cursor)
	add_child(_hover_service)

func refresh_after_state_restore() -> void:
	_update_round_and_turn()
	_update_task_progress()
	_update_objective_from_manager()
	var selected_idx := _unit_manager.get_selected_index() if is_instance_valid(_unit_manager) else -1
	_on_unit_manager_selection_changed(selected_idx)

func set_ui_navigation_mode(enabled: bool) -> void:
	if not _components or not is_instance_valid(_components.actions_panel): return
	if enabled:
		_components.actions_panel.enable_navigation_mode()
	elif not enabled:
		_components.actions_panel.disable_navigation_mode()

func _on_round_changed(_round: int = 0) -> void:
	_update_round_and_turn()

func _on_turn_changed(_unit: Unit = null) -> void:
	_update_round_and_turn()
	if is_instance_valid(_turn_system):
		EventBus.turn_changed.emit(_turn_system.get_current_round(), _turn_system.get_current_side())

func _on_turn_queue_updated() -> void:
	_update_round_and_turn()

func _on_task_updated(_index: int, _faction: int) -> void:
	_update_objective_from_manager()

func _on_task_completed(_index: int, _faction: int, _unit: Unit = null) -> void:
	_update_objective_from_manager()

func _on_task_failed(_index: int, _faction: int) -> void:
	_update_objective_from_manager()

func _apply_safe_zone_visibility() -> void:
	if not _components: return
	var combat_visible := not _is_safe_zone_mode
	_set_panel_visible(_components.actions_panel, true)
	_set_panel_visible(_components.combat_preview, combat_visible)
	_set_panel_visible(_components.morale_panel, combat_visible)

func _set_panel_visible(panel: Node, p_visible: bool) -> void:
	if is_instance_valid(panel): panel.visible = p_visible

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	if not _components: return

	var is_portrait := false
	if DisplaySettings:
		is_portrait = DisplaySettings.get_current_orientation() == DisplayOrientation.Orientation.PORTRAIT
	elif is_inside_tree():
		var viewport_size = get_viewport().get_visible_rect().size
		is_portrait = viewport_size.y > viewport_size.x

	if is_portrait != _current_is_portrait or not is_instance_valid(_components.margin_container):
		_swap_hud_layout(is_portrait)
	else:
		_components.update_layout(is_portrait)

func _swap_hud_layout(is_portrait: bool) -> void:
	GameLogger.debug(GameLogger.Category.UI, "[HUDController] Swapping HUD layout to: ", "Portrait" if is_portrait else "Landscape")
	_current_is_portrait = is_portrait

	# Clean up old components if they exist
	if _components and is_instance_valid(_components.margin_container):
		_components.margin_container.queue_free()

	# Re-create using factory
	_components = HUDComponentFactory.create_components(_hud, is_portrait)

	# Re-setup
	_components.setup(_state, _config)

	# Re-connect signals using connector
	_signal_connector = load("res://GUI/HUD/hud_signal_connector.gd").new()
	_signal_connector.setup(self, _state, _components)
	_signal_connector.connect_all()

	# Portrait specific connections
	if is_portrait:
		_connect_portrait_tabs()
		_on_portrait_tab_pressed("locations")

	# Refresh current HUD state
	_update_initial_state()
	_apply_safe_zone_visibility()

func _connect_portrait_tabs() -> void:
	if not _components or not is_instance_valid(_components.margin_container): return
	var root = _components.margin_container
	if root.name != "PortraitHUD": return

	var locations_btn = root.get_node_or_null("%LocationsBtn")
	var tasks_btn = root.get_node_or_null("%TasksBtn")
	var unit_btn = root.get_node_or_null("%UnitBtn")

	if locations_btn: locations_btn.pressed.connect(_on_portrait_tab_pressed.bind(GameConstants.UI.TAB_LOCATIONS))
	if tasks_btn: tasks_btn.pressed.connect(_on_portrait_tab_pressed.bind(GameConstants.UI.TAB_TASKS))
	if unit_btn: unit_btn.pressed.connect(_on_portrait_tab_pressed.bind(GameConstants.UI.TAB_UNIT))

func _on_portrait_tab_pressed(tab_name: String) -> void:
	var tabs: Dictionary = _get_portrait_tabs()
	if tabs.is_empty(): return

	if _is_tab_already_visible(tabs, tab_name):
		_hide_all_portrait_tabs(tabs)
		return

	_update_portrait_tab_visibility(tabs, tab_name)

func _get_portrait_tabs() -> Dictionary:
	if not _components or not is_instance_valid(_components.margin_container): return {}
	var root = _components.margin_container
	if not root: return {}

	return {
		GameConstants.UI.TAB_LOCATIONS: root.get_node_or_null("%LocationsTab"),
		GameConstants.UI.TAB_TASKS: root.get_node_or_null("%TasksTab"),
		GameConstants.UI.TAB_UNIT: root.get_node_or_null("%UnitTab")
	}

func _is_tab_already_visible(tabs: Dictionary, tab_name: String) -> bool:
	var tab = tabs.get(tab_name)
	return tab.visible if is_instance_valid(tab) else false

func _hide_all_portrait_tabs(tabs: Dictionary) -> void:
	for tab in tabs.values():
		if is_instance_valid(tab):
			tab.visible = false

func _update_portrait_tab_visibility(tabs: Dictionary, tab_name: String) -> void:
	for current_tab_name in tabs:
		var tab = tabs[current_tab_name]
		if not is_instance_valid(tab): continue

		tab.visible = (current_tab_name == tab_name)
		if current_tab_name == tab_name:
			_handle_tab_specific_activation(current_tab_name)

func _handle_tab_specific_activation(tab_name: String) -> void:
	match tab_name:
		GameConstants.UI.TAB_LOCATIONS:
			if is_instance_valid(_components.locations_list): _components.locations_list.show()
			location_details_visibility_changed.emit(false)
		GameConstants.UI.TAB_TASKS:
			if is_instance_valid(_components.tasks_list): _components.tasks_list.show()
			task_details_visibility_changed.emit(false)

func _update_round_and_turn() -> void:
	if is_instance_valid(_turn_system):
		var enabled = _turn_controller.is_enabled() if _turn_controller else true
		round_updated.emit(_turn_system.get_current_round())
		turn_updated.emit(_turn_system.get_current_side())
		turn_status_updated.emit(_turn_controller.get_faction_turn_counts(_unit_manager))
		turn_system_enabled_updated.emit(enabled)
		set_auto_battle_enabled(enabled)


func _on_turn_system_enabled_changed(enabled: bool) -> void:
	turn_system_enabled_updated.emit(enabled)
	set_auto_battle_enabled(enabled)
	# Also update unit detail and action availability since they might depend on turn system state
	var unit: Unit = _unit_manager.get_selected_unit() if is_instance_valid(_unit_manager) else null
	if unit:
		unit_details_updated.emit(unit, _terrain_map, _unit_manager)
		actions_updated.emit(unit, _terrain_map, _unit_manager, _combat_system, enabled)


func _on_objective_updated(objective: Objective) -> void:
	_update_objective_display(objective)
	_update_task_progress()

func _on_objective_completed(objective: Objective) -> void:
	_update_objective_display(objective)
	_update_task_progress()

func _update_objective_from_manager() -> void:
	if is_instance_valid(_task_manager):
		_update_objective_display(_task_manager.get_active_objective())

func _update_objective_display(objective: Objective) -> void:
	var tasks_data = HUDTaskPresenter.transform_objective_to_data(objective, _task_manager)
	tasks_updated.emit(tasks_data)

func _update_task_progress() -> void:
	if is_instance_valid(_location_service):
		var locations_data = _location_service.get_all_locations_data()
		locations_updated.emit(locations_data)
		EventBus.locations_updated.emit()
	else:
		if not _logged_warnings.has("location_service_missing_update"):
			_logged_warnings["location_service_missing_update"] = true
			GameLogger.warning(GameLogger.Category.UI, "[HUDController] Cannot update locations; location service is missing.")

func _on_unit_manager_selection_changed(index: int) -> void:
	var old_unit: Unit = _unit_manager.get_unit(_last_selected_index) if _last_selected_index != -1 else null
	if is_instance_valid(old_unit):
		if old_unit.willpower_changed.is_connected(_on_selected_unit_willpower_changed):
			old_unit.willpower_changed.disconnect(_on_selected_unit_willpower_changed)

	_last_selected_index = index
	var unit: Unit = _unit_manager.get_unit(index) if is_instance_valid(_unit_manager) and index != -1 else null
	if unit:
		GameLogger.debug(GameLogger.Category.UI, "[HUDController] Selecting unit: ", unit.unit_name, " (", GameConstants.get_faction_name(int(unit.faction)), ")")
		EventBus.unit_selected.emit(unit)
		if not unit.willpower_changed.is_connected(_on_selected_unit_willpower_changed):
			unit.willpower_changed.connect(_on_selected_unit_willpower_changed)
	else:
		EventBus.unit_deselected.emit(null)

	_refresh_unit_details(unit)
	var enabled: bool = _turn_controller.is_enabled() if is_instance_valid(_turn_controller) else true
	actions_updated.emit(unit, _terrain_map, _unit_manager, _combat_system, enabled)

	if is_instance_valid(_grid_visuals):
		var reachable := ReachableState.create_empty()
		if unit:
			reachable = MovementRangeService.calculate_reachable_state(unit, _terrain_map, _unit_manager)

		var threatened_hexes := {}
		if _grid_visuals.is_enemy_range_visible():
			threatened_hexes = _map_controller.get_threat_map()

		_grid_visuals.update_range_indicator(_grid, reachable)
		_grid_visuals.update_loyalty_indicators(_unit_manager, _terrain_map, _grid)
		_grid_visuals.update_enemy_range_overlay(_grid, threatened_hexes)

func _on_selected_unit_willpower_changed(_unit: Unit) -> void:
	_refresh_unit_details(_unit)

func _on_unit_manager_unit_moved(index: int, _coord: Vector2i) -> void:
	if index == _last_selected_index:
		var unit: Unit = _unit_manager.get_unit(index)
		_refresh_unit_details(unit)

func _refresh_unit_details(unit: Unit) -> void:
	unit_details_updated.emit(unit, _terrain_map, _unit_manager)

var _last_selected_index: int = -1

func _on_unit_removed(_unit: Unit) -> void:
	_update_objective_from_manager()
	if is_instance_valid(_grid_visuals):
		_on_unit_manager_selection_changed(_unit_manager.get_selected_index())
	turn_status_updated.emit(_turn_controller.get_faction_turn_counts(_unit_manager))

func _on_task_completion_requested(task_id: String) -> void:
	if _task_manager:
		_task_manager.debug_complete_task(task_id)

func _on_location_selected(location_data: Dictionary) -> void:
	location_details_updated.emit(location_data)
	if _components and is_instance_valid(_components.margin_container):
		if _components.margin_container.name == "PortraitHUD":
			# In portrait, hide list and show details
			if is_instance_valid(_components.locations_list):
				_components.locations_list.hide()
			location_details_visibility_changed.emit(true)

func _on_task_selected(task_data: Dictionary) -> void:
	task_details_updated.emit(task_data)
	if _components and is_instance_valid(_components.margin_container):
		if _components.margin_container.name == "PortraitHUD":
			# In portrait, hide list and show details
			if is_instance_valid(_components.tasks_list):
				_components.tasks_list.hide()
			task_details_visibility_changed.emit(true)

var _pending_combat_target: Target

func _on_menu_requested(type: String, data: PlayerAction) -> void:
	GameLogger.debug(GameLogger.Category.UI, "HUDController: Received menu_requested, type=", type)
	if type == "pause":
		if is_instance_valid(_pause_handler):
			_pause_handler.show_pause_menu()
		return

	if type == "attack_menu":
		var target = data.target_object
		var selected_idx: int = _unit_manager.get_selected_index()
		var move_data = data.target_move_data
		GameLogger.debug(GameLogger.Category.UI, "HUDController: target=", target, " selected_idx=", selected_idx, " panel_valid=", is_instance_valid(_components.actions_panel))
		if target and selected_idx != -1 and is_instance_valid(_components.actions_panel):
			var attacker: Unit = _unit_manager.get_unit(selected_idx)
			GameLogger.debug(GameLogger.Category.UI, "HUDController: Calling show_attack_menu with attacker=", attacker.unit_name if attacker else "null")
			_pending_combat_target = target as Target
			_components.actions_panel.show_attribute_menu(attacker, data, move_data)
		else:
			GameLogger.debug(GameLogger.Category.UI, "HUDController: Skipping show_attack_menu - conditions not met")

func update_compass(p_rotation: float) -> void:
	if _components and _components.weather_panel:
		_components.weather_panel.update_compass(p_rotation)

func show_feedback(text: String) -> void:
	FeedbackDisplay.new().show_feedback(text, _hud, _animation_service)

func _on_hud_action_executed(action_type: int) -> void:
	if action_type == GameConstants.ActionType.OPEN_ATTACK_MENU:
		return
	_pending_combat_target = null
	var unit: Unit = _unit_manager.get_selected_unit() if is_instance_valid(_unit_manager) else null
	var enabled: bool = _turn_controller.is_enabled() if is_instance_valid(_turn_controller) else true
	actions_updated.emit(unit, _terrain_map, _unit_manager, _combat_system, enabled)

func _on_attribute_hovered(idx: int) -> void:
	if idx == -1:
		_hide_combat_preview()
		return

	var target_info = _resolve_hover_target()
	var target: Target = target_info.target
	var active_action = target_info.active_action

	var selected_idx: int = _unit_manager.get_selected_index()
	if selected_idx == -1 or not target or _combat_system == null or not is_instance_valid(_components.combat_preview):
		return

	var attacker: Unit = _unit_manager.get_unit(selected_idx)
	_show_action_preview(attacker, target, active_action, idx)

func _hide_combat_preview() -> void:
	if is_instance_valid(_components.combat_preview):
		_components.combat_preview.hide_preview()

func _resolve_hover_target() -> Dictionary:
	var target: Target = _pending_combat_target
	var active_action = null

	if _components and is_instance_valid(_components.actions_panel):
		var panel_target = _components.actions_panel.get_current_attack_target()
		if panel_target:
			target = panel_target
			_pending_combat_target = panel_target

		active_action = _components.actions_panel.get_active_action()

	return {"target": target, "active_action": active_action}

func _show_action_preview(attacker: Unit, target: Target, active_action: Variant, attr_idx: int) -> void:
	if active_action and (active_action.type == GameConstants.ActionType.AID or active_action.interact_action_type == GameConstants.ActionType.AID):
		var pair_idx: int = int(float(attr_idx) / 2.0)
		_show_aid_preview(attacker, target, pair_idx)
	else:
		var forecast = _combat_system.get_combat_forecast(attacker, target, attr_idx)
		_components.combat_preview.show_forecast(attacker, target, forecast)

func _show_aid_preview(attacker: Unit, target: Target, pair_idx: int) -> void:
	var pair: Array = GameConstants.Combat.COMBAT_ATTRIBUTE_PAIRS[pair_idx]
	var bonus := 0
	if attacker and _combat_system:
		bonus = _combat_system.get_aid_bonus(attacker, pair[0]) # Or use both and max, but system has it now
	_components.combat_preview.show_aid_forecast(attacker, target, pair, bonus)



func calculate_distance_to_cell(cell: Vector2i) -> String:
	if is_instance_valid(_map_controller) and is_instance_valid(_unit_manager):
		return _map_controller.get_distance_to_selected(cell, _unit_manager)
	return ""
