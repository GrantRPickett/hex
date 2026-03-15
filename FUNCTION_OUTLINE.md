# Project Function Outline

## Autoloads

### Autoloads/achievement_manager.gd
- func _ready() -> void
- func unlock_achievement(achievement_id: String) -> bool
- func get_savable_data() -> Dictionary
- func load_savable_data(data: Dictionary)

### Autoloads/audio_bus_controller.gd
- func _ready() -> void
- func _apply_saved_settings() -> void
- func set_bus_volume_db(bus_name: String, volume_db: float) -> void
- func get_bus_volume_db(bus_name: String) -> float
- func mute_bus(bus_name: String, mute := true) -> void
- func is_bus_muted(bus_name: String) -> bool
- func play_music(stream: AudioStream, bus_name: String = "Music") -> void
- func stop_music() -> void
- func _ensure_bus(bus_name: String) -> void

### Autoloads/audio_manager.gd
- func _ready() -> void
- func _setup_sfx_pool() -> void
- func _connect_to_event_bus() -> void
- func play_sfx(sound_id: String) -> void
- func _get_next_player() -> AudioStreamPlayer

### Autoloads/control_settings.gd
- func _ready() -> void
- func _initialize_input_map() -> void
- func reset_inputs_to_defaults() -> void

### Autoloads/difficulty_service.gd
- func _ready() -> void
- func _on_config_changed(path: String, value) -> void
- func get_ai_scaling_factor() -> float
- func get_ai_morale_weight() -> float
- func get_retreat_threshold() -> float
- func get_combat_modifier() -> float

### Autoloads/display_settings.gd
- func _ready() -> void
- func _load_stored_settings() -> void
- func _get_stored_orientation_name() -> String
- func _resolve_resolution(stored: Variant, options: Array[Vector2i]) -> Vector2i
- func _find_resolution_index(target: Vector2i, options: Array[Vector2i]) -> int
- func _apply_window_settings() -> void
- func _get_active_window_id() -> int
- func get_standard_resolutions(orientation: DisplayOrientation.Orientation) -> Array[Vector2i]
- func get_current_orientation() -> DisplayOrientation.Orientation
- func get_current_resolution_index() -> int
- func get_current_resolution() -> Vector2i
- func set_orientation(orientation: DisplayOrientation.Orientation) -> void
- func set_resolution_index(index: int) -> void

### Autoloads/file_paths.gd
- static func get_dialogue_path(level_id: String, dialogue_id: String) -> String
- static func get_level_path(level_id: String) -> String
- static func get_path_separator() -> String
- static func join_path(base: String, extra: String) -> String
- static func path_exists(path: String) -> bool
- static func get_all_categories() -> Array[String]
- static func get_all_paths() -> Dictionary

### Autoloads/game_config.gd
- func _ready() -> void
- func reset_to_defaults() -> void
- func set_value(path: String, value) -> void
- func get_value(path: String, default_value = null)
- func save_config() -> void
- func load_config() -> void
- func _set_by_path(path: String, value) -> void
- func _get_by_path(path: String, default_value)
- func _deep_merge(base: Dictionary, update: Dictionary) -> Dictionary

### Autoloads/game_constants.gd
- static func colorize_attributes(text: String) -> String
- static func get_faction_name(faction: int) -> String

### Autoloads/input_mapper.gd
- func apply_configs(configs: Array, fallback: Array = []) -> void
- func map_action(action: String, keys: Array, buttons: Array = [], mouse_buttons: Array = []) -> void
- func clear_action(action: String) -> void
- func _as_int_array(value) -> Array

### Autoloads/item_registry.gd
- func _ready() -> void
- func _load_templates() -> void
- func get_template(item_id: String) -> ItemTemplate
- func get_all_templates() -> Array[ItemTemplate]
- func create_instance(item_id: String) -> InventoryItem

### Autoloads/journal_manager.gd
- func setup(task_manager: TaskManager) -> void
- func _ready()
- func set_level(level: Level) -> void
- func _ensure_initialized() -> void
- func _initialize_default_content()
- func unlock_entry(entry_id: String) -> bool
- func clear_journal() -> void
- func unlock_coupled_entry(entry_id: String, section_id: String, topic_id: String, notes: String, _flag_name: StringName) -> void
- func get_journal_data() -> JournalData
- func get_entry(entry_id: String) -> LevelJournalEntry
- func get_section(section_id: String) -> JournalSection
- func get_savable_data() -> Dictionary
- func load_savable_data(data: Dictionary)
- func _on_objective_updated(objective: Objective) -> void
- func _on_task_completed_signal(_faction_id: int, _unit: Unit, task: Task, objective: Objective) -> void
- func _on_task_failed_signal(task: Task, objective: Objective) -> void
- func _on_objective_completed(objective: Objective) -> void
- func _add_or_update_objective_entry(objective: Objective, status: String = "active") -> void
- func _add_or_update_stage_entry(stage: Stage, objective: Objective, status: String = "active") -> void
- func _add_or_update_task_entry(task: Task, status: String = "active", objective: Objective = null) -> void
- func _generate_entry_id(prefix: String, game_object_id: String) -> String
- func _get_objective_section() -> JournalSection
- func _on_task_status_changed(task: Task, new_status_str: String, objective: Objective, _args = null) -> void
- func _task_status_to_string(status_enum: Task.Status) -> String

### Autoloads/level_manager.gd
- func _ready() -> void
- func start_level_by_id(level_id: String) -> void
- func start_first_level() -> void
- func get_level_info(level_id: String) -> Dictionary
- func is_level_unlocked(level_id: String) -> bool
- func mark_level_completed(level_id: String) -> void
- func get_available_levels() -> Array[Dictionary]
- func get_current_level_path() -> String
- func get_current_level_id() -> String
- func is_level_completed(level_id: String) -> bool
- func reset_completed_levels() -> void
- func _on_level_complete() -> void
- func _on_quit_to_title() -> void
- func _on_quit_to_level_select() -> void

### Autoloads/locale_service.gd
- func _ready() -> void
- func _notification(what: int) -> void
- func apply_locale_settings() -> void
- func _apply_font_for_locale(locale: String) -> void

### Autoloads/resource_loader_service.gd
- func collect_resources_recursive(path: String, extension: String = ".tres", type_hint: String = "") -> Array[Resource]
- func load_resources_in_dir(path: String, extension: String = ".tres") -> Array[Resource]

### Autoloads/roster_manager.gd
- func _ready() -> void
- func _exit_tree() -> void
- func get_roster() -> PlayerRoster
- func get_units() -> Array[Unit]
- func save_roster() -> void
- func transfer_item(item: InventoryItem, source_unit: Unit, target_unit: Unit) -> void
- func toggle_item_equip(item: InventoryItem, unit: Unit) -> void
- func swap_items(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit) -> void
- func add_to_stash(item: InventoryItem) -> void
- func auto_equip() -> void
- func debug_reset_roster() -> void
- func sync_from_combat(unit_manager: UnitManager, stash_items: Array[InventoryItem]) -> void
- func sync_to_combat(unit_manager: UnitManager) -> void
- func sync_unit(combat_unit: Unit) -> void
- func _sync_single_unit_to_roster(combat_unit: Unit) -> void
- func _load_roster() -> void
- func _instantiate_units() -> void
- func _setup_unit(unit: Unit) -> void
- func _clear_loaded_units() -> void

### Autoloads/save_manager.gd
- func _ready() -> void
- func _setup_timer() -> void
- func setup() -> void
- func set_global_flag(flag_id: String, value: Variant) -> void
- func get_global_flags() -> Dictionary
- func set_level_flag(level_id: String, flag_id: String, value: Variant) -> void
- func get_level_flags(level_id: String) -> Dictionary
- func set_value(key: String, value: Variant) -> void
- func get_value(key: String, default: Variant = null) -> Variant
- func save_roster(roster: PlayerRoster) -> void
- func load_roster() -> PlayerRoster
- func has_saved_roster() -> bool
- func set_hometown_skit_shown(skit_path: String, shown: bool) -> void
- func get_hometown_skits() -> Dictionary
- func get_leader_unit_name() -> String
- func set_leader_unit_name(unit_name: String) -> void
- func get_completed_levels_count() -> int
- func _load_data() -> void
- func _save_data(memento: Dictionary = {}) -> void
- func _perform_actual_save() -> void
- func create_game_memento(game_state: GameState = null) -> Dictionary
- func _merge_system_data(memento: Dictionary) -> void
- func _capture_state_mementos(memento: Dictionary, game_state: GameState) -> void
- func restore_game_state(memento: Dictionary) -> void
- func _distribute_loaded_data(data: Dictionary) -> void
- func _distribute_config_data(data: Dictionary) -> void
- func _distribute_roster_data() -> void
- func _distribute_journal_data(data: Dictionary) -> void
- func _distribute_achievement_data(data: Dictionary) -> void
- func _distribute_weather_data(data: Dictionary) -> void
- func _load_saved_roster_resource() -> PlayerRoster
- func _restore_roster_units(roster: PlayerRoster) -> void
- func _load_default_player_roster() -> PlayerRoster
- func _load_roster_from_resource(path: String) -> PlayerRoster
- func save_current_state_for_undo() -> void
- func undo_state() -> bool
- func redo_state() -> bool
- func _get_journal_manager() -> Node
- func _get_achievement_manager() -> Node
- func get_all_skits() -> Array[Skit]

### Autoloads/scene_transition.gd
- func change_scene(path: String, delay := -1.0, emit_signal_only := false) -> bool
- func reload_current(emit_signal_only := false) -> bool
- func is_changing() -> bool

### Autoloads/weather_manager.gd
- func is_hard_mode() -> bool
- func _ready() -> void
- func add_pressure(pressure: String, to_forecast: bool = true) -> void
- func remove_pressure(pressure: String, from_forecast: bool = true) -> void
- func clear_pressures(forecast_only: bool = true) -> void
- func _notify_changed(forecast: bool) -> void
- func advance_weather() -> void
- func start_channeling(unit: Unit) -> bool
- func get_channeling_unit() -> Unit
- func create_memento(unit_manager: Node = null) -> Dictionary
- func restore_from_memento(memento: Dictionary, unit_manager: Node = null) -> void
- func get_weather_info(pressures: Array[String] = current_pressures) -> Dictionary
- func _get_basic_weather_info(pressures: Array[String]) -> Dictionary
- func _get_hard_mode_weather_info(pressures: Array[String]) -> Dictionary
- func apply_weather_effects() -> void
- func get_current_weather_attribute() -> WeatherAttribute

## GUI

### GUI/Compass.gd
- func _ready() -> void

### GUI/HUD/HoverStates/combat_preview_state.gd
- func can_enter(controller: Node, cell: Vector2i) -> bool
- func update(controller: Node, cell: Vector2i) -> void
- func _get_combat_target_at(controller: Node, cell: Vector2i) -> Target
- func exit(controller: Node) -> void

### GUI/HUD/HoverStates/hover_state.gd
- func can_enter(_controller: Node, _cell: Vector2i) -> bool
- func enter(controller: Node, cell: Vector2i) -> void
- func update(_controller: Node, _cell: Vector2i) -> void
- func exit(_controller: Node) -> void

### GUI/HUD/HoverStates/idle_state.gd
- func can_enter(_controller: Node, _cell: Vector2i) -> bool

### GUI/HUD/HoverStates/location_hover_state.gd
- func can_enter(controller: Node, cell: Vector2i) -> bool
- func update(controller: Node, cell: Vector2i) -> void
- func exit(controller: Node) -> void

### GUI/HUD/HoverStates/loot_hover_state.gd
- func can_enter(controller: Node, cell: Vector2i) -> bool
- func update(controller: Node, cell: Vector2i) -> void
- func exit(controller: Node) -> void

### GUI/HUD/HoverStates/task_hover_state.gd
- func can_enter(controller: Node, cell: Vector2i) -> bool
- func update(controller: Node, cell: Vector2i) -> void
- func exit(controller: Node) -> void

### GUI/HUD/HoverStates/terrain_hover_state.gd
- func can_enter(controller: Node, cell: Vector2i) -> bool
- func update(controller: Node, cell: Vector2i) -> void
- func exit(controller: Node) -> void

### GUI/HUD/HoverStates/unit_hover_state.gd
- func can_enter(controller: Node, cell: Vector2i) -> bool
- func update(controller: Node, cell: Vector2i) -> void
- func exit(controller: Node) -> void

### GUI/HUD/aim_cursor.gd
- func _draw() -> void
- func _ready() -> void
- func set_initial_position(pos: Vector2) -> void
- func connect_input_handler(handler: InputHandler) -> void
- func get_effective_cursor_position(fallback_mouse_pos: Vector2) -> Vector2
- func is_virtual_active() -> bool
- func _on_joy_aim_held(axis: Vector2, delta: float) -> void
- func _process(delta: float) -> void
- func _update_crosshair() -> void

### GUI/HUD/hover_info_manager.gd
- func _init(state: GameState) -> void
- func _ready() -> void
- func _reparent_to_root() -> void
- func set_info(text: String) -> void
- func _hide_hover_info(_reason: String) -> void
- func _process(_delta: float) -> void
- func _update_position(mouse_pos: Vector2) -> void
- func _get_hovered_object_at(coord: Vector2i, _global_mouse_pos: Vector2) -> Object
- func _show_hover_info(info: String, mouse_pos: Vector2) -> void
- func get_hex_occupants_at_mouse_position() -> Array[Node2D]
- func get_unit_at_mouse_position() -> Unit

### GUI/HUD/hud_component_factory.gd
- func setup(state: GameState, config: GameSessionBuilder.Config) -> void
- func update_layout(_is_portrait: bool) -> void
- func _get_setup_method_info(panel) -> Dictionary
- static func create_components(parent: Node, is_portrait: bool) -> Components
- static func _populate_from_scene(components: Components, root: Node, is_portrait: bool) -> void
- static func _populate_landscape(components: Components, root: Node) -> void
- static func _populate_portrait(components: Components, root: Node) -> void
- static func _create_layout_containers(root: MarginContainer) -> Dictionary
- static func _populate_components(_components: Components, _containers: Dictionary) -> void
- static func _populate_left_column(components: Components, column: VBoxContainer) -> void
- static func _populate_right_column(components: Components, container: Control) -> void
- static func _create_right_column_buttons(components: Components, container: Control) -> void
- static func _create_right_column_panels(components: Components, container: Control) -> void
- static func _populate_center_sections(components: Components, containers: Dictionary) -> void
- static func _instantiate_panel(scene_path: String, container: Control, name := "", h_flag := Control.SIZE_SHRINK_CENTER, v_flag := Control.SIZE_SHRINK_CENTER) -> Control
- static func _create_button(container: Control, spec: Dictionary) -> Button

### GUI/HUD/hud_config.gd
- func with_components(value: HUDComponentFactory.Components) -> Builder
- func with_turn_system(value: TurnSystem) -> Builder
- func with_unit_manager(value: UnitManager) -> Builder
- func with_task_manager(value: TaskManager) -> Builder
- func with_loot_manager(value: LootManager) -> Builder
- func with_combat_system(value: CombatSystem) -> Builder
- func with_pause_handler(value: PauseHandler) -> Builder
- func with_terrain_map(value: TerrainMap) -> Builder
- func with_map_controller(value: MapController) -> Builder
- func with_animation_service(value) -> Builder
- func with_locations_list_panel(value: LocationsListPanel) -> Builder
- func with_location_details_panel(value: LocationDetailsPanel) -> Builder
- func with_tasks_list_panel(value: TasksListPanel) -> Builder
- func with_task_details_panel(value: TaskDetailsPanel) -> Builder
- func with_task_controller(value: TaskController) -> Builder
- func with_location_service(value: LocationService) -> Builder
- func build() -> Config

### GUI/HUD/hud_controller.gd
- func emit_unit_details_visibility_changed(p_visible: bool) -> void
- func emit_combat_preview_shown(attacker: Target, defender: Target) -> void
- func emit_combat_preview_hidden() -> void
- func emit_location_details_updated(location_data) -> void
- func emit_task_details_updated(task_data) -> void
- func emit_loot_details_updated(loot: Loot) -> void
- func emit_terrain_details_updated(terrain: TerrainTile, distance: String) -> void
- func emit_auto_battle_toggle_requested(enabled: bool) -> void
- func _ready() -> void
- func setup(state: GameState, components: HUDComponentFactory.Components, config: GameSessionBuilder.Config) -> void
- func _on_unit_damaged(target: Node, amount: int, source: Node) -> void
- func _on_locale_changed() -> void
- func _update_initial_state() -> void
- func set_aim_cursor(cursor: AimCursor) -> void
- func set_safe_zone_mode(is_safe_zone: bool) -> void
- func set_auto_battle_state(enabled: bool) -> void
- func set_auto_battle_enabled(interactable: bool) -> void
- func _process(_delta: float) -> void
- func handle_actions_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, _unit_index: int = -1) -> void
- func handle_dialogue_finished(_flag_id: StringName) -> void
- func _setup_hover_service() -> void
- func refresh_after_state_restore() -> void
- func set_ui_navigation_mode(enabled: bool) -> void
- func _on_round_changed(_round: int = 0) -> void
- func _on_turn_changed(_unit: Unit = null) -> void
- func _on_turn_queue_updated() -> void
- func _on_task_updated(_index: int, _faction: int) -> void
- func _on_task_completed(_index: int, _faction: int, _unit: Unit = null) -> void
- func _on_task_failed(_index: int, _faction: int) -> void
- func _apply_safe_zone_visibility() -> void
- func _set_panel_visible(panel: Node, p_visible: bool) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void
- func _swap_hud_layout(is_portrait: bool) -> void
- func _connect_portrait_tabs() -> void
- func _on_portrait_tab_pressed(tab_name: String) -> void
- func _update_round_and_turn() -> void
- func _on_turn_system_enabled_changed(enabled: bool) -> void
- func _on_objective_updated(objective: Objective) -> void
- func _on_objective_completed(objective: Objective) -> void
- func _update_objective_from_manager() -> void
- func _update_objective_display(objective: Objective) -> void
- func _update_task_progress() -> void
- func _on_unit_manager_selection_changed(index: int) -> void
- func _on_selected_unit_willpower_changed(_unit: Unit) -> void
- func _on_unit_manager_unit_moved(index: int, _coord: Vector2i) -> void
- func _refresh_unit_details(unit: Unit) -> void
- func _on_unit_removed(_unit: Unit) -> void
- func _on_task_completion_requested(task_id: String) -> void
- func _on_location_selected(location_data: Dictionary) -> void
- func _on_task_selected(task_data: Dictionary) -> void
- func _on_menu_requested(type: String, data: UnitAction) -> void
- func update_compass(p_rotation: float) -> void
- func show_feedback(text: String) -> void
- func _on_hud_action_executed(action_type: int) -> void
- func _on_attribute_hovered(idx: int) -> void
- func _hide_combat_preview() -> void
- func _resolve_hover_target() -> Dictionary
- func _show_action_preview(attacker: Unit, target: Target, active_action: Variant, pair_idx: int) -> void
- func _show_aid_preview(attacker: Unit, target: Target, pair_idx: int) -> void
- func calculate_distance_to_cell(cell: Vector2i) -> String
- func _calculate_faction_turn_counts() -> Dictionary

### GUI/HUD/hud_hover_service.gd
- func setup(controller: Node) -> void
- func _init_hover_states() -> void
- func process_hover() -> void
- func update_hover_info(cell: Vector2i) -> void
- func _are_hover_dependencies_valid() -> bool
- func _clear_all_hover_states() -> void
- func force_hover_update() -> void

### GUI/HUD/hud_signal_connector.gd
- func setup(hud_controller, state: GameState, components: HUDComponentFactory.Components) -> void
- func connect_all() -> void
- func _connect_task_manager_signals() -> void
- func _connect_turn_system_signals() -> void
- func _connect_components() -> void
- func _connect_system_controls() -> void
- func _connect_auto_battle_controls() -> void
- func _connect_pause_controls() -> void
- func _connect_debug_controls() -> void
- func _connect_debug_stat_buttons() -> void
- func _apply_debug_stat_boost(faction: int, enabled: bool) -> void
- func _connect_hud_signals() -> void
- func _connect_unit_manager_signals() -> void

### GUI/HUD/hud_task_presenter.gd
- static func transform_objective_to_data(objective: Objective, unit_manager: UnitManager = null) -> Array
- static func _transform_task(task: Task, stage_id: String) -> Dictionary

### GUI/HUD/threat_warning_service.gd
- func evaluate(unit, origin: Vector2i, path: Array[Vector2i], unit_manager, terrain_map) -> Dictionary
- func needs_confirmation() -> bool
- func acknowledge_warning() -> String
- func reset() -> void

### GUI/action_target_handler.gd
- static func populate_target_lists(action: UnitAction) -> Dictionary
- static func get_target_name(target: Target, loc: GDScript) -> String
- static func format_target_button_text(target: Target, reachable_targets: Array[Target], move_info: Dictionary, loc: GDScript, all_targets: Array[Target] = []) -> String

### GUI/actions_panel.gd
- func _ready() -> void
- func _setup_hint_label() -> void
- func _on_locale_changed() -> void
- func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool = true) -> void
- func _should_defer_update(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool) -> bool
- func _handle_invalid_states(unit: Unit, unit_manager: UnitManager) -> bool
- func _handle_no_actions(unit: Unit, available_actions: Array) -> bool
- func _add_action_button(unit: Unit, action: UnitAction) -> Button
- func show_attribute_menu(unit: Unit, action: UnitAction, move_info: Dictionary = {}) -> void
- func _prepare_attribute_menu(_unit: Unit, action: UnitAction, move_info: Dictionary) -> bool
- func _add_target_selector(unit: Unit, action: UnitAction, targets: Array[Target]) -> void
- func _build_attribute_grid(unit: Unit, action: UnitAction) -> bool
- func _build_aid_attribute_grid(unit: Unit, action: UnitAction, attrs) -> bool
- func _build_standard_attribute_grid(unit: Unit, action: UnitAction, attrs) -> bool
- func _emit_attribute_action(action: UnitAction, idx: int, name: String, interact_type: UnitAction.Type) -> void
- func _create_grid(cols: int) -> GridContainer
- func _create_grid_button(grid: Control, txt: String) -> Button
- func _add_label(txt: String) -> void
- func _add_back_button() -> void
- func _clear_actions() -> void
- func _update_hint_visibility() -> void
- func _show_hint(msg: String) -> void
- func _show_actions_hint() -> void
- func enable_navigation_mode() -> void
- func disable_navigation_mode() -> void
- func _focus_first() -> bool
- func _register_focus_target(c: Control) -> void
- func set_auto_battle_mode(active: bool) -> void
- func get_current_attack_target() -> Target
- func get_active_action() -> UnitAction
- func _get_action_label(a: UnitAction) -> String
- func _get_action_hint(a: UnitAction) -> String
- func _get_target_name(t: Target) -> String

### GUI/combat_preview_panel.gd
- func _ready() -> void
- func _on_locale_changed() -> void
- func show_preview(attacker: Target, defender: Target) -> void
- func show_forecast(attacker: Target, defender: Target, forecast: Dictionary) -> void
- func show_aid_forecast(attacker: Target, defender: Target, pair_names: Array, bonus: int) -> void
- func _get_target_name(target: Target) -> String
- func _update_panel_layout() -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void
- func hide_preview() -> void

### GUI/custom_resizable_panel.gd
- func _ready() -> void
- func _update_padding() -> void
- func _update_min_size() -> void
- func force_fit_content() -> void

### GUI/feedback_display.gd
- func _init()
- func show_feedback(text: String, hud_node: Node, animation_service = null) -> void

### GUI/hover_info_panel.gd
- func set_info(text: String) -> void

### GUI/hud.gd
- func _ready() -> void
- func setup(state: GameState, _config: GameSessionBuilder.Config) -> void
- func set_animation_service(service) -> void
- func _create_default_ui() -> void
- func on_action_selected(action: UnitAction) -> void
- func on_command_executed(_command_name: String, result: CommandResult) -> void
- func _refresh_actions_after_command() -> void
- func _sync_selected_unit() -> bool
- func _resolve_tentative_move_if_needed() -> bool
- func _await_tentative_resolution() -> void
- func show_warning_message(text: String) -> void
- func _create_warning_label(text: String) -> Label
- func _fallback_warning_flash(label: Label) -> void
- func _create_panel(p_name: String, p_pos: Vector2, p_size: Vector2) -> Panel
- func _create_vbox(p_name: String, parent: Control, padding: float) -> VBoxContainer
- func _create_label(p_name: String, parent: Node) -> Label

### GUI/hud_action_executor.gd
- func _init(hud: Node, unit_manager: UnitManager, input_controller: InputController) -> void
- func execute_action(action: UnitAction, current_unit: Unit, current_unit_index: int) -> bool
- func _try_execute_mapped_command(action: UnitAction, current_unit: Unit, current_unit_index: int) -> CommandResult
- func _run_input_command(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult
- func _command_success(result) -> bool
- func _execute_attack_command(action: UnitAction, current_unit_index: int) -> CommandResult
- func _execute_attack_payload(attacker_idx: int, target_idx: int, attr_idx: int) -> CommandResult
- func _execute_aid_command(action: UnitAction, current_unit_index: int) -> CommandResult
- func _execute_convince_command(action: UnitAction, current_unit_index: int) -> CommandResult
- func _execute_convince_payload(initiator_idx: int, target_idx: int) -> CommandResult
- func _execute_loot_command(action: UnitAction, current_unit: Unit, current_unit_index: int) -> CommandResult
- func _execute_loot_payload(looter_idx: int, coord: Vector2i) -> CommandResult
- func _execute_skill_command(action: UnitAction, current_unit_index: int) -> CommandResult
- func _execute_talk_command(action: UnitAction, current_unit_index: int) -> CommandResult
- func _execute_move_and_interact_action(action: UnitAction, current_unit: Unit, current_unit_index: int) -> bool
- func _move_unit_to_coord(target_coord: Vector2i, _current_unit: Unit, current_unit_index: int) -> bool
- func _convert_action_to_dict(action: UnitAction) -> Dictionary

### GUI/inventory/inventory_character_panel.gd
- func setup(p_unit: Unit) -> void
- func _ready() -> void
- func refresh() -> void
- func _add_stat_row(stat_name: String, base: int, bonus: int, total: int, stat_color: Color = GameConstants.Colors.UI_WHITE) -> void
- func _can_drop_data(_at_position: Vector2, data: Variant) -> bool
- func _drop_data(_at_position: Vector2, data: Variant) -> void
- func set_highlight(active: bool) -> void

### GUI/inventory/inventory_item_slot.gd
- func setup(p_item: InventoryItem, p_unit: Unit) -> void
- func _ready() -> void
- func _update_ui() -> void
- func _get_drag_data(_at_position: Vector2) -> Variant
- func set_highlight(active: bool) -> void
- func _can_drop_data(_at_position: Vector2, data: Variant) -> bool
- func _drop_data(_at_position: Vector2, data: Variant) -> void

### GUI/journal_ui.gd
- func _unhandled_input(event: InputEvent) -> void
- func _ready()
- func _on_locale_changed()
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void
- func setup(p_journal_manager: Node) -> void
- func _on_journal_updated()
- func _populate_sections()
- func _on_section_selected(index: int)
- func _populate_topics(section_id: String)
- func find_item_by_metadata(list: ItemList, metadata_value: Variant) -> int
- func _on_topic_selected(index: int)

### GUI/location_details_panel.gd
- func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void
- func _ready() -> void
- func _setup_back_button() -> void
- func _on_back_pressed() -> void
- func _on_locale_changed() -> void
- func update_details(location_data: Variant) -> void

### GUI/location_display_item.gd
- func _ready() -> void
- func _on_gui_input(event: InputEvent) -> void
- func set_location_data(location_data: Dictionary) -> void

### GUI/locations_list_panel.gd
- func _init() -> void
- func _ready() -> void
- func update_locations(locations_data: Array) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void

### GUI/loot_details_panel.gd
- func _init() -> void
- func _ready() -> void
- func update_details(loot: Loot) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void

### GUI/morale_panel.gd
- func _ready() -> void
- func _on_locale_changed() -> void
- func setup(state: GameState, _config: GameSessionBuilder.Config) -> void
- func _connect_unit_signals(unit: Unit) -> void
- func _on_unit_data_changed(_unit: Unit = null) -> void
- func _on_willpower_changed(_unit: Unit) -> void
- func _ensure_controls_ready() -> void
- func update_morale_display() -> void
- func _safe_ratio(current: int, max_val: int) -> float
- func _update_labels(player_ratio: float, enemy_ratio: float, neutral_ratio: float) -> void
- func _update_label_tooltip(label: Label, units: Array, initial_max: int) -> void
- func _update_bars(player_ratio: float, player_max: int, enemy_ratio: float, enemy_max: int) -> void
- func _check_all_retreats(player_wp: int, enemy_wp: int, neutral_wp: int) -> void
- func _get_willpower_stats(units: Array) -> Dictionary
- func _check_retreat_condition(current_wp: int, initial_max_wp: int, condition_flag_name: String, trigger_signal: Signal, faction_label: String) -> void
- func faction_label_to_id(label: String) -> int
- func _recalculate_initial_max_willpower() -> void
- func reset_state(unit_manager: UnitManager = null) -> void

### GUI/round_info_panel.gd
- func _init() -> void
- func _ready() -> void
- func _on_locale_changed() -> void
- func update_round(current_round: int) -> void
- func update_turn(side: int) -> void
- func update_enabled(enabled: bool) -> void
- func update_turn_status(counts: Dictionary) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void

### GUI/task_details_panel.gd
- func _ready() -> void
- func _setup_back_button() -> void
- func _on_back_pressed() -> void
- func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void
- func _on_locale_changed() -> void
- func update_details(task_data) -> void

### GUI/task_display_item.gd
- func _ready() -> void
- func set_task_data(task_data: Dictionary) -> void

### GUI/task_list_item.gd
- func _ready() -> void
- func _on_gui_input(event: InputEvent) -> void
- func _setup_debug_button() -> void
- func _on_debug_button_pressed() -> void
- func _on_mouse_entered() -> void
- func _on_mouse_exited() -> void
- func update_task(task_data: Dictionary) -> void

### GUI/tasks_list_panel.gd
- func _ready() -> void
- func _on_locale_changed() -> void
- func update_tasks(grouped_tasks: Array) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void

### GUI/terrain_details_panel.gd
- func _ready() -> void
- func _on_locale_changed() -> void
- func update_details(terrain: TerrainTile, distance: String) -> void

### GUI/unit_details_panel.gd
- func _init() -> void
- func _ready() -> void
- func _on_locale_changed() -> void
- func update_details(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager) -> void
- func _handle_null_unit() -> void
- func _capture_unit_state(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager) -> Dictionary
- func _has_state_changed(state: Dictionary) -> bool
- func _apply_unit_details(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, state: Dictionary) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void
- func _update_basic_info(unit: Unit) -> void
- func _update_stats_display(unit: Unit, current_willpower: int) -> void
- func _update_stress_display(_current_stress: int) -> void
- func _update_movement_display(unit: Unit, current_moves: int, current_can_act: bool) -> void
- func _update_status_display(_current_stuck: bool) -> void
- func _update_attributes_display(unit: Unit) -> void
- func _update_inventory_display(unit: Unit) -> void

### GUI/weather_display_ui.gd
- func _ready()
- func _on_weather_changed(new_weather_attribute: WeatherAttribute)

### GUI/weather_panel.gd
- func _ready() -> void
- func _on_locale_changed() -> void
- func _on_pressures_changed(pressures: Array[String]) -> void
- func _on_forecast_changed(pressures: Array[String]) -> void
- func _update_ui(pressures: Array[String], is_forecast: bool) -> void
- func force_fit_content() -> void
- func update_compass(rotation_rad: float) -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void

## Gameplay

### Gameplay/animation_request_service.gd
- func setup(state: GameState, config: GameSessionBuilder.Config) -> void
- func set_tween_factory(factory: Callable) -> void
- func request_unit_move(unit: Node2D, coord: Vector2i, style_id: StringName = StyleIds.UNIT_MOVE) -> void
- func on_unit_moved(index: int, coord: Vector2i) -> void
- func request_feedback_float(node: Control, offset: Vector2, style_id: StringName = StyleIds.HUD_FEEDBACK, auto_free: bool = true) -> void
- func request_warning_flash(node: Control, style_id: StringName = StyleIds.HUD_WARNING) -> void
- func request_property_animation(target: Object, property: String, value, style_id: StringName = StyleIds.DEFAULT, on_complete: Callable = Callable()
- func _get_style(style_id: StringName) -> AnimationStyle
- func _create_tween_for(target: Object) -> Object
- func _connect_completion(tween: Object, request_id: StringName, payload: Dictionary) -> void
- func _get_effective_duration(base_duration: float) -> float

### Gameplay/camera_controller.gd
- func setup(state: GameState, config: GameSessionBuilder.Config) -> void
- func init_camera_snap() -> void
- func center_on_selected() -> void
- func on_unit_moved(index: int, _coord: Vector2i) -> void
- func get_rotation() -> float
- func toggle_free_cam() -> void
- func zoom(direction: int) -> void
- func handle_camera_input(event: InputEvent) -> void

### Gameplay/camera_handler.gd
- func setup(game_root: Node2D) -> void
- func init_camera_snap() -> void
- func rotate_camera(rotation_delta: int) -> void
- func zoom(direction: int) -> void
- func set_initial_rotation(rotation: float) -> void
- func center_on_position(pos: Vector2) -> void
- func set_free_cam(is_free: bool) -> void
- func is_free_cam() -> bool
- func get_camera_rotation() -> float
- func handle_camera_input(event: InputEvent) -> void
- func _unhandled_input(event: InputEvent) -> void
- func _apply_camera_rotation_from_step() -> void

### Gameplay/combat/combat_priority_profile.gd
- func get_weight(key: StringName) -> int

### Gameplay/commands/aid_ally_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/attack_unit_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/cancel_move_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/command_factory.gd
- static func _get_script_metadata(script: Script) -> Dictionary
- static func create_default_command_set() -> Dictionary
- static func create_command_by_id(cmd_id: GameConstants.Commands.CommandID) -> GameCommand
- static func get_command_metadata() -> Dictionary

### Gameplay/commands/command_history.gd
- static func push_snapshot(context: GameCommandContext) -> void
- static func pop_snapshot() -> void
- static func undo(context: GameCommandContext) -> bool

### Gameplay/commands/command_result.gd
- func _init(p_status: Status = Status.SUCCESS, p_message: String = "") -> void
- static func success(p_message: String = "") -> CommandResult
- static func failed(error: String = "Command failed") -> CommandResult
- static func invalid_context(missing: PackedStringArray = []) -> CommandResult
- static func invalid_payload(reason: String = "Invalid payload") -> CommandResult
- static func precondition_failed(reason: String = "Precondition failed") -> CommandResult
- func is_success() -> bool
- func is_failure() -> bool
- func get_description() -> String
- func get_error_message() -> String

### Gameplay/commands/command_validator.gd
- static func validate_context(context: GameCommandContext, required_fields: PackedStringArray) -> CommandResult
- static func validate_payload_exists(payload) -> CommandResult
- static func validate_payload_type(payload, expected_type: String) -> CommandResult
- static func validate_payload_dict_keys(payload: Dictionary, required_keys: PackedStringArray) -> CommandResult
- static func validate_int(value: int, min_val: int = -2147483648, max_val: int = 2147483647, name: String = "value") -> CommandResult
- static func validate_vector2i_in_bounds(coord: Vector2i, width: int, height: int) -> CommandResult
- static func validate_active_unit(context: GameCommandContext, unit_index: int) -> CommandResult
- static func type_string(t: int) -> String

### Gameplay/commands/confirm_move_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/convince_unit_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/explore_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/game_command.gd
- static func get_command_name() -> String
- static func get_command_description() -> String
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func execute(_context: GameCommandContext, _payload = null) -> CommandResult
- func get_required_context_fields() -> PackedStringArray
- func validate_context(context: GameCommandContext) -> CommandResult

### Gameplay/commands/game_command_context.gd
- func _init(
- func is_valid() -> bool
- func get_missing_dependencies() -> PackedStringArray
- func get_field(field_name: String)
- func get_grid_dimensions() -> Vector2i
- func get_selected_unit_index() -> int
- func get_selected_unit() -> Unit

### Gameplay/commands/input_command_router.gd
- func _init(context: GameCommandContext = null, commands: Dictionary = {}) -> void
- func set_context(context: GameCommandContext) -> void
- func set_commands(commands: Dictionary) -> void
- func register_command(id: GameConstants.Commands.CommandID, command: GameCommand) -> void
- func execute(id: GameConstants.Commands.CommandID, payload = null) -> CommandResult

### Gameplay/commands/joy_move_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/loot_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/move_action_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, action = null) -> CommandResult

### Gameplay/commands/move_to_coord_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult
- func _extract_coord(payload) -> Vector2i

### Gameplay/commands/primary_action_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/select_index_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/selection_cycle_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/talk_to_unit_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/toggle_enemy_range_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func execute(context: GameCommandContext, _payload = null) -> CommandResult
- func get_required_context_fields() -> PackedStringArray

### Gameplay/commands/toggle_free_cam_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, _payload = null) -> CommandResult

### Gameplay/commands/trapped_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/trigger_dialogue_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/undo_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, _payload = null) -> CommandResult

### Gameplay/commands/use_skill_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/commands/visit_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult
- func _resolve_visit_target_info(context: GameCommandContext, payload) -> Dictionary

### Gameplay/commands/wait_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, _payload = null) -> CommandResult

### Gameplay/commands/zoom_camera_command.gd
- static func _get_command_id() -> GameConstants.Commands.CommandID
- func get_required_context_fields() -> PackedStringArray
- func execute(context: GameCommandContext, payload = null) -> CommandResult

### Gameplay/default_game_session_service_factory.gd
- func create_services() -> Dictionary
- func _create_unit_controller() -> UnitController

### Gameplay/game_session.gd
- func _init(p_config: GameSessionBuilder.Config) -> void
- func initialize() -> void
- func _initialize_technical_systems() -> void
- func _attach_services() -> void
- func end_session() -> void
- func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void
- func set_unit_controlled_by_player(index: int, is_player: bool) -> void
- func handle_pause_state_changed(paused: bool) -> void
- func handle_hud_toggle(visible: bool) -> void
- func _update_terrain_overlay() -> void
- func disable_gameplay() -> void

### Gameplay/game_session_builder.gd
- func set_roster_loader(loader: RosterLoader) -> void
- func build(config: Config) -> GameState
- func _prepare_services(config: Config) -> Dictionary
- func _validate_required_services(services: Dictionary) -> void
- func _setup_core_systems(state: GameState, config: Config) -> void
- func _setup_input_and_hud(state: GameState, config: Config) -> void
- func _setup_hud(state: GameState, config: Config) -> HUDComponentFactory.Components
- func _setup_command_infrastructure(state: GameState, config: Config) -> void
- func _setup_dialogue_logic(state: GameState, config: Config) -> void
- func _register_observers(state: GameState, config: Config) -> void
- func _register_ui_signals(state: GameState) -> void
- func _register_task_dialogue_signals(state: GameState) -> void
- func _register_turn_and_task_signals(state: GameState) -> void
- func _register_combat_and_world_signals(state: GameState, config: Config) -> void
- func _register_visual_signals(state: GameState, config: Config) -> void
- func _create_game_state(services: Dictionary, config: Config) -> GameState
- func load_player_roster(provided_roster: PlayerRoster, save_manager: Node) -> PlayerRoster
- func load_enemy_roster(provided_roster: EnemyRoster) -> EnemyRoster
- func load_neutral_roster(provided_roster: NeutralRoster) -> NeutralRoster
- func _get_roster_loader() -> RosterLoader

### Gameplay/game_session_service_factory.gd
- func create_services() -> Dictionary

### Gameplay/game_state.gd
- func _init(p_services: Dictionary, p_tree_nodes: Array[Node] = []) -> void
- func get_tree_nodes() -> Array[Node]
- func get_hud() -> Hud

### Gameplay/gameplay.gd
- func _ready() -> void
- func _init_dependencies() -> void
- func _init_session() -> void
- func _setup_level_manager() -> void
- func _connect_game_signals() -> void
- func _finish_setup() -> void
- func _resolve_dependency(path: NodePath, label: String) -> Node
- func _on_quit_requested() -> void
- func set_turn_system_enabled(enabled: bool) -> void
- func set_level_and_rebuild(p_level: Level) -> void
- func _update_terrain_overlay() -> void
- func _disable_gameplay() -> void
- func _exit_tree() -> void

### Gameplay/hometown_progression_service.gd
- func _init(catalog: LevelCatalog, save_manager: SaveManager) -> void
- func get_all_level_ids() -> Array[String]
- func get_all_skits() -> Array[Skit]
- func sort_skits_by_level(skits: Array[Skit]) -> Array[Skit]
- func filter_skits_by_unseen(skits: Array[Skit]) -> Array[Skit]
- func filter_skits_by_unlocked(skits: Array[Skit]) -> Array[Skit]
- func queue_dialogue(dialogue_path: String) -> void
- func pop_skit() -> Skit
- func watch_skit() -> void
- func mark_skit_seen(skit_id: String) -> void

### Gameplay/inputs/combat_input_state.gd
- func handle_action(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult
- func handle_input(event: InputEvent) -> void

### Gameplay/inputs/input_binding_service.gd
- func apply_bindings(controls: Node, input_mapper: Node) -> void
- func save_bindings(action: String, keys: Array, joy_buttons: Array, mouse_buttons: Array) -> void
- func restore_defaults() -> void
- func _register_events(action: String, keys: Array, joy_buttons: Array, mouse_buttons: Array) -> void
- func _apply_from_controls(controls: Node, input_mapper: Node) -> void
- func _apply_action_group(controls: Node, input_mapper: Node, property_name: String, fallback: Array) -> void

### Gameplay/inputs/input_controller.gd
- func setup(state: GameState, config: GameSessionBuilder.Config, command_set: Dictionary = {}) -> void
- func apply_command_set(command_set: Dictionary = {}) -> void
- func _connect_signals() -> void
- func _unhandled_input(event: InputEvent) -> void
- func _on_move_requested(action: String) -> void
- func _on_selection_cycle_requested(direction: int) -> void
- func _on_select_index_requested(index: int) -> void
- func _on_free_cam_toggle_requested() -> void
- func _on_toggle_enemy_range_requested() -> void
- func _on_zoom_requested(direction: int) -> void
- func _on_joy_axis_held(axis: Vector2, _delta: float) -> void
- func _on_primary_action_at(screen_pos: Vector2) -> void
- func _on_secondary_action_at(screen_pos: Vector2) -> void
- func _on_wait_requested() -> void
- func _on_confirm_move_requested() -> void
- func _on_ui_nav_toggle_requested() -> void
- func _execute_command(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult
- func _register_input_actions() -> void
- func _default_command_set() -> Dictionary
- func set_ui_navigation_mode(enabled: bool) -> void
- func request_select_index(index: int) -> void
- func request_selection_cycle(direction: int) -> void
- func request_wait() -> void
- func register_input_actions() -> void
- func _mark_input_handled() -> void

### Gameplay/inputs/input_handler.gd
- func _ready() -> void
- func _notification(what: int) -> void
- func _physics_process(delta: float) -> void
- func _unhandled_input(event: InputEvent) -> void
- func _should_ignore_input(event: InputEvent) -> bool
- func _handle_auto_battle_toggle(event: InputEvent) -> bool
- func _handle_camera_interception(event: InputEvent) -> bool
- func _handle_core_gameplay_inputs(event: InputEvent) -> void
- func reset_joy_state() -> void
- func set_ui_navigation_mode(enabled: bool) -> void
- func refresh_action_cache() -> void
- func _handle_gameplay_actions(event: InputEvent) -> bool
- func _handle_selection_actions(event: InputEvent) -> bool
- func _handle_camera_actions(event: InputEvent) -> bool
- func _mark_input_handled() -> void
- func _event_matches_action(event: InputEvent, action: StringName) -> bool
- func _handle_joypad_motion(event: InputEvent) -> void
- func _process_joy_axis(delta: float) -> void
- func _handle_ui_nav_toggle(event: InputEvent) -> bool

### Gameplay/inputs/input_state.gd
- func _init(manager: Node, context: GameCommandContext, router: InputCommandRouter) -> void
- func enter() -> void
- func exit() -> void
- func handle_action(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult
- func handle_input(event: InputEvent) -> void

### Gameplay/interaction/interaction_rules.gd
- static func location_interaction_cost(danger: bool) -> Dictionary
- static func unit_talk_cost(actor: Unit, target: Unit) -> Dictionary

### Gameplay/map/display_orientation.gd
- static func from_string(name: String) -> DisplayOrientation.Orientation
- static func to_name(orientation: DisplayOrientation.Orientation) -> String

### Gameplay/map/grid_query_service.gd
- func setup(unit_manager: UnitManager, loot_manager: LootManager, terrain_map: TerrainMap, task_manager: TaskManager = null, grid: TileMapLayer = null) -> void
- func world_to_map(world_pos: Vector2) -> Vector2i
- func map_to_world(map_coord: Vector2i) -> Vector2
- func get_distance(a: Vector2i, b: Vector2i) -> int
- func snap_to_grid(node: Node2D) -> Vector2i
- func is_unit_at(coord: Vector2i, ignore_unit: Unit = null) -> bool
- func get_unit_at(coord: Vector2i) -> Unit
- func is_loot_at(coord: Vector2i) -> bool
- func get_loot_at(coord: Vector2i) -> Loot
- func get_terrain(coord: Vector2i) -> TerrainTile
- func is_passable(coord: Vector2i) -> bool
- func get_location_at(coord: Vector2i) -> Location
- func is_blocked(coord: Vector2i, ignore_unit: Unit = null) -> bool
- func get_all_at(coord: Vector2i) -> Dictionary
- func get_neighbors(coord: Vector2i) -> Array[Vector2i]
- func get_nearest_empty_coord(requested_coord: Vector2i, max_radius: int = 5) -> Vector2i

### Gameplay/map/grid_utility.gd
- static func find_nearest(origin: Vector2i, max_radius: int, predicate: Callable, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Vector2i

### Gameplay/map/grid_visuals.gd
- func _ready() -> void
- func setup_hex_shape(tile_size: Vector2, grid: Node2D = null) -> void
- func update_hover_indicator(mouse_pos: Vector2, grid: Node2D, _unit_manager: UnitManager, terrain_map = null) -> void
- func update_path_preview(mouse_pos: Vector2, grid: Node2D, unit_manager: UnitManager, terrain_map) -> void
- func update_range_indicator(grid: Node2D, unit_manager: UnitManager, terrain_map) -> void
- func update_terrain_overlay(grid: Node2D, terrain_map) -> void
- func toggle_enemy_range_view() -> void
- func is_enemy_range_visible() -> bool
- func update_enemy_range_overlay(unit_manager: UnitManager, terrain_map, grid: Node2D) -> void
- func update_dialogue_indicators(grid: Node2D, unit_manager: UnitManager, dialogue_service: DialogueActionService) -> void
- func _clear_children(node: Node) -> void
- func _try_draw_tentative_path_preview(unit: Unit, grid: Node2D, terrain_map) -> bool
- func _draw_hover_path_preview(unit: Unit, mouse_pos: Vector2, grid: Node2D, unit_manager: UnitManager, terrain_map) -> void
- func _draw_range_indicators(grid: Node2D, unit: Unit, unit_manager: UnitManager, reachable: Dictionary, start_cell: Vector2i) -> void
- func _draw_aoo_threats(grid: Node2D, unit: Unit, unit_manager: UnitManager, terrain_map) -> void
- func _get_threatened_hexes(unit_manager: UnitManager, terrain_map) -> Dictionary
- func _draw_threatened_hexes_overlay(threatened_hexes: Dictionary, grid: Node2D) -> void
- func _create_overlay_polygon(coord: Vector2i, color: Color, hex_points: PackedVector2Array, grid: Node2D) -> Polygon2D
- func _build_hex_points(tile_size: Vector2, grid: Node2D = null) -> PackedVector2Array
- func refresh_visuals(unit_manager: UnitManager, terrain_map, grid: Node2D) -> void
- func show_threatened_path_hex(coord: Vector2i, grid: Node2D) -> void

### Gameplay/map/hex_lib.gd
- static func get_distance(a: Vector2i, b: Vector2i, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> int
- static func get_neighbor_offsets(coord: Vector2i, axis: int) -> Array[Vector2i]
- static func map_to_axial(map_coord: Vector2i, axis: int) -> Vector2i
- static func axial_to_map(axial_coord: Vector2i, axis: int) -> Vector2i
- static func is_in_bounds(coord: Vector2i, width: int, height: int) -> bool
- static func key_of(coord: Vector2i) -> String

### Gameplay/map/hex_navigator.gd
- func get_direction_map(coord: Vector2i, grid) -> Dictionary
- func cache_analog_vectors(grid) -> void
- func map_action_by_camera(action: String, coord: Vector2i, rotation: float, grid) -> String
- func get_action_from_joy_axis(axis: Vector2, rotation: float, coord: Vector2i, grid) -> String
- func _get_closest_action(target_vec: Vector2) -> String
- static func can_reach_coord(reachable_coords: Array, target_coord: Vector2i) -> bool
- static func get_hex_distance(a: Vector2i, b: Vector2i, offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> int
- static func get_neighbor_offsets(coord: Vector2i, offset_axis: int) -> Array[Vector2i]

### Gameplay/map/map_controller.gd
- func setup(grid: TileMapLayer) -> void
- func get_terrain_map() -> TerrainMap
- func get_grid() -> TileMapLayer
- func on_loot_added(loot: Loot, coord: Vector2i) -> void
- func configure_tileset() -> void
- func build_grid(width: int, height: int) -> void

### Gameplay/map/move_controller.gd
- func _ready()
- func setup(state: GameState, config: GameSessionBuilder.Config, request_validator: MoveRequestValidator = null, execution_service: MoveExecutionService = null, threat_warning_service: ThreatWarningService = null) -> void
- func update_grid_dimensions(width: int, height: int) -> void
- func request_move(action: String) -> void
- func request_move_tentative(action: String) -> void
- func request_move_to_coord(target_coord: Vector2i) -> bool
- func confirm_move() -> void
- func cancel_move() -> void
- func cancel_tentative_move_for_index(index: int) -> void
- func force_action_menu_update() -> void
- func is_move_locked() -> bool
- func _release_move_lock_deferred() -> void
- func _release_move_lock() -> void
- func _is_move_blocked() -> bool
- func _reset_warnings() -> void
- func _validate_manager_state() -> bool
- func _handle_existing_tentative_move(unit: Unit, target_coord: Vector2i, selected_idx: int) -> bool
- func _check_post_move_actions(selected_idx: int, unit: Unit, terrain_map) -> void
- func _should_abort_move() -> bool
- func _get_active_unit_context() -> Dictionary
- func _prepare_move_operation(reset_warnings: bool) -> Dictionary
- func _prepare_confirmation_operation(action_name: String) -> Dictionary
- func _execute_direction_move(unit: Unit, index: int, action: String) -> void
- func _execute_tentative_direction_move(unit: Unit, index: int, action: String) -> void
- func _execute_coordinate_move(unit: Unit, index: int, target_coord: Vector2i) -> bool
- func _validate_tentative_move_exists(unit: Unit, action_name: String) -> bool
- func _handle_threat_confirmation() -> bool
- func _finalize_move(unit: Unit, index: int) -> void
- func _perform_cancellation(unit: Unit, index: int) -> void
- func _on_weather_effect_applied(weather_info: Dictionary)
- func _on_unit_selection_changed(new_index: int) -> void

### Gameplay/map/move_execution_service.gd
- func execute_move(unit_controller, task_controller, unit, selected_idx: int, destination: Vector2i, cost: int) -> void
- func finalize_tentative_move(unit_controller, task_controller, unit: Unit, selected_idx: int, terrain_map) -> void
- func evaluate_post_move(unit, terrain_map, unit_manager, selected_idx: int, action_manager = UnitActionManager) -> Dictionary

### Gameplay/map/move_request_validator.gd
- func validate_direction_move(unit_manager, hex_navigator, map_controller, grid: Node2D, selected_idx: int, unit, action: String, _grid_width: int, _grid_height: int, wind_direction: Vector2, wind_intensity: float) -> Dictionary
- func _resolve_next_coord(current: Vector2i, action: String, hex_navigator, grid: Node2D) -> Vector2i
- func _validate_basic_movement(next: Vector2i, selected_idx: int, terrain_map, unit_manager) -> String
- func _calculate_move_cost(current: Vector2i, next: Vector2i, terrain_map, grid: Node2D, wind_direction: Vector2, wind_intensity: float) -> int
- func validate_coordinate_move(unit, unit_manager, map_controller, selected_idx: int, target_coord: Vector2i, grid_width: int, grid_height: int, wind_direction: Vector2, wind_intensity: float) -> Dictionary

### Gameplay/map/movement_range_calculator.gd
- func compute(start: Vector2i, movement_points: int, terrain_map, pass_through_blockers: Dictionary = {}) -> Dictionary
- func _validate_compute_inputs(start: Vector2i, movement_points: int, terrain_map) -> bool
- func _process_compute_node(coord: Vector2i, terrain_map, movement_points: int, best_cost: Dictionary, next_frontier: Array[Vector2i], pass_through_blockers: Dictionary = {}) -> void
- func _can_enter_neighbor_compute(neighbor: Vector2i, terrain_map) -> bool
- func find_path(target_coord: Vector2i, start_coord: Vector2i, reachable: Dictionary, terrain_map, movement_budget: int = -1, threatened_hexes: Dictionary = {}, blocked_hexes: Dictionary = {}) -> Array[Vector2i]
- func _pop_best_frontier_entry(frontier: Array) -> Dictionary
- func _is_valid_neighbor_for_path(neighbor: Vector2i, _target_coord: Vector2i, reachable: Dictionary, terrain_map, blocked_hexes: Dictionary) -> bool
- func _process_path_neighbor(neighbor: Vector2i, current_coord: Vector2i, current_entry: Dictionary, terrain_map, threatened_hexes: Dictionary, budget_limit: int, came_from: Dictionary, cost_so_far: Dictionary, steps_so_far: Dictionary, threat_so_far: Dictionary, frontier: Array) -> void
- func _reconstruct_path(came_from: Dictionary, start_coord: Vector2i, target_coord: Vector2i) -> Array[Vector2i]

### Gameplay/map/movement_range_service.gd
- static func calculate_reachable_state(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, unit_index: int = -1) -> ReachableState
- static func find_path(start: Vector2i, target: Vector2i, budget: int, terrain_map: TerrainMap, unit_manager: UnitManager = null, unit_index: int = -1) -> Array[Vector2i]

### Gameplay/map/reachable_state.gd
- static func create_empty() -> ReachableState

### Gameplay/map/terrain_map.gd
- func set_offset_axis(axis: int) -> void
- func get_offset_axis() -> int
- func load_from_rows(rows: Array, width: int = -1, height: int = -1) -> void
- func is_within_bounds(coord: Vector2i) -> bool
- func get_terrain(coord: Vector2i) -> TerrainTile
- func is_passable(coord: Vector2i) -> bool
- func get_movement_cost(coord: Vector2i) -> int
- func get_neighbors(coord: Vector2i) -> Array[Vector2i]
- func get_version() -> int
- func get_code(coord: Vector2i) -> String
- func get_color_for_code(code: String) -> Color
- func get_all_terrain_colors() -> Dictionary
- func _clear_tiles() -> void
- func _get_code(coord: Vector2i) -> String

### Gameplay/narrative/dialogue/dialogue_action_service.gd
- func setup(state: GameState, config: GameSessionBuilder.Config) -> void
- func _on_flag_changed(flag_name: String, value: Variant) -> void
- func _get_grid_axis() -> int
- func set_level(level: Level) -> void
- func prepare_for_level(level: Level) -> void
- func register_triggers(triggers: Array[DialogueTrigger]) -> void
- func append_dialogue_actions(actions: Array[UnitAction], unit: Unit, _um: UnitManager) -> void
- func get_trigger_at(coord: Vector2i) -> DialogueTrigger
- func trigger_at_coord(coord: Vector2i, initiator_unit: Unit = null) -> CommandResult
- func handle_dialogue_request(id_or_path: String, unit_index: int = -1) -> void
- func _start_direct_dialogue(resource_path: String, initiator_index: int) -> void
- func set_autoplay_enabled(enabled: bool) -> void
- func set_autoplay_delay(delay: float) -> void
- func set_text_speed(speed: float) -> void
- func is_dialogue_active() -> bool
- func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult
- func _load_dialogue_resource(path: String) -> Resource
- func _on_dialogue_finished() -> void
- func _hide_hud_before_dialogue() -> void
- func _show_hud_after_dialogue() -> void
- func _setup_dialogue_state(initiator_index: int, target_index: int) -> void
- func _get_character_states() -> Dictionary
- func _mark_dialogue_seen_globally(flag_id: StringName) -> void
- func _resolve_level_identifier(level: Level) -> StringName

### Gameplay/narrative/dialogue/dialogue_state.gd
- func has_flag(flag_name: String) -> bool
- func set_flag(flag_name: String, value: Variant) -> void
- func get_character_stat(char_name: String, stat_name: String, default: Variant = null) -> Variant
- func get_character(char_name: String) -> Dictionary

### Gameplay/narrative/dialogue/dialogue_trigger.gd
- func configure_from_entry(new_entry: LevelDialogueEntry) -> void
- func set_group(group: DialogueTriggerGroup) -> void
- func get_dialogue_id() -> StringName
- func get_action_label(partner_display_name: String) -> String
- func get_dialogue_resource(cache: Dictionary) -> DialogueResource
- func matches_initiator(target) -> bool
- func matches_partner(unit: Unit) -> bool
- func mark_seen(from_group := false) -> void
- func reset_seen() -> void
- func requires_initiator_action() -> bool
- func allows_partner_initiation() -> bool
- func assign_coord_on_grid(grid: TileMapLayer) -> void
- func _matches_role(target, role_name: StringName) -> bool
- func has_journal() -> bool
- func get_journal_entry_id() -> StringName
- func get_journal_section_id() -> String
- func get_journal_topic_id() -> String
- func get_journal_notes() -> String
- func get_journal_flag_name() -> StringName

### Gameplay/narrative/dialogue/dialogue_trigger_evaluator.gd
- func setup(unit_manager: UnitManager, grid_axis: int) -> void
- func set_grid_axis(axis: int) -> void
- func is_trigger_available(trigger: DialogueTrigger, active_flag: StringName) -> bool
- func append_dialogue_actions(
- func collect_partner_indices(trigger: DialogueTrigger, initiator_index: int, initiator_coord: Vector2i) -> Array[int]
- func collect_initiator_indices(trigger: DialogueTrigger, partner_index: int, partner_coord: Vector2i) -> Array[int]
- func can_proceed_without_partner(trigger: DialogueTrigger) -> bool
- func are_coords_adjacent(a: Vector2i, b: Vector2i) -> bool
- func build_dialogue_action(trigger: DialogueTrigger, initiator_index: int, partner_index: int, label: String) -> UnitAction

### Gameplay/narrative/dialogue/dialogue_trigger_group.gd
- func _init(id: StringName = StringName("")
- func register_trigger(trigger) -> void
- func mark_seen() -> void
- func reset() -> void

### Gameplay/narrative/dialogue/dialogue_trigger_manager.gd
- func setup(save_manager: Node) -> void
- func register_triggers(triggers: Array[DialogueTrigger]) -> void
- func get_trigger(dialogue_id: StringName) -> DialogueTrigger
- func get_all_triggers() -> Array
- func get_trigger_at(coord: Vector2i) -> DialogueTrigger
- func mark_seen(trigger: DialogueTrigger) -> void
- func _cleanup_registered_triggers() -> void
- func _load_seen_flags() -> void
- func _save_seen_flags() -> void
- func clear_triggers() -> void

### Gameplay/narrative/journal/journal_data.gd
- func _init()
- func add_section(section: JournalSection)
- func add_topic(topic: JournalTopic)
- func add_entry(entry: LevelJournalEntry)
- func has_entry(entry_id: String) -> bool
- func replace_entry(entry: LevelJournalEntry)
- func get_section(section_id: String) -> JournalSection
- func get_topic(topic_id: String) -> JournalTopic
- func get_entry(entry_id: String) -> LevelJournalEntry
- func get_unlocked_topics_in_section(section_id: String) -> Array[JournalTopic]
- func get_unlocked_entries_in_topic(topic_id: String) -> Array[LevelJournalEntry]
- func get_all_unlocked_entries() -> Dictionary

### Gameplay/narrative/journal/journal_section.gd
- func _init(p_id: String = "", p_title: String = "New Section")

### Gameplay/narrative/journal/journal_topic.gd
- func _init(p_id: String = "", p_title: String = "New Topic", p_section_id: String = "")

### Gameplay/narrative/task/defeat_enemies_task.gd
- func handle_event(type: String, data: Dictionary) -> void

### Gameplay/narrative/task/game_objective_controller.gd
- func setup(task_manager_source: TaskManager, unit_manager: UnitManager) -> void
- func check_location_progress() -> void
- func is_task_reached() -> bool
- func process_turn_progress() -> void
- func _on_task_completed(_index: int, _faction: int, _unit: Unit = null) -> void
- func reset_task_state() -> void
- func get_target_task(index: String) -> Task
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void
- func create_target_texture(primary: Color, secondary: Color) -> Texture2D

### Gameplay/narrative/task/objective.gd
- func _init(p_objective_id: String = "", p_title: String = "Objective", p_description: String = "", p_starting_stage: Stage = null, p_level: Level = null) -> void
- func start_objective(level_resource: Level) -> void
- func handle_event(type: String, data: Dictionary) -> void
- func _transition_to_stage(stage_res: Stage) -> void
- func _on_stage_completed(next_stage: Stage) -> void
- func _complete_objective() -> void
- func _fail_objective() -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/narrative/task/stage.gd
- func start_stage(context_target: Unit = null) -> void
- func handle_event(type: String, data: Dictionary) -> void
- func _on_task_completed(faction: int, unit: Unit, task: Task) -> void
- func advance() -> void
- func _on_task_failed(task: Task) -> void
- func _on_task_progress_changed(_current: int, _required: int, faction: int, task: Task) -> void
- func _are_faction_required_tasks_complete(faction: int) -> bool
- func _are_all_required_tasks_complete() -> bool
- func end_stage() -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/narrative/task/task.gd
- func initialize(target: Unit = null) -> void
- func handle_event(type: String, data: Dictionary) -> void
- func _apply_progress(progress: int, actor: Unit, data: Dictionary, type: String) -> void
- func _apply_duration_progress(data: Dictionary) -> void
- func _complete_task(faction: int, target: Object = null, completed_event: String = "") -> void
- func force_complete(faction: int = -1) -> void
- func _fail_task() -> void
- func cancel() -> void
- func get_progress_ratio() -> float
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void
- func can_be_worked_on_by(unit: Unit, from_coord: Vector2i = GameConstants.INVALID_COORD) -> bool
- func _can_work_filters(unit: Unit, from_coord: Vector2i) -> bool
- func _coord_matches_requirement(unit: Unit, from_coord: Vector2i, coord: Vector2i, kind) -> bool

### Gameplay/narrative/task/task_action_provider.gd
- func append_task_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i) -> void
- func _add_task_action(actions: Array[UnitAction], task: Task, action_origin: Vector2i, unit: Unit = null) -> void

### Gameplay/narrative/task/task_condition_handler.gd
- func setup(task_manager: TaskManager, unit_manager: UnitManager) -> void
- func check_objective_failed(objective: Resource) -> bool
- func get_player_units() -> Array[Unit]
- func handle_inventory_check(objective: Resource, player_units: Array[Unit]) -> void

### Gameplay/narrative/task/task_controller.gd
- func setup(state: GameState) -> void
- func _connect_task_manager_signals() -> void
- func finish_setup() -> void
- func bootstrap_level(current_level: Level) -> void
- func activate_initial_stage() -> void
- func set_level(current_level: Level) -> void
- func handle_event(event_type: String, params: Dictionary = {}) -> void
- func on_unit_defeated(unit: Unit, attacker: Unit = null) -> void
- func _on_stage_completed(_next_stage: Stage, completing_stage: Stage) -> void
- func _on_stage_failed(failing_stage: Stage) -> void
- func on_task_completed(index: int, faction: int, unit: Unit) -> void
- func _grant_mid_stage_reward(reward: TaskReward, unit: Unit, faction: int) -> void
- func _on_objective_updated(objective: Resource) -> void
- func _on_objective_completed(_objective: Resource) -> void
- func _on_objective_failed(_objective: Resource) -> void
- func on_round_changed(current_round: int) -> void
- func _gather_round_requirements(active_tasks: Array) -> Dictionary
- func _collect_faction_data(needs_by_faction: Dictionary) -> Dictionary
- func check_objective_conditions() -> void
- func check_inventory_objectives(player_units: Array[Unit]) -> void
- func _check_defeat_conditions(stage: Stage) -> void
- func _grant_end_of_level_rewards() -> void
- func _handle_stage_spawns(stage: Resource) -> void
- func _update_turn_blocking() -> void
- func is_narrative_blocking() -> bool
- func is_task_reached() -> bool
- func is_game_over() -> bool
- func reset_task_state() -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void
- func get_task_by_id(task_id: String) -> Task
- func get_task_info(task_id: String) -> Dictionary
- func get_task_at_coord(coord: Vector2i) -> Dictionary
- func _transform_task_to_info(task: Task) -> Dictionary
- func _on_dialogue_finished(_flag: StringName = &"") -> void

### Gameplay/narrative/task/task_dialogue_handler.gd
- func setup(state) -> void
- func queue_stage_dialogues(stage: Resource, dialogue_type: String) -> void
- func queue_task_dialogues(stage: Resource, dialogue_type: String) -> void
- func process_queue() -> void
- func on_dialogue_finished() -> void
- func is_queue_empty() -> bool
- func is_processing() -> bool
- func get_queue_contents() -> String
- func _add_to_queue(path: String) -> void
- func _resolve_dialogue_path(dialogue_id: String, stage: Resource) -> String

### Gameplay/narrative/task/task_manager.gd
- func setup(state: GameState) -> void
- func prepare_objective(current_level: Level, level_objective: Objective) -> void
- func start_active_objective() -> void
- func set_level_and_objective(current_level: Level, level_objective: Objective) -> void
- func register_unit(unit: Unit) -> void
- func register_location(location: Location) -> void
- func _on_loot_added(loot: Loot, _coord: Vector2i) -> void
- func _on_loot_removed(loot: Loot) -> void
- func register_loot(loot_node: Loot) -> void
- func get_active_objective() -> Objective
- func get_location_at(coord: Vector2i) -> Location
- func get_loot_at(coord: Vector2i) -> Loot
- func _on_target_interacted(unit: Unit, context: Dictionary, target: Target) -> void
- func _on_unit_moved(index: int, coord: Vector2i) -> void
- func _on_objective_updated(_objective: Objective) -> void
- func _on_objective_completed() -> void
- func _on_objective_failed() -> void
- func _check_stage_spawns() -> void
- func _spawn_location(_spawn_data: Dictionary) -> void
- func _on_game_action(action: Dictionary) -> void
- func get_task_for_target(target: Target) -> Task
- func get_task_by_id(task_id: String) -> Task
- func debug_complete_task(task_id: String) -> void
- func _debug_eliminate_faction(faction: int) -> void
- func get_active_tasks_for_target(target: Target) -> Array[Task]
- func _on_task_completed_relay(task: Task, faction: int, unit: Unit) -> void
- func _on_task_failed_relay(task: Task) -> void
- func _on_task_updated_relay(task: Task, faction: int) -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/narrative/task/task_processor.gd
- static func is_event_type_supported(task, type: String) -> bool
- static func is_event_processed(task, type: String, data: Dictionary) -> bool
- static func validate_interaction_data(task, type: String, data: Dictionary) -> bool
- static func matches_any_filter(task, type: String, data: Dictionary) -> bool
- static func filter_matches(task, filter, type: String, data: Dictionary) -> bool
- static func process_move_explore(task, _type: String, data: Dictionary) -> bool
- static func process_ability_used(task, _type: String, data: Dictionary) -> bool
- static func process_dialogue_started(task, _type: String, data: Dictionary) -> bool
- static func process_unit_defeated(task, _type: String, data: Dictionary) -> bool
- static func process_round_changed(task, data: Dictionary) -> bool
- static func duration_condition_holds(task, data: Dictionary) -> bool
- static func calculate_event_progress(task, actor: Unit, data: Dictionary, type: String) -> int
- static func get_best_attribute_name(actor: Unit) -> String
- static func to_vector2i(value) -> Vector2i

### Gameplay/narrative/task/task_stage_spawner.gd
- func _init(state: GameState) -> void
- func handle_stage_spawns(stage: Resource) -> bool
- func _spawn_stage_units(stage: Resource, grid: TileMapLayer) -> bool
- func _spawn_stage_loot(stage: Resource, grid: TileMapLayer) -> bool
- func _spawn_stage_locations(stage: Resource, grid: TileMapLayer) -> bool
- func _spawn_stage_dialogue_triggers(stage: Resource, grid: TileMapLayer) -> bool

### Gameplay/narrative/task/task_validator.gd
- func validate_item_target(task: Task, world: Dictionary) -> bool
- func validate_location_target(task: Task, world: Dictionary) -> bool
- func validate_unit_target(task: Task, world: Dictionary) -> bool

### Gameplay/roster/inventory_service.gd
- static func handle_item_transfer(item: InventoryItem, source_unit: Unit, target_unit: Unit, roster: PlayerRoster) -> void
- static func handle_item_swap(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit, roster: PlayerRoster) -> void
- static func _can_accept_item_swap(unit: Unit, item_coming_in: InventoryItem, item_going_out: InventoryItem) -> bool
- static func auto_equip_roster(roster: PlayerRoster, loaded_units: Array[Unit]) -> void
- static func save_roster_state(roster: PlayerRoster, loaded_units: Array[Unit]) -> void
- static func _get_highest_stat(unit: Unit) -> String
- static func _get_unit_item_count(unit: Unit) -> int

### Gameplay/roster/player_roster.gd
- func update_roster(active_units: Array[Unit], permadeath: bool = true) -> void
- func _build_active_entries(active_units: Array[Unit]) -> Dictionary
- func _merge_inactive_entries(current_entries: Array[Dictionary], active_counts: Dictionary) -> Array[Dictionary]
- func _get_previous_entries() -> Array[Dictionary]
- func _sync_units_from_entries() -> void
- func add_to_stash(items: Array[InventoryItem]) -> void
- func clear_stash() -> void
- func get_remaining_location_titles() -> PackedStringArray
- func set_remaining_location_titles(titles: PackedStringArray) -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/roster/roster_loader.gd
- func load_player_roster(provided_roster: PlayerRoster, save_manager: Node, fallback_path: String = DEFAULT_PLAYER_ROSTER_PATH) -> PlayerRoster
- func load_enemy_roster(provided_roster: EnemyRoster, fallback_path: String = DEFAULT_ENEMY_ROSTER_PATH) -> EnemyRoster
- func load_neutral_roster(provided_roster: NeutralRoster, fallback_path: String = DEFAULT_NEUTRAL_ROSTER_PATH) -> NeutralRoster
- func _load_saved_player_roster(save_manager: Node) -> PlayerRoster
- func _load_player_roster_resource(path: String) -> PlayerRoster
- func _load_unit_roster(provided_roster: UnitRoster, fallback_path: String, roster_class: GDScript, roster_label: String, resource_label: String, warn_on_empty := true) -> UnitRoster
- func _populate_roster_from_resource(target_roster: UnitRoster, path: String, roster_class: GDScript, roster_label: String, resource_label: String) -> void
- func _build_core_player_roster() -> PlayerRoster
- func _instantiate_core_units(roster: PlayerRoster) -> void
- func _add_starting_item_set(roster: PlayerRoster) -> void

### Gameplay/roster/roster_persistence.gd
- static func unit_to_entry(unit: Unit) -> Dictionary
- static func entry_to_scene(entry: Dictionary) -> PackedScene
- static func entry_to_unit(entry: Dictionary) -> Unit
- static func _set_owner_recursive(node: Node, p_owner: Node) -> void
- static func scene_to_entry(scene: PackedScene) -> Dictionary

### Gameplay/roster/unit_roster.gd
- func get_unit_scene(index: int) -> PackedScene
- func get_random_unit_scene() -> PackedScene
- func get_units() -> Array[Unit]

### Gameplay/skills/heal_skill.gd
- func activate(user: Unit, target: Variant) -> bool

### Gameplay/skills/skill.gd
- func activate(user: Unit, target: Variant) -> bool
- func on_equip(user: Unit) -> void
- func on_unequip(user: Unit) -> void
- func get_tooltip_text() -> String

### Gameplay/skills/weather_change_skill.gd
- func activate(user: Unit, _target: Variant) -> bool
- func get_tooltip_text() -> String

### Gameplay/targets/components/action_points_component.gd
- func _init() -> void
- func set_owner_unit(unit: Unit) -> void
- func refresh_for_new_round() -> void
- func has_move_available() -> bool
- func has_action_available() -> bool
- func has_reaction_available() -> bool
- func get_reactions_available() -> int
- func get_max_reactions() -> int
- func set_max_reactions(value: int) -> void
- func consume_move(cost: int = 1) -> void
- func consume_action() -> void
- func consume_reaction() -> void
- func adjust_reactions_available(delta: int) -> void
- func adjust_remaining_movement(delta: int) -> void
- func block_movement_this_turn() -> void
- func block_action_this_turn() -> void
- func get_remaining_movement_points() -> int
- func get_movement_points() -> int
- func set_movement_points(value: int) -> void
- func get_willpower() -> int
- func set_willpower(value: int) -> void
- func get_max_willpower() -> int
- func set_max_willpower(value: int) -> void

### Gameplay/targets/components/inventory_component.gd
- func setup(owner: Node, _attributes: Node = null, inventory: UnitInventory = null) -> void
- func _find_or_create_inventory(owner: Node) -> UnitInventory
- func cleanup() -> void
- func get_inventory() -> UnitInventory
- func equip_item(item: InventoryItem) -> bool
- func unequip_item(item: InventoryItem) -> bool
- func add_item_to_inventory(item: InventoryItem) -> bool
- func remove_item_from_inventory(item: InventoryItem) -> bool
- func get_equipped_items() -> Array[InventoryItem]
- func has_item_by_id(origin_id: String) -> bool
- func clear_items() -> void
- func clear() -> void

### Gameplay/targets/components/movement_range_cache.gd
- func setup(get_movement_points: Callable, unit_manager: UnitManager = null) -> void
- func set_unit_manager(unit_manager: UnitManager) -> void
- func compute_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1, pass_through_blockers: Dictionary = {}) -> Dictionary
- func invalidate() -> void
- func cleanup() -> void

### Gameplay/targets/components/target_interaction_handler.gd
- func _init(unit: Unit) -> void
- func set_loot_manager(manager: LootManager) -> void
- func set_task_manager(manager: TaskManager) -> void
- func set_location_service(service: LocationService) -> void
- func set_unit_manager(manager: UnitManager) -> void
- func interact(target: Target) -> bool
- func loot(loot_coord: Vector2i) -> bool
- func _handle_trapped_loot(loot_node: Loot, loot_coord: Vector2i) -> bool
- func _collect_items_from_node(loot_node: Loot, inventory: UnitInventory) -> bool
- func _try_loot_item(item: InventoryItem, should_auto_equip: bool) -> bool
- func _cleanup_loot_node(loot_node: Loot) -> void
- func explore(target_task: Task, target_node: Target = null, attribute: String = "") -> bool
- func visit_location(location: Location) -> bool
- func convince_unit(target_unit: Unit) -> bool
- func fight_unit(target_unit: Unit) -> bool
- func _auto_loot_from_node(loot_node: Loot, loot_coord: Vector2i) -> bool
- func _try_interaction_detailed(interaction_callable: Callable) -> bool
- func _try_interaction(interaction_callable: Callable) -> bool

### Gameplay/targets/components/unit_combat_behavior.gd
- func _init(unit: Unit) -> void
- func set_combat_system(combat_system: CombatSystem) -> void
- func attack(target: Unit, attribute_index: int = 0) -> bool
- func aid_ally(ally: Unit, attribute_index: int = 0) -> bool
- func _is_adjacent_to_target(target: Unit) -> bool

### Gameplay/targets/components/unit_death_handler.gd
- func _init(unit: Unit) -> void
- func set_unit_manager(manager: UnitManager) -> void
- func set_loot_manager(manager: LootManager) -> void
- func set_animation_service(service) -> void
- func die() -> void
- func is_dying() -> bool
- func _drop_loot() -> void
- func _should_drop_standard_loot() -> bool
- func _get_current_difficulty() -> String
- func _drop_quest_items(inventory: UnitInventory) -> void
- func _route_remaining_items(inventory: UnitInventory) -> void
- func _drop_inventory() -> void
- func _finalize_death() -> void

### Gameplay/targets/components/unit_loyalty_component.gd
- func _init(p_unit: Unit) -> void
- func is_faction_leader(p_faction: int) -> bool
- func set_faction_leader(p_faction: int, enabled: bool) -> void
- func reset_neutral_loyalty() -> void
- func set_neutral_loyalty(target_faction: int, allow_rally: bool = true, rally_targets: Array = []) -> void
- func _can_change_loyalty() -> bool
- func _normalize_faction(target_faction: int) -> int
- func _rally_allies(rally_targets: Array) -> void
- func _can_rally_ally(ally: Variant) -> bool
- func apply_persuasion(target_faction: int) -> void
- func handle_attack_from(attacker: Unit) -> void

### Gameplay/targets/components/unit_movement_behavior.gd
- func _init(unit: Unit = null) -> void
- func setup(unit: Unit) -> void
- func has_move_available() -> bool
- func consume_move(cost: int = 1) -> void
- func adjust_remaining_movement(delta: int) -> void
- func block_movement_this_turn() -> void
- func get_remaining_movement_points() -> int
- func get_max_movement_points() -> int
- func compute_movement_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1, pass_through_blockers: Dictionary = {}) -> Dictionary
- func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]
- func get_path_to_adjacent(target_pos: Vector2i, terrain_map, unit_manager: UnitManager) -> Array[Vector2i]
- func get_blocked_hexes(unit_manager: UnitManager, target_coord: Vector2i = Vector2i.MAX) -> Dictionary
- func get_threatened_hexes(unit_manager: UnitManager, terrain_map) -> Dictionary
- func _can_unit_threaten(viewer: Unit, other: Unit) -> bool
- func _add_unit_threats(attacker: Unit, attacker_index: int, unit_manager: UnitManager, terrain_map, axis: int, threatened_hexes: Dictionary) -> void
- func process_path_for_opportunity_attacks(path: Array[Vector2i], terrain_map) -> Dictionary
- func _resolve_aoo_at_pos(current_pos: Vector2i, next_pos: Vector2i, attackers: Array, context: Dictionary, terrain_map) -> bool
- func _can_trigger_aoo(attacker: Unit, pos_leaving: Vector2i, unit_manager: UnitManager, terrain_map) -> bool
- func _get_opportunity_attack_context() -> Dictionary
- func _select_best_attack_attribute(unit: Unit) -> int
- func set_free_roam_mode(enabled: bool) -> void
- func is_free_roam_mode() -> bool
- func refresh_for_new_round() -> void
- func get_start_of_turn_grid_coord() -> Vector2i
- func set_start_of_turn_grid_coord(coord: Vector2i) -> void
- func set_tentative_move(coord: Vector2i, path: Array[Vector2i], cost: int) -> void
- func clear_tentative_move() -> void
- func get_tentative_grid_coord() -> Vector2i
- func has_tentative_move() -> bool
- func get_tentative_path() -> Array[Vector2i]
- func get_tentative_cost() -> int
- func move_along_path(path: Array) -> void
- func on_enter_terrain(terrain: Variant) -> void
- func get_pass_through_blockers(unit_manager: UnitManager) -> Dictionary
- func get_stop_blockers(unit_manager: UnitManager, target_coord: Vector2i = Vector2i.MAX) -> Dictionary

### Gameplay/targets/components/unit_query_service.gd
- func _init(unit: Unit) -> void
- func has_nearby_units(units: Array, detection_range: float) -> bool
- func get_units_in_range(units: Array, detection_range: float) -> Array[Unit]
- func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array[Unit]
- func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: int) -> Array[Unit]
- func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]
- func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array[Unit]
- func list_locations_in_range(locations: Array, detection_range: float) -> Array
- func invalidate_cache() -> void
- func get_hostile_units() -> Array[Unit]
- func get_friendly_units() -> Array[Unit]
- func get_neutral_units() -> Array[Unit]
- func get_all_units_categorized() -> Dictionary
- func get_adjacent_units_categorized(adjacency_range: float = 1.5) -> Dictionary
- func get_persuadable_neutrals() -> Array[Unit]
- func get_closest_unit(units: Array) -> Unit
- func get_unit_at(coord: Vector2i) -> Unit
- func get_loot_at(coord: Vector2i) -> Loot
- func get_location_at(coord: Vector2i) -> Location
- func is_occupied(coord: Vector2i) -> bool
- func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()
- func _get_relationship_units(type: String) -> Array[Unit]
- func _get_axis() -> int
- func _get_or_build(cache: Array, dirty_flag_var: String, builder_callable: Callable) -> Array

### Gameplay/targets/components/unit_status_component.gd
- func _init(unit: Unit) -> void
- func apply_status_effect(effect: StringName) -> void
- func has_status_effect(effect: StringName) -> bool
- func clear_status_effect(effect: StringName) -> void
- func get_status_effects() -> Array

### Gameplay/targets/discovery/combat_discovery.gd
- static func get_adjacent_targets(unit: Unit) -> Dictionary
- static func get_all_targets(unit: Unit) -> Dictionary

### Gameplay/targets/discovery/convince_discovery.gd
- static func is_convincable(unit: Unit) -> bool
- static func split_targets(enemies: Array) -> Dictionary

### Gameplay/targets/discovery/dialogue_discovery.gd
- static func get_potential_partners(unit_manager: UnitManager, trigger: DialogueTrigger, initiator: Unit, initiator_coord: Vector2i, grid_axis: int) -> Array[Unit]
- static func get_potential_initiators(unit_manager: UnitManager, trigger: DialogueTrigger, partner: Unit, partner_coord: Vector2i, grid_axis: int) -> Array[Unit]
- static func has_active_dialogue(initiator: Unit, partner: Unit, triggers: Array, active_flag: StringName) -> bool

### Gameplay/targets/discovery/loot_discovery.gd
- static func get_immediate_loot(unit: Node, coord: Vector2i, loot_manager: Node) -> Node
- static func can_be_looted_by(unit: Node, loot: Node, interaction_range: float = 1.5) -> bool
- static func get_potential_loot_targets(unit: Node, loot_manager: Node, immediate_loot: Node = null) -> Array[Dictionary]

### Gameplay/targets/discovery/task_discovery.gd
- static func get_active_tasks(task_manager, faction: int = GameConstants.INVALID_INDEX) -> Array
- static func get_immediate_tasks(unit: Unit, coord: Vector2i, task_manager) -> Array

### Gameplay/targets/inventory_item.gd
- func _init() -> void
- func get_item_name() -> String
- func get_modifiers() -> Dictionary
- func is_quest_item() -> bool
- func _generate_uuid() -> String
- func to_dict() -> Dictionary
- static func from_dict(data: Dictionary) -> InventoryItem
- func duplicate_instance(regenerate_uuid: bool = false) -> InventoryItem

### Gameplay/targets/location.gd
- func _ready() -> void
- func set_grid_coord(grid_coord: Vector2i) -> void
- func mark_explored() -> void

### Gameplay/targets/location_action_provider.gd
- func append_location_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void
- func _add_task_summary_action(actions: Array[UnitAction], task_manager: TaskManager, immediate: Array[Task], reachable: Array[Task], reachable_lookup: Dictionary, action_type: UnitAction.Type, action_id: String) -> void

### Gameplay/targets/location_service.gd
- func setup(task_manager: TaskManager) -> void
- func get_all_locations_data() -> Array[Dictionary]
- func get_location_data_at_coordinate(coord: Vector2i) -> Dictionary
- func _transform_location_to_data(loc: Location) -> Dictionary
- func visit_location(location: Location, unit: Unit) -> bool
- func explore_location(location: Location, unit: Unit, task: Task, attribute: String = "") -> bool
- func create_memento() -> Dictionary
- func restore_from_memento(_memento: Dictionary) -> void

### Gameplay/targets/loot.gd
- func disarm_trap() -> void
- func can_be_looted_by(unit: Unit, interaction_range: float = 1.5) -> bool
- func add_items(items: Array[InventoryItem]) -> void
- func is_empty() -> bool
- func get_hover_info() -> String
- func take_all_items() -> Array[InventoryItem]

### Gameplay/targets/loot_action_provider.gd
- func append_loot_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void
- func _find_immediate_loot(unit: Unit, action_origin: Vector2i) -> Node
- func _find_reachable_loot(unit: Unit, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, immediate_loot: Node) -> Array
- func _add_loot_action(actions: Array[UnitAction], immediate_loot: Node, reachable_loot: Array, reachable_lookup: Dictionary, action_type: UnitAction.Type, action_id: String) -> void

### Gameplay/targets/loot_manager.gd
- func reset() -> void
- func add_to_routing_pool(items: Array[InventoryItem]) -> void
- func collect_routing_pool() -> Array[InventoryItem]
- func add_loot(loot: Loot, coord: Vector2i) -> void
- func remove_loot(loot: Loot) -> void
- func get_loot_at(coord: Vector2i) -> Loot
- func has_loot_at(coord: Vector2i) -> bool
- func get_loot_count() -> int
- func get_loot(index: int) -> Loot
- func get_coord(index: int) -> Vector2i
- func get_all_loot() -> Array[Loot]
- func spawn_loot(coord: Vector2i, items: Array[InventoryItem]) -> void
- func _spawn_new_loot(coord: Vector2i, items: Array[InventoryItem]) -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void
- func collect_all_loot_items() -> Array[InventoryItem]

### Gameplay/targets/move_and_interact_provider.gd
- static func append_move_and_interact_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, reachable_lookup: Dictionary, axis: int) -> void
- static func _append_move_and_attack_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void
- static func _process_move_and_unit_interaction(actions: Array[UnitAction], unit: Unit, target: Unit, action_role_id: String, action_type: UnitAction.Type, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void
- static func _append_move_and_loot_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, remaining_move: int) -> void
- static func _append_move_and_task_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, remaining_move: int) -> void
- static func _get_adjacent_coords(coord: Vector2i, axis: int) -> Array[Vector2i]
- static func _resolve_move_cost(reachable_lookup: Dictionary, coord: Vector2i, remaining_move: int) -> int
- static func _has_unblocked_path(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, target_coord: Vector2i, remaining_move: int) -> bool
- static func _resolve_move_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i
- static func _build_move_and_interact_action(move_coord: Vector2i, interact_action_type: UnitAction.Type, movement_cost: int, action_cost: int) -> UnitAction
- static func _select_best_attack_attribute(unit: Unit) -> int

### Gameplay/targets/target.gd
- func interact(unit: Unit, context: Dictionary = {}) -> void
- func get_attribute(attr_name: String) -> int
- func get_attribute_by_index(idx: int) -> int
- func get_grid_location() -> Vector2i
- func snap_to_grid() -> void
- func set_external_grid_coord(coord: Vector2i) -> void
- func clear_external_grid_coord() -> void
- func has_external_grid_coord() -> bool
- func distance_to_target(other: Target) -> int
- func is_pixel_inside(world_pos: Vector2) -> bool

### Gameplay/targets/target_spawner.gd
- static func spawn_unit(
- static func _apply_attributes(target: Target, entry: Resource) -> void
- static func spawn_loot(loot_entry: LevelLootEntry, loot_manager: LootManager, parent: Node = null, grid: Node2D = null) -> Node
- static func spawn_location(location_entry: LevelTaskEntry, parent: Node, grid: Node2D) -> Location
- static func spawn_or_update_location(location_entry: LevelTaskEntry, parent: Node, grid: Node2D) -> Location
- static func spawn_dialogue_trigger(dialogue_entry: LevelDialogueEntry, parent: Node, grid: TileMapLayer) -> DialogueTrigger

### Gameplay/targets/unit.gd
- func _init() -> void
- func _ready() -> void
- func _on_action_points_willpower_changed() -> void
- func _exit_tree() -> void
- func set_unit_manager(unit_manager: UnitManager) -> void
- func get_attribute(attr_name: String) -> int
- func get_unit_manager() -> UnitManager
- func set_animation_service(service) -> void
- func set_task_manager(manager: TaskManager) -> void
- func get_task_manager() -> TaskManager
- func set_location_service(service: LocationService) -> void
- func get_location_service() -> LocationService
- func set_loot_manager(manager: LootManager) -> void
- func get_loot_manager() -> LootManager
- func set_combat_system(system: CombatSystem) -> void
- func get_combat_system() -> CombatSystem
- func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]
- func is_at_full_morale() -> bool
- func adjust_remaining_movement(amount: int) -> void
- func on_enter_terrain(terrain: Variant) -> void
- func add_skill(skill: Skill) -> void
- func remove_skill(skill: Skill) -> void
- func get_combat_profile() -> CombatPriorityProfile
- func is_at_full_willpower() -> bool
- func refresh_for_new_round() -> void
- func set_free_roam_mode(enabled: bool) -> void
- func is_in_free_roam_mode() -> bool
- func consume_action() -> void
- func block_movement_this_turn() -> void
- func block_action_this_turn() -> void
- func is_faction_leader(p_faction: int) -> bool
- func set_faction_leader(p_faction: int, enabled: bool) -> void
- func is_player_leader() -> bool
- func set_player_leader(enabled: bool) -> void
- func is_friendly(other: Unit) -> bool
- func is_hostile(other: Unit) -> bool
- func _die() -> void
- func apply_consumable(pair_index: int, bonus: int) -> void
- func prepare_for_save() -> void
- func get_hover_info() -> String
- func finalize_setup() -> void
- func get_aid_buff(pair_index: int) -> int
- func add_aid_buff(p_value: int, pair_index: int = GameConstants.INVALID_INDEX) -> void
- func consume_aid_buffs() -> void

### Gameplay/targets/unit_action_manager.gd
- static func set_dialogue_service(service: DialogueActionService) -> void
- static func get_dialogue_service() -> DialogueActionService
- static func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool
- static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[UnitAction]
- static func get_available_actions_with_weather(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[UnitAction]
- static func _collect_actions(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[UnitAction]
- static func _get_grid_axis(unit: Unit) -> int
- static func _append_combat_actions(actions: Array[UnitAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void
- static func _append_location_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, coords: Array[Vector2i], lookup: Dictionary) -> void
- static func _append_loot_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, coords: Array[Vector2i], lookup: Dictionary) -> void
- static func _append_task_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i) -> void
- static func _append_skill_actions(actions: Array[UnitAction], unit: Unit, weather_manager) -> void
- static func _append_wait_action(actions: Array[UnitAction]) -> void

### Gameplay/targets/unit_component_factory.gd
- static func create_components(unit: Unit) -> void
- static func _init_inventory(unit: Unit) -> void
- static func _init_movement_cache(unit: Unit) -> void
- static func _init_behaviors(unit: Unit) -> void
- static func _inject_dependencies(unit: Unit) -> void

### Gameplay/targets/unit_controller.gd
- func configure_dependencies(state: GameState, config: GameSessionBuilder.Config) -> void
- func setup() -> void
- func get_unit_manager() -> UnitManager
- func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void
- func set_coord(index: int, coord: Vector2i) -> void
- func set_player_controlled(index: int, is_player: bool) -> void

### Gameplay/targets/unit_inventory.gd
- func add_item_to_inventory(item: InventoryItem) -> bool
- func remove_item_from_inventory(item: InventoryItem) -> bool
- func equip_item(item: InventoryItem) -> bool
- func _ensure_item_tracked(item: InventoryItem) -> bool
- func _check_equip_capacity(item: InventoryItem) -> bool
- func _find_by_uuid(uuid: String) -> InventoryItem
- func _equip_existing_item(item: InventoryItem) -> bool
- func _perform_equip(item: InventoryItem) -> void
- func unequip_item(item: InventoryItem) -> bool
- func clear_items() -> void
- func clear() -> void
- func get_items() -> Array[InventoryItem]
- func get_non_quest_items() -> Array[InventoryItem]
- func get_equipped_items() -> Array[InventoryItem]
- func get_equipped_non_quest_items() -> Array[InventoryItem]
- func has_item_by_id(item_id: String) -> bool

### Gameplay/targets/unit_manager.gd
- func reset() -> void
- func begin_batch_placement() -> void
- func end_batch_placement() -> void
- func add_unit(unit: Unit, coord: Vector2i, player_controlled: bool = false) -> void
- func get_nearest_empty_coord(requested_coord: Vector2i, max_radius: int = 5) -> Vector2i
- func mark_retreat(unit: Unit) -> void
- func remove_unit(unit: Unit) -> void
- func get_all_units() -> Array[Unit]
- func get_units() -> Array[Unit]
- func get_unit_count() -> int
- func get_player_units() -> Array[Unit]
- func get_enemy_units() -> Array[Unit]
- func get_neutral_units() -> Array[Unit]
- func get_allied_units(unit: Unit) -> Array[Unit]
- func get_faction_leader(faction: int) -> Unit
- func set_faction_leader(leader: Unit, faction: int) -> void
- func set_roster_for_faction(faction: int, roster: Resource) -> void
- func get_roster_for_faction(faction: int) -> Resource
- func reset_all_neutral_loyalties() -> void
- func get_selected_unit() -> Unit
- func get_selected_sprite() -> Unit
- func get_units_by_faction(faction: int) -> Array[Unit]
- func get_fleet_willpower(faction: int) -> int
- func get_selected_index() -> int
- func get_selected_coord() -> Vector2i
- func get_coord_by_unit(unit: Unit) -> Vector2i
- func get_unit(index: int) -> Unit
- func get_coord(index: int) -> Vector2i
- func set_coord(index: int, coord: Vector2i) -> void
- func is_occupied(coord: Vector2i, ignore_index: int = GameConstants.INVALID_INDEX) -> bool
- func get_unit_at_coord(coord: Vector2i) -> Unit
- func is_player_controlled(index: int) -> bool
- func set_player_controlled(index: int, is_controlled: bool) -> void
- func force_select_index(index: int) -> void
- func select_index(index: int) -> void
- func cycle_selection(direction: int) -> void
- func get_unit_index(unit: Unit) -> int
- func apply_faction_stat_boost(faction: int, amount: int) -> void
- func _apply_unit_stat_boost(unit: Unit, amount: int) -> void
- func get_faction_max_willpower(faction: int, include_debug_boost: bool = true) -> int
- func index_of_unit_at(coord: Vector2i) -> int
- func can_player_act(index: int) -> bool
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/targets/unit_presenter.gd
- static func get_hover_info(unit: Unit) -> String
- static func get_faction_name(unit: Unit) -> String

### Gameplay/targets/unit_serializer.gd
- static func create_memento(unit: Unit) -> Dictionary
- static func restore_from_memento(unit: Unit, data: Dictionary) -> void

### Gameplay/terrain/ash.gd
- func _init() -> void

### Gameplay/terrain/bridge_causeway.gd
- func _init() -> void

### Gameplay/terrain/cave_entrance.gd
- func _init() -> void

### Gameplay/terrain/courtyard.gd
- func _init() -> void

### Gameplay/terrain/crossroads.gd
- func _init() -> void

### Gameplay/terrain/crystal.gd
- func _init() -> void

### Gameplay/terrain/desert_oasis.gd
- func _init() -> void

### Gameplay/terrain/enchanted_forest.gd
- func _init() -> void

### Gameplay/terrain/floating_island.gd
- func _init() -> void

### Gameplay/terrain/fort.gd
- func _init() -> void

### Gameplay/terrain/grass.gd
- func _init() -> void

### Gameplay/terrain/graveyard.gd
- func _init() -> void

### Gameplay/terrain/hill_high_ground.gd
- func _init() -> void

### Gameplay/terrain/ice.gd
- func _init() -> void

### Gameplay/terrain/jungle.gd
- func _init() -> void

### Gameplay/terrain/keep.gd
- func _init() -> void

### Gameplay/terrain/lava_flow.gd
- func _init() -> void

### Gameplay/terrain/leaf_platform.gd
- func _init() -> void

### Gameplay/terrain/monastery.gd
- func _init() -> void

### Gameplay/terrain/mountain_peak.gd
- func _init() -> void

### Gameplay/terrain/mud.gd
- func _init() -> void

### Gameplay/terrain/oasis.gd
- func _init() -> void

### Gameplay/terrain/path.gd
- func _init() -> void

### Gameplay/terrain/plaza.gd
- func _init() -> void

### Gameplay/terrain/quagmire.gd
- func _init() -> void

### Gameplay/terrain/river.gd
- func _init() -> void

### Gameplay/terrain/rock_dune.gd
- func _init() -> void

### Gameplay/terrain/ruins.gd
- func _init() -> void

### Gameplay/terrain/sand.gd
- func _init() -> void

### Gameplay/terrain/stone.gd
- func _init() -> void

### Gameplay/terrain/swamp.gd
- func _init() -> void

### Gameplay/terrain/terrain_tile.gd
- func get_movement_adjustment() -> int
- func get_modified_movement_cost(weather_attribute: WeatherAttribute) -> int
- func apply_to_unit(unit: Unit) -> void
- func get_hover_info() -> String
- func _init() -> void

### Gameplay/terrain/tree_village.gd
- func _init() -> void

### Gameplay/terrain/underground.gd
- func _init() -> void

### Gameplay/terrain/vines.gd
- func _init() -> void

### Gameplay/terrain/wall.gd
- func _init() -> void

### Gameplay/terrain/waterfall.gd
- func _init() -> void

### Gameplay/turn/action_availability_service.gd
- func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool
- func _can_move_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool
- func _can_act_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool

### Gameplay/turn/action_label_formatter.gd
- static func format(base: String, adjacent_count: int, reachable_count: int, imm_label: String = "near") -> String
- static func get_label(action: UnitAction, target_name: String = "") -> String
- static func get_hint(action: UnitAction) -> String

### Gameplay/turn/ai/ai_action.gd
- func _init(

### Gameplay/turn/ai/ai_action_evaluator.gd
- func evaluate(_unit: _Unit, _context: _AIContext) -> Array[_AIAction]

### Gameplay/turn/ai/ai_command_builder.gd
- func build(action: _AIAction, unit: _Unit, context: _AIContext) -> Dictionary
- func _convince(unit_index: int, action: AIAction, context: AIContext) -> Dictionary
- func _attack(unit_index: int, action: AIAction, context: AIContext) -> Dictionary
- static func _select_best_attack_attribute(unit: Unit) -> int
- func _explore(unit_index: int, action: AIAction) -> Dictionary
- func _visit(unit_index: int, action: AIAction) -> Dictionary
- func _trapped(unit_index: int, action: AIAction) -> Dictionary
- func _loot(unit_index: int, action: AIAction) -> Dictionary
- func _aid_ally(unit_index: int, action: AIAction, context: AIContext) -> Dictionary

### Gameplay/turn/ai/aid_ally_evaluator.gd
- func evaluate(unit: Unit, _context: AIContext) -> Array[AIAction]
- func _get_best_aid_attribute(unit: Unit) -> int

### Gameplay/turn/ai/attack_evaluator.gd
- func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]
- func _is_neutral(unit: Unit) -> bool
- func _fallback_enemy_action(unit: Unit, context: AIContext, score_move_to_enemy: float) -> AIAction

### Gameplay/turn/ai/center_fallback_evaluator.gd
- func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]

### Gameplay/turn/ai/convince_evaluator.gd
- func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]

### Gameplay/turn/ai/loot_evaluator.gd
- func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]
- func _calculate_base_scores(unit: Unit) -> Dictionary
- func _add_immediate_loot_actions(unit: Unit, context: AIContext, base_score: float, actions: Array[AIAction], start_pos: Vector2i) -> void
- func _add_move_to_loot_actions(unit: Unit, context: AIContext, base_score: float, actions: Array[AIAction], start_pos: Vector2i) -> void
- func _try_add_move_to_loot_action(unit: Unit, context: AIContext, target: Variant, base_score: float, threatened_hexes: Dictionary, actions: Array[AIAction]) -> void
- func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary

### Gameplay/turn/ai/talk_evaluator.gd
- func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]
- func _resolve_dialogue_service(context: AIContext) -> DialogueActionService
- func _find_talk_actions(
- func _find_move_to_talk_actions(
- func _find_path_to_adjacent(

### Gameplay/turn/ai/task_evaluator.gd
- func evaluate(unit: _Unit, context: _AIContext) -> Array[_AIAction]
- func _calculate_scores(unit: _Unit, context: _AIContext) -> Dictionary
- func _calculate_morale_factor(unit: _Unit, context: _AIContext) -> float
- func _add_immediate_task_actions(unit: _Unit, context: _AIContext, base_score: float, actions: Array[_AIAction]) -> void
- func _add_move_to_task_actions(unit: _Unit, context: _AIContext, base_score: float, actions: Array[_AIAction]) -> void
- func _is_opposed_task(task: Task) -> bool
- func _is_invalid_coord(coord: Vector2i) -> bool
- func _get_threatened_hexes(unit: _Unit, context: _AIContext) -> Dictionary
- func _fallback_task_action(unit: _Unit, context: _AIContext) -> _AIAction
- func _get_personal_willpower_ratio(unit: _Unit) -> float
- func _get_group_morale_ratio(unit: _Unit, context: _AIContext) -> float

### Gameplay/turn/ai_controller.gd
- func _ready() -> void
- func _exit_tree() -> void
- func setup(state: GameState, _config: GameSessionBuilder.Config) -> void
- func _calculate_initial_max_willpower() -> void
- func set_turn_controller(controller: TurnController) -> void
- func set_command_context(command_context: GameCommandContext) -> void
- func execute_turn(ai_unit: Unit) -> bool
- func _build_context() -> AIContext
- func _rebuild_evaluators(_state) -> void
- func _gather_actions(unit: Unit, context: AIContext) -> Array[AIAction]
- func _execute_action(unit: Unit, action: AIAction, context: AIContext) -> bool
- func _execute_movement(unit: Unit, path: Array, terrain_map) -> bool
- func _truncate_path_to_reachable(unit: Unit, path: Array, terrain_map, budget: int) -> Array
- func _execute_interaction(unit: Unit, action: AIAction, context: AIContext) -> bool
- func _execute_command(cmd: GameCommand, payload: Dictionary) -> bool
- func _promote_move_action(unit: Unit, action: AIAction, context: AIContext) -> void
- func _promote_task_move(unit: Unit, action: AIAction, context: AIContext) -> void
- func _promote_loot_move(unit: Unit, action: AIAction, context: AIContext) -> void
- func _promote_talk_move(unit: Unit, action: AIAction, context: AIContext) -> void
- func _on_weather_effect_applied(weather_attribute: WeatherAttribute) -> void

### Gameplay/turn/auto_battle_diagnostics.gd
- static func report_unsupported_actions(unit: Unit, actions: Array, hud: Node = null) -> Dictionary
- static func get_unsupported_history() -> Array[Dictionary]

### Gameplay/turn/auto_battle_service.gd
- func _init(controller: TurnController) -> void
- func setup(unit_manager: UnitManager, ai_controller: AIController) -> void
- func reset() -> void
- func is_enabled() -> bool
- func is_in_progress() -> bool
- func set_enabled(enabled: bool) -> void
- func force_disable(reason: String = "") -> void
- func maybe_run_turn(unit: Unit = null) -> void
- func _can_run_auto_turn() -> bool
- func _resolve_current_player_unit() -> Unit
- func _is_valid_auto_unit(unit: Unit) -> bool
- func _process_auto_turn(unit: Unit) -> void
- func _handle_ai_result(unit: Unit, success: bool) -> void
- func _execute_ai_turn_logic(unit: Unit) -> bool
- func _handle_unit_invalidated_after_action() -> void
- func _handle_ai_success(unit: Unit) -> void
- func _handle_ai_failure(unit: Unit) -> void
- func _find_player_unit_candidate() -> int
- func _get_fallback_candidate() -> int
- func _activate_candidate_unit(index: int) -> Unit
- func _try_select_alternate_unit(_current_unit: Unit) -> bool
- func _reset_attempts() -> void
- func _record_attempt(index: int) -> void
- func _attempts_exhausted() -> bool
- func _should_preserve_turn(unit: Object) -> bool
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/turn/checkpoint_manager.gd
- func setup(game_state: GameState) -> void
- func on_checkpoint_requested() -> void
- func on_undo_requested() -> void
- func on_redo_requested() -> void
- func create_checkpoint(game_state: GameState) -> void
- func undo(game_state: GameState) -> bool
- func redo(game_state: GameState) -> bool
- func has_history() -> bool
- func has_redo() -> bool
- func _capture_state(game_state: GameState) -> Dictionary
- func _restore_state(game_state: GameState, snapshot: Dictionary) -> void
- func _validate_unique_items(game_state: GameState) -> void

### Gameplay/turn/combat_action_calculator.gd
- func append_combat_actions(actions: Array[UnitAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void
- func _find_adjacent_combat_targets(unit: Unit, _unit_manager: UnitManager) -> Dictionary
- func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int, adjacent_targets: Dictionary) -> Dictionary
- func _find_reachable_targets_with_move(units: Array, unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int, adjacent_targets: Dictionary, out_move_data: Dictionary) -> Array
- func _should_skip_target(unit: Unit, other: Unit, adjacent_targets: Dictionary) -> bool
- func _add_attack_action(actions: Array[UnitAction], _unit: Unit, enemies: Array, reachable_enemies: Array, target_move_data: Dictionary) -> void
- func _add_convince_action(actions: Array[UnitAction], _unit: Unit, convince_targets: Array, reachable_convince: Array, target_move_data: Dictionary) -> void
- func _add_aid_action(actions: Array[UnitAction], _unit: Unit, allies: Array, reachable_allies: Array, target_move_data: Dictionary) -> void
- func _find_best_adjacent_coord(target_coord: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, axis: int, action_range: float, unit_manager: UnitManager = null, unit_index: int = -1) -> Dictionary
- func has_reachable_adjacent(reachable_coords: Array[Vector2i], target_coord: Vector2i, axis: int, action_range: float, unit_manager: UnitManager = null, unit_index: int = -1) -> bool

### Gameplay/turn/combat_system.gd
- func execute_combat(attacker: Unit, defender: Unit, attribute_index: int) -> Dictionary
- func execute_attack_of_opportunity(attacker: Unit, defender: Unit, attribute_index: int) -> Dictionary
- func _execute_attack(attacker: Unit, defender: Unit, attribute_index: int, allow_counter: bool, consume_attacker_reaction: bool = false) -> Dictionary
- func _apply_damage_and_loyalty(attacker: Unit, defender: Unit, results: Dictionary) -> void
- func _consume_reactions(attacker: Unit, defender: Unit, can_counter: bool, consume_attacker_reaction: bool) -> void
- func _emit_attack_events(attacker: Unit, defender: Unit, results: Dictionary) -> void
- func get_combat_forecast(attacker: Target, defender: Target, attribute_index: int) -> Dictionary
- func get_attack_of_opportunity_forecast(attacker: Target, defender: Target, attribute_index: int) -> Dictionary
- func _validate_combatants(attacker: Target, defender: Target) -> Dictionary
- func _get_stat(unit: Target, attribute_index: int, use_consumable: bool = true) -> int
- func _compute_defense(unit: Target, attribute_index: int) -> float
- func _simulate_attack(attacker: Target, defender: Target, attribute_index: int, can_counter: bool = true) -> Dictionary

### Gameplay/turn/turn_controller.gd
- func _init() -> void
- func reset() -> void
- func setup(state: GameState, _config: GameSessionBuilder.Config) -> void
- func configure_dependencies(checkpoint_manager: CheckpointManager, hud: Node, terrain_map) -> void
- func start_next_turn() -> void
- func complete_turn() -> void
- func _start_unit_turn(index: int) -> void
- func _start_new_round() -> void
- func classify_unit_side(unit: Unit, index: int) -> int
- func rebuild_turn_roster(preserve_state: bool = false) -> void
- func _preserve_queue_state(old_queue: Array[int], units_by_side: Dictionary) -> void
- func _consume_current_turn_entry() -> void
- func _process_ai_turn(unit: Unit) -> void
- func on_turn_changed(unit: Unit) -> void
- func can_act_on_index(index: int) -> bool
- func lock_active_player_unit(index: int) -> void
- func complete_player_activation(index: int) -> void
- func _sync_unit_manager_selection(index: int) -> void
- func _is_unit_active(index: int) -> bool
- func _refresh_all_units() -> void
- func set_enabled(enabled: bool) -> void
- func is_enabled() -> bool
- func set_player_auto_battle_enabled(enabled: bool) -> void
- func is_player_auto_battle_enabled() -> bool
- func is_player_auto_control_locked() -> bool
- func force_disable_auto_battle(reason: String = "") -> void
- func is_queue_empty() -> bool
- func get_turn_queue() -> Array[int]
- func get_turn_system() -> TurnSystem
- func get_current_unit_index() -> int
- func get_current_side() -> int
- func get_round() -> int
- func move_index_to_front(target_index: int, list_position: int) -> void
- func set_current_unit_index(index: int) -> void
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/turn/turn_queue_builder.gd
- func _init(unit_manager: UnitManager) -> void
- func build_full_queue(start_side: int) -> Array[int]
- func get_active_units_by_side() -> Dictionary
- func determine_start_side(units_by_side: Dictionary, round_number: int, turns_taken_this_round: Dictionary, next_starting_side: int) -> int
- func build_from_active_units(units_by_side: Dictionary, start_side: int) -> Array[int]
- func get_side_rotation(start_side: int) -> Array[int]
- func find_next_active_side(current_side: int, units_by_side: Dictionary) -> int
- func classify_unit_side(unit: Unit, index: int) -> int

### Gameplay/turn/turn_system.gd
- func reset() -> void
- func get_turn_queue() -> Array[int]
- func set_turn_queue(queue: Array[int]) -> void
- func is_queue_empty() -> bool
- func get_queue_size() -> int
- func peek_next_index() -> int
- func pop_next_index() -> void
- func move_index_to_front(target_index: int, list_position: int) -> void
- func get_current_unit_index() -> int
- func set_current_unit_index(index: int) -> void
- func get_current_side() -> int
- func set_current_side(side: int) -> void
- func get_current_round() -> int
- func get_round() -> int
- func increment_round() -> void
- func get_next_starting_side() -> int
- func set_next_starting_side(side: int) -> void
- func get_turns_taken_this_round(side: int) -> int
- func increment_turns_taken_this_round(side: int) -> void
- func reset_turns_taken_this_round() -> void
- func has_index_in_queue(index: int) -> bool
- func create_memento() -> Dictionary
- func restore_from_memento(memento: Dictionary) -> void

### Gameplay/turn/unit_action.gd
- func _init(p_type: Type = Type.UNKNOWN) -> void
- static func create(p_type: Type, p_action_id: String = "") -> UnitAction

## Menus

### Menus/controls_menu.gd
- func _ready() -> void
- func _refresh_layouts() -> void
- func reset_and_apply_defaults() -> void
- func _on_back_pressed() -> void
- func _on_reset_pressed() -> void
- func _unhandled_input(event: InputEvent) -> void
- func _get_event_label(event: InputEvent) -> String

### Menus/credits.gd
- func _ready() -> void
- func set_return_delay(delay: float) -> void
- func _start_timer() -> void
- func _on_return_timeout(token: int) -> void

### Menus/inventory_management_menu.gd
- func _ready() -> void
- func _refresh_ui() -> void
- func _update_help_text() -> void
- func _on_action_requested(type: String, item: InventoryItem, unit: Unit) -> void
- func _on_minus_pressed(unit: Unit, item: InventoryItem) -> void
- func _on_equip_pressed(unit: Unit, item: InventoryItem) -> void
- func _on_hand_pressed(item: InventoryItem) -> void
- func handle_item_drop(item: InventoryItem, source_unit: Unit, target_unit: Unit) -> void
- func handle_swap(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit) -> void
- func _on_auto_equip_pressed() -> void
- func _on_debug_reset_pressed() -> void
- func _on_viewport_size_changed() -> void
- func _update_layout() -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _input(event: InputEvent) -> void
- func _on_back_pressed() -> void
- func _update_move_mode_visuals() -> void
- func _enter_move_mode(item: InventoryItem) -> void
- func _exit_move_mode() -> void
- func setup(p_menu: Control, is_vertical: bool = true) -> void
- func add_item(node: Node) -> void
- func _can_drop_data(_at_position: Vector2, data: Variant) -> bool
- func _drop_data(_at_position: Vector2, data: Variant) -> void
- func _on_pause_pressed() -> void

### Menus/level_select.gd
- func _ready() -> void
- func _populate_levels() -> void
- func _on_back_pressed() -> void
- func _on_level_pressed(level_id: String) -> void
- func _on_debug_reset_pressed() -> void
- func _on_pause_pressed() -> void
- func _update_layout() -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void

### Menus/pause_handler.gd
- func _unhandled_input(event: InputEvent) -> void
- func _handle_pause_input(event: InputEvent) -> bool
- func show_pause_menu() -> void
- func _hide_pause_menu() -> void
- func _on_pause_resume() -> void
- func _on_pause_controls() -> void
- func _on_pause_inventory() -> void
- func _on_pause_journal() -> void
- func _on_pause_settings() -> void
- func _on_controls_back() -> void
- func _on_inventory_back() -> void
- func _on_journal_back() -> void
- func _on_settings_back() -> void
- func _on_pause_quit() -> void
- func is_paused() -> bool
- func set_journal_manager(p_journal_manager: Node) -> void
- func set_unit_manager(p_unit_manager: UnitManager) -> void

### Menus/pause_menu.gd
- func _ready() -> void
- func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void
- func _update_layout() -> void
- func _unhandled_input(event: InputEvent) -> void
- func show_menu() -> void
- func hide_menu() -> void
- func _on_resume_pressed() -> void
- func _on_controls_pressed() -> void
- func _on_inventory_pressed() -> void
- func _on_journal_pressed() -> void
- func _on_settings_pressed() -> void
- func _on_quit_pressed() -> void

### Menus/settings_menu.gd
- func _ready() -> void
- func _on_locale_changed() -> void
- func setup(game_config: Node) -> void
- func _translate_labels() -> void
- func _setup_audio_settings(game_config: Node) -> void
- func _create_audio_row(parent: Node, anchor: Node, bus_name: String, label_key: String, config_path: String, mute_path: String) -> void
- func _setup_display_settings(_game_config_node: Node) -> void
- func _setup_animation_settings(game_config: Node) -> void
- func _setup_language_row(game_config: Node) -> void
- func _on_language_selected(index: int) -> void
- func _unhandled_input(event: InputEvent) -> void
- func _on_back_pressed() -> void
- func _on_volume_changed(value: float) -> void
- func _on_mute_toggled(pressed: bool) -> void
- func _on_orientation_selected(index: int) -> void
- func _on_resolution_selected(index: int) -> void
- func _on_animation_speed_selected(index: int) -> void
- func _initialize_dialogue_settings(game_config: Node) -> void
- func _on_auto_advance_toggled(pressed: bool) -> void
- func _on_auto_advance_speed_changed(value: float) -> void
- func _on_text_speed_changed(value: float) -> void
- func _update_auto_advance_speed_label(value: float) -> void
- func _update_text_speed_label(value: float) -> void
- func _setup_difficulty_row(game_config: Node) -> void
- func _on_difficulty_selected(index: int) -> void
- func _save_dialogue_value(path: String, value) -> void

### Menus/title_screen.gd
- func _ready() -> void
- func set_quit_callback(callback: Callable) -> void
- func _on_start_pressed() -> void
- func _on_quit_pressed() -> void
- func _on_level_select() -> void
- func _unhandled_input(event: InputEvent) -> void
- func _is_relevant_press(event: InputEvent) -> bool
- func _is_quit_event(event: InputEvent) -> bool
- func _is_start_event(event: InputEvent) -> bool
- func _contains(values: PackedInt32Array, value: int) -> bool
- func _mark_input_handled() -> void
- func _start_keys() -> PackedInt32Array
- func _quit_keys() -> PackedInt32Array
- func _start_buttons() -> PackedInt32Array
- func _quit_buttons() -> PackedInt32Array
- func _allow_any_non_quit_key() -> bool
- func _allow_any_joy_button() -> bool
- func _start_via_shortcut() -> void
- func _quit_via_shortcut() -> void
- func _scene_transition() -> Node

## Resources

### Resources/Localization/localization_strings.gd
- static func get_command_name(command_id: GameConstants.Commands.CommandID) -> String
- static func get_command_description(command_id: GameConstants.Commands.CommandID) -> String
- static func get_text(key: String, _language_code: StringName = &"") -> String
- static func has_key(key: String) -> bool
- static func get_supported_languages() -> PackedStringArray

### Resources/animation_styles/animation_style_set.gd
- func get_style(style_id: StringName) -> AnimationStyle

### Resources/file_paths_loader.gd
- static func load_paths() -> FilePathsLoader
- func _load_internal() -> void
- func get_path(path_key: String) -> String
- func get_category(category: String) -> Dictionary
- func get_warnings() -> Array[String]
- func get_dynamic_paths() -> Dictionary
- func validate_paths() -> Dictionary
- func _validate_category_recursive(category: String, dict: Dictionary, results: Dictionary) -> void
- func get_errors() -> Array[String]
- func print_summary() -> void
- func _count_paths(dict: Dictionary) -> int
- static func get_scene(scene_key: String) -> String
- static func get_autoload(autoload_key: String) -> String

## Root

### debug_load.gd
- func _init()

### verify_roster_reset.gd
- func _init()

## level

### level/Level.gd
- func _init() -> void
- func _ensure_default_terrain_data() -> void
- func _regenerate_location_entries_from_coords() -> void

### level/combat_stats.gd
- func _init(p_grit := 6, p_flow := 6, p_gusto := 6, p_focus := 6, p_shine := 6, p_shade := 6, p_willpower := 10) -> void
- func get_attribute(attr_name: String) -> int
- func set_attribute(attr_name: String, value: int) -> void

### level/level_auto_fix_service.gd
- func apply(level: Level, level_id: StringName, _roster_rows: Array, location_rows: Array, start_rows: Array, dialogue_rows: Array, options: LevelAutoFixOptions) -> Dictionary
- func _build_context(level: Level, level_id: StringName) -> Dictionary
- func _validate_coord_in_context(coord: Vector2i, blocked_types: Array[String], dims: Dictionary, terrain_map: TerrainMap, occupancy: Dictionary) -> Dictionary
- func _find_replacement_in_context(original: Vector2i, blocked_types: Array[String], dims: Dictionary, terrain_map: TerrainMap, occupancy: Dictionary) -> Vector2i
- func _get_reason_label(reason: String) -> String
- func _repair_locations(level: Level, location_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_player_starts(level: Level, player_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_neutral_starts(level: Level, neutral_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_tasks(level: Level, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _write_report_file(level_id: StringName, report: Dictionary) -> void

### level/level_build_context.gd
- func _init(p_game_state: GameState, p_root: Node2D, p_unit_manager: UnitManager, p_unit_controller: UnitController, p_task_manager: TaskManager, p_loot_manager: LootManager, p_combat_system: CombatSystem, p_grid: Node2D, p_camera: Camera2D, p_controls: Node, p_player_roster: PlayerRoster, p_enemy_roster: EnemyRoster, p_neutral_roster: NeutralRoster = null, p_target_task_templates: Array[Task] = [], p_level: Level = null, p_allow_loot_spawn: bool = true, p_dialogue_service: DialogueActionService = null, p_animation_service = null, p_leader_unit_name: String = "Scout", p_location_service: LocationService = null) -> void

### level/level_builder.gd
- func _init(context: LevelBuildContext) -> void
- func build_environment(level: Level, terrain_map: TerrainMap) -> Dictionary
- func spawn_global_content(level: Level, terrain_map: TerrainMap) -> void
- func _apply_level_settings(level: Level, terrain_map: TerrainMap) -> void
- func _is_location_coord_passable(coord: Vector2i) -> bool

### level/level_catalog.gd
- func get_default_level() -> String
- func get_levels() -> Array[Dictionary]
- func get_level_by_id(level_id: String) -> Dictionary
- func find_level_by_path(path: String) -> Dictionary

### level/level_content_spawner.gd
- func _init(context: LevelBuildContext, terrain_map) -> void
- func spawn_global_content(level: Level) -> void
- func _spawn_player_units(level: Level, skip_scene_path: String = "") -> void
- func _handle_empty_player_spawns(level: Level, skip_scene_path: String) -> void
- func _try_spawn_player_entry(entry: LevelUnitSpawnEntry, skip_scene_path: String) -> void
- func _spawn_scripted_player_unit(entry: LevelUnitSpawnEntry, skip_scene_path: String) -> void
- func _spawn_roster_player_unit(entry: LevelUnitSpawnEntry, skip_scene_path: String) -> void
- func _spawn_roster_units_at_coords(coords: Array[Vector2i], skip_scene_path: String) -> void
- func _spawn_enemy_units(level: Level) -> void
- func _spawn_neutral_units(level: Level) -> void
- func _spawn_unit(scene: PackedScene, coord: Vector2i, is_player: bool, is_neutral: bool, modulate: Color = Color.WHITE, inventory: Array[InventoryItem] = []) -> void
- func _verify_unit_components(unit: Unit) -> void
- func _init_unit_faction(unit: Unit, is_player: bool, is_neutral: bool) -> void
- func _apply_unit_dependencies(unit: Unit) -> void
- func _assign_fallback_player_leader() -> void
- func _spawn_level_dialogue_triggers(level: Level) -> Array[DialogueTrigger]
- func _apply_trigger_group(_trigger: DialogueTrigger, entry: LevelDialogueEntry) -> void
- func _is_location_coord_passable(coord: Vector2i) -> bool
- func _is_hometown_context() -> bool
- func _is_hometown_level(level: Level) -> bool
- func _get_primary_player_identity() -> Dictionary
- func _should_skip_neutral_spawn(scene: PackedScene, leader_scene_path: String, leader_unit_name: String, _entry_coord: Vector2i) -> bool
- func _spawn_hometown_player_leader(level: Level, leader_scene_path: String, leader_unit_name: String) -> Dictionary
- func _find_hometown_leader_entry(level: Level, leader_scene_path: String, leader_unit_name: String) -> Dictionary
- func _scene_matches_leader(scene: PackedScene, leader_scene_path: String, leader_unit_name: String) -> bool
- func _ensure_leader_scene_recorded(scene: PackedScene, canonical_path: String = "", leader_unit_name: String = "") -> void
- func _ensure_leader_scene_recorded_orig(scene: PackedScene, canonical_path: String = "", leader_unit_name: String = "") -> void

### level/level_dialogue_entry.gd
- func get_flag_id() -> StringName

### level/level_dialogue_journal_entry.gd
- func has_journal() -> bool
- func has_dialogue() -> bool

### level/level_flow_controller.gd
- func _init(catalog: LevelCatalog = null, progress_store: LevelProgressStore = null, scene_tree: SceneTree = null, scene_transition: Node = null) -> void
- func start_level(level_id: String) -> Resource
- func start_first_level() -> void
- func mark_level_completed(level_id: String) -> void
- func get_available_levels() -> Array[Dictionary]
- func is_level_unlocked(level_id: String) -> bool
- func get_level_info(level_id: String) -> Dictionary
- func get_current_level_path() -> String
- func get_current_level_id() -> String
- func handle_level_complete(_level_path: String = "") -> void
- func handle_quit_to_title() -> void
- func handle_quit_to_level_select() -> void
- func _change_scene(target: String) -> void
- func _set_next_level_by_path(path: String) -> void
- func _load_resource(path: String) -> Resource
- func _has_unlocked_incomplete_levels() -> bool
- func _on_scene_changed(new_scene: Node = null) -> void
- func _configure_gameplay_scene(scene: Node) -> void
- func _connect_scene_signal(scene: Node, signal_name: String, callable: Callable) -> void

### level/level_initialization_orchestrator.gd
- static func run_initialization_pipeline(level: Level, level_manager: Object, task_controller: Object) -> void

### level/level_journal_entry.gd
- func _init(

### level/level_loader.gd
- static func load_level_data(level: Level) -> Dictionary
- static func _validate_data(data: Dictionary) -> void

### level/level_log.gd
- static func set_debug(enabled: bool) -> void
- static func debug(msg: String) -> void
- static func info(msg: String) -> void
- static func warn(msg: String) -> void
- static func error(msg: String) -> void

### level/level_loot_entry.gd
- func get_items() -> Array[InventoryItem]
- func get_coord() -> Vector2i
- func get_stats() -> CombatStats

### level/level_manager_gameplay.gd
- func _init(game_state: GameState, controls: Node) -> void
- func set_save_manager(save_manager: SaveManager) -> void
- func set_dialogue_service(service: DialogueActionService) -> void
- func set_auto_fix_enabled(enabled: bool) -> void
- func set_level_resource(level: Level) -> void
- func prepare_level_data() -> void
- func clear_world() -> void
- func build_environment() -> Dictionary
- func spawn_global_content() -> void
- func finalize_setup() -> void
- func apply_level_if_available() -> void
- func _create_build_context() -> LevelBuildContext
- func _handle_build_result(result: Dictionary) -> void
- func _connect_morale_panel_signals() -> void
- func set_level_and_rebuild(level: Level) -> void
- func on_task_reached() -> void
- func update_task_progress() -> void
- func on_task_failed() -> void
- func _get_level_id_for_level(level: Level) -> StringName
- func _apply_row_resources(level: Level) -> void
- func _is_hometown_level(level: Level) -> bool
- func _queue_hometown_progression_dialogues() -> void
- func on_unit_moved(index: int, coord: Vector2i) -> void
- func _apply_hometown_exploration_rules() -> void
- func _get_primary_player_unit() -> Unit

### level/level_progress_store.gd
- func _init(save_manager: Node = null) -> void
- func get_completed_levels() -> Dictionary
- func is_level_completed(level_id: String) -> bool
- func mark_level_completed(level_id: String) -> void
- func reset() -> void

### level/level_roster_service.gd
- func _init() -> void
- func setup(save_manager: SaveManager) -> void
- func refresh_player_roster(state: GameState) -> void
- func determine_leader_name(roster: PlayerRoster) -> String
- func _resolve_leader_name_from_roster(roster: PlayerRoster, preferred: String) -> String
- func _unit_name_from_scene(scene: PackedScene) -> String

### level/level_row_loader.gd
- func _init() -> void
- func refresh_for_level(level_id: StringName) -> void
- func set_auto_fix_options(options: LevelAutoFixOptions) -> void
- func _load_rows_for_level(level_id: StringName) -> void
- func apply_rows_to_level(level: Level, level_id: StringName) -> Dictionary
- func _rows_for_level(level_id: StringName) -> Dictionary
- func _apply_combat_rows(level: Level, roster_rows: Array, loot_rows: Array, location_rows: Array) -> void
- func _validate_and_autofix(level: Level, level_id: StringName, rows: Dictionary) -> Dictionary
- func _apply_start_rows(level: Level, rows: Array) -> void
- func _apply_dialogue_rows(level: Level, rows: Array) -> void
- func _build_journal_entries(rows: Array) -> Array[LevelJournalEntry]
- func _load_rows_from_path(path: String, expected_type: Script) -> Array
- func _list_resource_files(path: String) -> Array[String]
- func _sync_roster_definitions(level: Level) -> void
- func _inject_into_first_stage(level: Level) -> void
- func _get_stages_to_inject(objective: Objective) -> Array[Stage]
- func _inject_all_rows_to_stage(level: Level, stage: Stage) -> void
- func _inject_collection_to_target(collection: Array, target: Array) -> void

### level/level_row_validator.gd
- func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, start_rows: Array, dialogue_rows: Array, journal_entry_rows: Array) -> Array[String]
- func _validate_journal_entry_rows(journals: Array, level_id: String) -> Array[String]
- func _validate_roster_rows(rows: Array, level_id: String, width: int, height: int, coord_map: Dictionary) -> Array[String]
- func _validate_loot_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]
- func _validate_location_rows(rows: Array, level_id: String, width: int, height: int, coord_map: Dictionary) -> Array[String]
- func _validate_start_rows(rows: Array, level_id: String, width: int, height: int, roster_coords: Dictionary, location_coords: Dictionary) -> Array[String]
- func _get_faction_key(faction: int) -> StringName
- func _validate_start_slot(row: Variant, faction_key: StringName, player_slots: Dictionary, level_id: String, errors: Array[String]) -> void
- func _validate_start_coordinate(row: Variant, start_coords: Dictionary, roster_coords: Dictionary, location_coords: Dictionary, level_id: String, errors: Array[String]) -> void
- func _validate_start_faction_requirements(row: Variant, faction_key: StringName, level_id: String, errors: Array[String]) -> void
- func _is_in_bounds(coord: Vector2i, width: int, height: int) -> bool
- func _coord_key(coord: Vector2i) -> String

### level/level_state_controller.gd
- func setup(game_state: GameState) -> void
- func update_grid_dimensions(width: int, height: int) -> void
- func on_task_reached(level_resource: Level, _save_manager: SaveManager) -> void
- func get_task_reached_state() -> bool
- func set_task_reached_state(value: bool) -> void
- func update_task_progress() -> void
- func handle_player_defeat(message: String) -> void
- func handle_enemy_retreat() -> void
- func handle_neutral_retreat() -> void
- func update_safe_zone_ui(is_hometown: bool) -> void
- func _resolve_scene_tree() -> SceneTree

### level/level_task_entry.gd
- func get_location_scene() -> PackedScene
- func get_coord() -> Vector2i
- func get_stats() -> CombatStats

### level/level_unit_spawn_entry.gd
- func get_unit_scene() -> PackedScene
- func get_coord() -> Vector2i
- func get_inventory() -> Array[InventoryItem]
- func get_ai_profile() -> CombatPriorityProfile
- func get_stats() -> CombatStats

### level/validation/connectivity_validator.gd
- static func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, start_rows: Array) -> Array[String]
- static func _collect_pois(level: Level, roster_rows: Array, loot_rows: Array, location_rows: Array, width: int, height: int) -> Dictionary
- static func _perform_reachability_scan(start_coord: Vector2i, terrain_map: TerrainMap, width: int, height: int, axis: int) -> Dictionary
- static func _report_connectivity_errors(poi_map: Dictionary, player_starts: Array[Vector2i], reachable: Dictionary, level_id: String) -> Array[String]

### level/validation/dialogue_validator.gd
- static func validate_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]
- static func validate_journal_links(dialogue_rows: Array, journal_rows: Array, level_id: String, objective: Objective = null) -> Array[String]
- static func _add_explicit_links(obj: Resource, d_white: Dictionary, j_white: Dictionary) -> void

### level/validation/grid_utils.gd
- static func dims_of(level: Level) -> Dictionary
- static func is_passable(terrain_map: TerrainMap, coord: Vector2i, level: Level) -> bool
- static func find_replacement_coord(origin: Vector2i, terrain_map: TerrainMap, level: Level, occupancy: Dictionary, blocked: Array[String]) -> Vector2i

### level/validation/level_data_validator.gd
- static func validate_data(data: Dictionary) -> void
- static func filter_coords(data: Dictionary, keys: Array[String]) -> void

### level/validation/repair/dialogue_repairer.gd
- func repair(_level: Level, dialogue_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_dialogue_metadata(row: LevelDialogueEntry, report: Dictionary, level_name: String) -> void

### level/validation/repair/location_repairer.gd
- func repair(level: Level, _location_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_location_metadata(loc: LevelTaskEntry, index: int, report: Dictionary, level_name: String) -> void

### level/validation/repair/task_repairer.gd
- func repair(level: Level, report: Dictionary, _context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_task_metadata(t: Task, index: int, stage_id: String, report: Dictionary, level_name: String) -> void

### level/validation/repair/unit_spawn_repairer.gd
- func repair_player_starts(level: Level, player_rows: Array[LevelUnitSpawnEntry], report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func repair_neutral_starts(level: Level, neutral_rows: Array[LevelUnitSpawnEntry], report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void
- func _repair_unit_spawn_metadata(spawn: LevelUnitSpawnEntry, index: int, type: String, report: Dictionary, level_name: String) -> void

### level/validation/spawn_utils.gd
- static func parse_entry(entry) -> Dictionary
- static func to_spawn_entry(parsed: Dictionary) -> LevelUnitSpawnEntry

### level/validation/task_row_validator.gd
- static func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array) -> Array[String]
- static func _coord_key(coord: Vector2i) -> String

## tests

### tests/base_test_suite.gd
- static func assert_eq(test_suite: Node, actual, expected, message: String = "")
- static func _simulate_frames(runner: GdUnitSceneRunner, frames: int = 1) -> void
- static func _create_scene_runner(test_suite: Node, scene_path: String) -> GdUnitSceneRunner
- static func ensure_manager(
- static func setup_autoloads(tree: SceneTree, autoload_configs: Dictionary) -> Dictionary
- static func teardown_autoloads(tree: SceneTree) -> void
- static func _clear_save_game() -> void
- static func free_tree(node: Node) -> void
- static func _mock_unit(test_suite: Node, unit_name: String = "Mock Unit", faction: int = 0) -> Unit

### tests/fixtures/test_factory.gd
- static func create_unit(name: String = "Test Unit", faction: int = 0) -> Unit
- static func create_level() -> Level
- static func create_level_build_context() -> LevelBuildContext
- static func cleanup_level_build_context(context: LevelBuildContext) -> void

### tests/fixtures/test_stubs.gd
- func _init(p_neighbors: Dictionary = {}, width: int = 10, height: int = 10)
- func is_within_bounds(coord: Vector2i) -> bool
- func is_passable(coord: Vector2i) -> bool
- func get_neighbors(coord: Vector2i) -> Array[Vector2i]
- func get_offset_axis() -> int
- func set_offset_axis(axis: int) -> void
- func load_from_rows(_p_rows: Array, _p_width: int = -1, _p_height: int = -1) -> void
- func select_index(p_index: int) -> void
- func get_selected_unit() -> Unit
- func get_selected_index() -> int
- func add_unit(unit: Unit, coord: Vector2i, _is_player: bool = false) -> void
- func get_unit(index: int) -> Unit
- func get_coord(index: int) -> Vector2i
- func get_unit_index(unit) -> int
- func is_occupied(coord: Vector2i, _ignore_index: int = -1) -> bool
- func set_coords(values: Array[Vector2i]) -> void
- func set_location(coord: Vector2i, location: Location) -> void
- func set_task_for_target(target: Target, task: Task) -> void
- func clear_locations() -> void
- func get_location_at(coord: Vector2i) -> Location
- func get_task_for_target(target: Target) -> Task
- func get_location_count() -> int
- func get_target(index: int) -> Vector2i
- func get_active_objective() -> Objective
- func set_active_objective(obj: Objective) -> void
- func add_loot(loot: Loot, coord: Vector2i) -> void
- func has_loot_at(coord: Vector2i) -> bool
- func get_loot_at(coord: Vector2i) -> Loot
- func get_loot_count() -> int
- func get_loot(index: int) -> Loot
- func get_coord(index: int) -> Vector2i
- func reset() -> void
- func append_dialogue_actions(actions: Array[UnitAction], _unit: Unit, _p_unit_manager: UnitManager) -> void
- func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult
- func handle_dialogue_request(id_or_path: String, unit_index: int = -1) -> void
- func get_inventory() -> UnitInventory
- func get_items() -> Array
- func _init(u: Unit)
- func get_adjacent_units(units: Array, _r: float = 1.5) -> Array[Unit]
- func get_hostile_units() -> Array[Unit]
- func get_friendly_units() -> Array[Unit]
- func get_neutral_units() -> Array[Unit]
- func _init(u: Unit)
- func attack(target: Unit, pair_idx: int = 0) -> bool
- func _init(u: Unit)
- func get_remaining_movement_points() -> int
- func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]
- func _init()
- func _ready() -> void
- func has_action_available() -> bool
- func consume_action() -> void
- func set_attribute_values(values: Dictionary) -> void
- func get_attributes()
- func get_grid_location() -> Vector2i
- func set_grid_location(coord: Vector2i) -> void
- func get_hostile_units() -> Array
- func get_friendly_units() -> Array
- func get_neutral_units() -> Array
- func get_adjacent_units(units: Array, _adjacency_range: float = 1.5) -> Array
- func get_units_in_range(units: Array, _detection_range: float) -> Array
- func get_path_to_coord(target_coord: Vector2i, _terrain_map: Variant, _start_coord: Vector2i = Vector2i.MAX, _movement_budget: int = -1) -> Array[Vector2i]
- func get_closest_unit(units: Array) -> Unit
- func attack(target: Unit, _pair_idx: int = 0) -> void
- func die() -> void
- func damage(amount: int) -> void
- func get_remaining_movement_points() -> int
- func get_channeling_unit() -> Unit
- func get_value(key: String, default = null)
- func set_value(key: String, value) -> void
- func save_config() -> void
- func get_standard_resolutions(requested_orientation: int) -> Array[Vector2i]
- func get_current_orientation() -> int
- func get_current_resolution_index() -> int
- func get_current_resolution() -> Vector2i
- func set_orientation(new_orientation: int) -> void
- func set_resolution_index(new_index: int) -> void
- func get_bus_volume_db(bus: String) -> float
- func set_bus_volume_db(bus: String, db: float) -> void
- func is_bus_muted(bus: String) -> bool
- func mute_bus(bus: String, enable: bool) -> void
- func reset_inputs_to_defaults()
- func apply_configs(_configs, _defaults = null)
- func get_round() -> int
- func get_current_side() -> int
- func get_current_unit_index() -> int
- func complete_turn() -> void
- func can_act_on_index(_idx: int) -> bool
- func is_enabled() -> bool
- func lock_active_player_unit(_idx: int) -> void
- func rebuild_turn_roster() -> void
- func execute_turn(unit) -> bool

### tests/reproduce_equip_bug.gd
- func test_roster_equipment_persistence() -> void

### tests/test_achievement_manager.gd
- func _find_achievement_script() -> GDScript
- func _make_manager() -> Node
- func _make_achievement(id: String, title: String = "Test Achievement") -> Achievement
- func after_test() -> void
- func test_unlock_achievement_sets_unlocked_true() -> void
- func test_unlock_achievement_emits_signal() -> void
- func test_unlock_achievement_returns_false_when_already_unlocked() -> void
- func test_unlock_achievement_returns_false_for_unknown_id() -> void
- func test_unlock_achievement_does_not_emit_signal_if_already_unlocked() -> void
- func test_unlock_achievement_idempotent_on_second_call() -> void
- func test_get_savable_data_returns_only_unlocked_ids() -> void
- func test_get_savable_data_empty_when_none_unlocked() -> void
- func test_load_savable_data_marks_matching_achievements_unlocked() -> void
- func test_load_savable_data_ignores_unknown_ids_without_crash() -> void
- func test_load_savable_data_no_key_does_nothing() -> void
- func test_load_savable_data_round_trip() -> void

### tests/test_action_availability_service.gd
- func set_target_task(coord: Vector2i, target_task: Task) -> void
- func get_location_at(coord: Vector2i) -> Location
- func get_task_for_target(target: Target) -> Task
- func get_active_objective() -> Objective
- func can_be_worked_on_by(_unit: Unit, from_coord: Vector2i = Vector2i(-1, -1)
- func test_is_unit_not_stuck_when_location_at_tentative_position() -> void

### tests/test_action_commands.gd
- func attack(target: Unit, pair_idx: int = 0) -> void
- func aid_ally(target: Unit) -> void
- func die() -> void
- func test_attack_command_execution() -> void
- func test_aid_ally_command_execution() -> void
- func test_explore_command_execution() -> void
- func test_loot_command_execution() -> void

### tests/test_action_label_formatter.gd
- func test_format_no_counts_returns_base() -> void
- func test_format_adjacent_only() -> void
- func test_format_reachable_only() -> void
- func test_format_both_counts() -> void
- func test_format_adjacent_one() -> void
- func test_format_empty_base_no_counts() -> void
- func test_format_empty_base_with_counts() -> void
- func test_format_zero_adjacent_is_not_shown() -> void
- func test_format_zero_reachable_is_not_shown() -> void
- func test_format_large_counts() -> void

### tests/test_action_points_component_extended.gd
- func _make_component() -> ActionPointsComponent
- func test_consume_reaction_decrements_available() -> void
- func test_consume_reaction_does_not_go_below_zero() -> void
- func test_consume_reaction_from_one_to_zero() -> void
- func test_consume_reaction_twice_from_two() -> void
- func test_refresh_restores_reactions_after_consume() -> void
- func test_get_reactions_available_matches_remaining() -> void
- func test_get_max_reactions_unaffected_by_consume() -> void
- func test_set_max_reactions() -> void

### tests/test_actions_panel.gd
- func before_test() -> void
- func after_test() -> void
- func _make_unit(player := true) -> Unit
- func test_show_attack_menu_displays_targets_and_attributes() -> void
- func test_set_auto_battle_mode_hides_hint_and_dims_panel() -> void
- func test_enable_navigation_mode_focuses_first_button() -> void

### tests/test_ai_attack_evaluator.gd
- func get_adjacent_units(_units: Array, _r: float = 1.5) -> Array
- func test_evaluate_returns_empty_for_neutral_units() -> void
- func test_evaluate_returns_attack_for_adjacent_enemy() -> void
- func test_evaluate_returns_move_to_enemy_for_distant_enemy() -> void

### tests/test_ai_loot_evaluator.gd
- func test_evaluate_returns_loot_action_if_loot_at_start_coord() -> void
- func test_evaluate_returns_move_to_loot_action_for_reachable_loot() -> void
- func test_evaluate_returns_empty_when_missing_context() -> void

### tests/test_ai_task_evaluator.gd
- func can_be_worked_on_by(_unit: UnitClass, _coord: Vector2i = GameConstants.INVALID_COORD) -> bool
- func test_evaluate_returns_work_on_task_if_at_location() -> void
- func test_evaluate_returns_move_to_task_for_distant_task() -> void

### tests/test_aid_ally_evaluator.gd
- func before_test() -> void
- func _setup_unit_with_mock_query(u: Unit) -> void
- func test_evaluate_scores_zero_if_no_actions() -> void
- func test_evaluate_scores_zero_if_ally_has_no_actions() -> void
- func test_evaluate_lowers_score_if_ally_not_near_enemy() -> void
- func test_evaluate_full_score_if_ally_near_enemy() -> void
- func test_evaluate_halves_score_if_ally_already_buffed() -> void

### tests/test_aim_cursor.gd
- func _make_cursor() -> Node2D
- func test_set_initial_position() -> void
- func test_get_effective_cursor_position_fallback() -> void
- func test_get_effective_cursor_position_virtual() -> void
- func test_is_virtual_active() -> void
- func test_joy_aim_activation() -> void
- func test_joy_aim_inactivity_timeout() -> void

### tests/test_animation_request_service.gd
- func map_to_local(coord: Vector2i) -> Vector2
- func tween_property(_target: Object, property: String, value, duration: float) -> RecordingTween
- func tween_interval(duration: float) -> RecordingTween
- func parallel() -> RecordingTween
- func set_trans(_value: int) -> RecordingTween
- func set_ease(_value: int) -> RecordingTween
- func tween_callback(callback: Callable) -> RecordingTween
- func _build_style(style_id: StringName, duration: float, metadata: Dictionary = {}, position_offset: Vector2 = Vector2.ZERO) -> AnimationStyle
- func _make_style_set(styles: Array[AnimationStyle]) -> AnimationStyleSet
- func _make_service(style_set: AnimationStyleSet) -> Dictionary
- func test_unit_move_request_emits_target_position() -> void
- func test_warning_flash_uses_style_metadata() -> void
- func test_feedback_float_uses_offset_and_fade() -> void
- func test_property_animation_invokes_callback() -> void

### tests/test_animation_request_service_extended.gd
- func _make_service() -> AnimService
- func after_test() -> void
- func test_on_unit_moved_emits_animation_requested() -> void
- func test_on_unit_moved_ignores_invalid_index() -> void
- func test_on_unit_moved_ignores_null_unit_manager() -> void

### tests/test_animation_style_set_and_hover_states.gd
- func _make_style(id: StringName) -> AnimationStyle
- func test_get_style_finds_matching_style() -> void
- func test_get_style_returns_null_for_unknown_id() -> void
- func test_get_style_returns_null_for_empty_set() -> void
- func test_get_style_returns_first_match() -> void
- func test_get_style_skips_null_entries() -> void
- func get_terrain(_cell: Vector2i) -> Variant
- func index_of_unit_at(_cell: Vector2i) -> int
- func get_unit(_idx: int) -> Variant
- func get_location_data_at_coordinate(_cell: Vector2i) -> Dictionary
- func get_task_at_coord(_cell: Vector2i) -> Dictionary
- func _init() -> void
- func calculate_distance_to_cell(_cell: Vector2i) -> String
- func test_terrain_hover_can_enter_false_when_no_terrain_map() -> void
- func test_terrain_hover_can_enter_false_when_null_terrain() -> void
- func test_terrain_hover_update_emits_signal() -> void
- func test_location_hover_can_enter_false_when_no_service() -> void
- func test_location_hover_can_enter_false_when_empty_data() -> void
- func test_location_hover_can_enter_true_when_data_present() -> void
- func test_location_hover_update_emits_signal() -> void
- func test_task_hover_can_enter_false_when_no_task_controller() -> void
- func test_task_hover_can_enter_false_when_no_task_at_coord() -> void
- func test_task_hover_can_enter_true_when_task_present() -> void
- func test_task_hover_update_emits_signal() -> void
- func after_test() -> void

### tests/test_auto_battle_diagnostics.gd
- func show_warning_message(text: String) -> void
- func test_report_unsupported_actions_records_history() -> void

### tests/test_auto_battle_service_extended.gd
- func is_queue_empty() -> bool
- func get_turn_queue() -> Array
- func get_current_unit_index() -> int
- func get_current_side() -> int
- func is_player_controlled(_idx: int) -> bool
- func test_auto_battle_force_disable() -> void
- func test_auto_battle_maybe_run_turn_aborts_if_disabled() -> void

### tests/test_autoload_functions.gd
- func before_test() -> void
- func test_audio_bus_controller_set_and_get_volume_db() -> void
- func test_audio_bus_controller_mute_bus_reflects_state() -> void
- func test_audio_bus_controller_play_music_assigns_stream_and_bus() -> void
- func test_audio_bus_controller_stop_music_halts_playback() -> void
- func test_event_bus_show_feedback_message_emits_correctly() -> void
- func test_game_config_set_value_emits_signal() -> void
- func test_game_config_save_and_load_round_trip() -> void
- func test_input_mapper_map_action_registers_keys_and_buttons() -> void
- func test_input_mapper_apply_configs_uses_fallback_when_empty() -> void
- func _capture_feedback(msg: String) -> void
- func _capture_event(event_name: String, payload) -> void
- func _reset_config_signal_state() -> void
- func _capture_config_change(path: String, value) -> void
- func _delete_user_file(path: String) -> void
- func _get_music_player() -> AudioStreamPlayer
- func _has_key_event(events: Array, keycode: Key) -> bool
- func _has_button_event(events: Array, button_index: JoyButton) -> bool

### tests/test_camera_controller.gd
- func test_toggle_free_cam() -> void

### tests/test_camera_handler.gd
- func before_test() -> void
- func after_test() -> void
- func test_get_camera_rotation() -> void
- func test_rotate_camera() -> void
- func test_zoom_method() -> void
- func test_zoom_clamping() -> void
- func test_set_initial_rotation() -> void
- func test_set_free_cam() -> void
- func test_init_camera_snap() -> void
- func test_rotation_snapping_and_wrapping() -> void

### tests/test_checkpoint_manager_extended.gd
- func create_memento()
- func restore_from_memento(_c)
- func create_memento()
- func restore_from_memento(_c)
- func create_memento()
- func restore_from_memento(_c)
- func show_feedback(m: String) -> void
- func center_on_selected() -> void
- func get_grid() -> TileMapLayer
- func get_terrain_map() -> TerrainMap
- func update_range_indicator(_g, _u, _m) -> void
- func test_checkpoint_manager_on_undo_redo_requested() -> void

### tests/test_click_to_move.gd
- func _register(node: Node) -> Node
- func _get_screen_pos(scene: Node2D, coord: Vector2i) -> Vector2
- func test_click_to_move_single_hex() -> void
- func test_click_to_move_multi_hex_path() -> void
- func test_click_to_move_cannot_move_out_of_range() -> void
- func test_move_controller_request_move_to_coord_moves_unit()
- func test_confirm_move_consumes_incremental_cost() -> void
- func _make_enemy_roster_definition(coords: Array[Vector2i]) -> UnitRosterDefinition
- func test_confirm_move_requires_warning_when_leaving_threatened_hex() -> void

### tests/test_click_to_move_paths.gd
- func test_click_to_move_path_exists() -> void
- func test_move_controller_exists() -> void
- func test_hex_navigator_has_pathfind() -> void
- func test_game_config_has_movement_constants() -> void

### tests/test_combat_action_calculator.gd
- func get_friendly_units() -> Array[Unit]
- func get_hostile_units() -> Array[Unit]
- func get_adjacent_units(p_units: Array, _max_range: float = 1.0) -> Array[Unit]
- func _make_reach_state(coords: Array[Vector2i]) -> Dictionary
- func _make_unit(faction: Unit.Faction, wp: int, max_wp: int) -> Unit
- func after_test() -> void
- func test_append_combat_actions_includes_adjacent_attack() -> void
- func test_append_combat_actions_includes_adjacent_aid() -> void

### tests/test_combat_and_turn_extended.gd
- func _make_target(val: int) -> Target
- func test_combat_system_get_combat_forecast() -> void
- func test_combat_system_get_attack_of_opportunity_forecast() -> void
- func on_checkpoint_requested() -> void
- func test_turn_controller_on_turn_changed_checkpoints() -> void

### tests/test_combat_priority_profile.gd
- func _make_profile() -> CombatPriorityProfile
- func test_get_weight_attack_returns_10() -> void
- func test_get_weight_finish_low_hp_returns_6() -> void
- func test_get_weight_protect_ally_returns_5() -> void
- func test_get_weight_objective_returns_5() -> void
- func test_get_weight_avoid_risk_returns_4() -> void
- func test_get_weight_flank_returns_3() -> void
- func test_get_weight_retreat_returns_2() -> void
- func test_get_weight_fallback_uses_priority_order() -> void
- func test_get_weight_unknown_key_returns_zero() -> void
- func test_get_weight_custom_weight_table_overrides() -> void
- func test_get_weight_earlier_priority_has_higher_fallback() -> void

### tests/test_combat_stats.gd
- func test_set_attribute_grit() -> void
- func test_set_attribute_flow() -> void
- func test_set_attribute_gusto() -> void
- func test_set_attribute_focus() -> void
- func test_set_attribute_shine() -> void
- func test_set_attribute_shade() -> void
- func test_set_attribute_willpower() -> void
- func test_set_attribute_case_insensitive() -> void
- func test_set_attribute_unknown_name_is_noop() -> void
- func test_set_attribute_zero() -> void
- func test_set_attribute_negative() -> void
- func test_init_with_custom_values() -> void
- func test_get_attribute_unknown_returns_zero() -> void

### tests/test_combat_system.gd
- func before_test() -> void
- func test_execute_combat_null_attacker() -> void
- func test_execute_combat_null_defender() -> void
- func test_execute_combat_both_null() -> void
- func test_execute_combat_returns_dictionary() -> void
- func test_execute_combat_with_valid_units() -> void

### tests/test_command_coverage.gd
- func test_command_result_is_success_returns_true_for_success() -> void
- func test_command_result_is_success_returns_false_for_failure() -> void
- func test_command_result_is_failure_returns_true_for_failure() -> void
- func test_command_result_is_failure_returns_false_for_success() -> void
- func test_command_result_get_description_returns_description() -> void
- func test_command_result_get_description_returns_empty_for_success() -> void
- func test_game_command_context_get_field_returns_unit_manager() -> void
- func test_game_command_context_get_field_returns_hex_navigator() -> void
- func test_game_command_context_get_field_returns_camera_controller() -> void
- func test_game_command_context_get_field_returns_move_controller() -> void
- func test_game_command_context_get_field_returns_dialogue_service() -> void
- func test_game_command_context_get_field_returns_turn_controller() -> void
- func test_game_command_context_get_field_returns_location_controller() -> void
- func test_game_command_context_get_field_returns_tilemap() -> void
- func test_game_command_context_get_field_returns_null_for_invalid() -> void
- func test_game_command_context_get_grid_dimensions_returns_vector2i() -> void
- func test_game_command_context_get_selected_unit_index_returns_int() -> void
- func test_game_command_get_required_context_fields_returns_packed_string_array() -> void
- func test_game_command_validate_context_succeeds_with_valid_context() -> void
- func test_aid_ally_command_get_required_context_fields_returns_array() -> void
- func test_attack_unit_command_get_required_context_fields_returns_array() -> void
- func test_joy_move_command_get_required_context_fields_returns_array() -> void
- func test_loot_command_get_required_context_fields_returns_array() -> void
- func test_move_action_command_get_required_context_fields_returns_array() -> void
- func test_primary_action_command_get_required_context_fields_returns_array() -> void
- func test_selection_cycle_command_get_required_context_fields_returns_array() -> void
- func test_select_index_command_get_required_context_fields_returns_array() -> void
- func test_toggle_free_cam_command_get_required_context_fields_returns_array() -> void
- func test_wait_command_get_required_context_fields_returns_array() -> void
- func test_explore_command_get_required_context_fields_returns_array() -> void
- func test_zoom_camera_command_get_required_context_fields_returns_array() -> void

### tests/test_command_result.gd
- func test_success() -> void
- func test_failed() -> void
- func test_invalid_context() -> void
- func test_invalid_payload() -> void
- func test_precondition_failed() -> void
- func test_default_values() -> void

### tests/test_connectivity_validation.gd
- func test_connectivity_failure_with_ring() -> void
- func test_connectivity_success_no_ring() -> void
- func test_connectivity_failure_start_impassable() -> void

### tests/test_controls_menu.gd
- func before_test() -> void
- func after_test() -> void
- func test_back_button_emits_signal() -> void
- func test_reset_button_triggers_reset() -> void

### tests/test_controls_reset.gd
- func after_test() -> void
- func before_test() -> void
- func test_reset_inputs_to_defaults_restores_settings() -> void

### tests/test_controls_settings.gd
- func before_test() -> void
- func after_test() -> void
- func test_custom_move_action_registers_key_binding() -> void
- func test_interaction_actions_register_mouse_buttons() -> void

### tests/test_dialogue_action_service.gd
- func _create_trigger(coord: Vector2i, initiator: StringName, partner: StringName, group_id: StringName = StringName("")
- func _prepare_service() -> DialogueActionService
- func test_append_dialogue_actions_adds_talk_entry() -> void
- func test_start_dialogue_consumes_action_and_sets_flag() -> void
- func test_trigger_group_marks_all_seen() -> void
- func test_leader_placeholder_matches_active_leader() -> void
- func test_partner_initiation_allows_reverse_start() -> void

### tests/test_dialogue_action_service_extended.gd
- func _init(id: StringName = &"") -> void
- func requires_initiator_action() -> bool
- func mark_seen(_b := false) -> void
- func reset_seen() -> void
- func _init() -> void
- func _make_service() -> DialogueActionService
- func after_test() -> void
- func test_prepare_for_level_replaces_active_triggers() -> void
- func test_get_trigger_at_finds_by_coord() -> void
- func test_has_active_dialogue_with_matches_unit() -> void
- func test_trigger_assign_coord_on_grid() -> void

### tests/test_dialogue_extended_2.gd
- func get_unit_count() -> int
- func get_unit(_idx) -> Unit
- func get_selected_unit() -> Unit
- func get_unit_index(_u) -> int
- func get_coord(_u) -> Vector2i
- func _add_and_free(node: Node) -> Node
- func test_dialogue_action_trigger_at_coord() -> void
- func test_dialogue_action_handle_dialogue_request() -> void

### tests/test_dialogue_trigger.gd
- func _make_entry(initiator: StringName = &"", partner: StringName = &"", label: String = "") -> LevelDialogueEntry
- func _make_trigger(entry: LevelDialogueEntry = null) -> DialogueTrigger
- func after_test() -> void
- func test_get_action_label_uses_entry_action_label_when_set() -> void
- func test_get_action_label_formats_talk_to_with_partner_display_name() -> void
- func test_get_action_label_falls_back_to_entry_partner_name() -> void
- func test_get_action_label_no_entry_formats_with_provided_name() -> void
- func test_get_action_label_empty_everything_produces_talk_to_empty() -> void
- func test_get_dialogue_resource_returns_null_when_no_entry() -> void
- func test_get_dialogue_resource_returns_null_when_path_empty() -> void
- func test_get_dialogue_resource_returns_cached_value_on_hit() -> void
- func test_get_dialogue_resource_returns_null_for_nonexistent_path() -> void
- func test_matches_partner_false_when_null_unit() -> void
- func test_matches_partner_false_when_no_entry() -> void
- func test_matches_partner_true_when_partner_name_empty_any_unit_matches() -> void
- func test_matches_partner_true_when_unit_name_matches() -> void
- func test_matches_partner_false_when_unit_name_does_not_match() -> void

### tests/test_dialogue_trigger_evaluator.gd
- func test_is_trigger_available() -> void
- func test_collect_partner_and_initiator_indices() -> void
- func test_build_dialogue_action() -> void

### tests/test_dialogue_trigger_group.gd
- func mark_seen(from_group := false) -> void
- func reset_seen() -> void
- func test_register_trigger_adds_member() -> void
- func test_register_trigger_null_is_ignored() -> void
- func test_register_trigger_duplicate_not_added_twice() -> void
- func test_register_trigger_when_group_already_seen_calls_mark_seen_immediately() -> void
- func test_mark_seen_sets_group_seen() -> void
- func test_mark_seen_propagates_to_all_members() -> void
- func test_mark_seen_idempotent() -> void
- func test_reset_clears_group_and_members() -> void

### tests/test_difficulty_service.gd
- func _make_service() -> Node
- func after_test() -> void
- func test_get_ai_scaling_factor() -> void
- func test_get_ai_morale_weight() -> void
- func test_get_retreat_threshold() -> void
- func test_get_combat_modifier() -> void

### tests/test_display_settings.gd
- func before_test() -> void
- func after_test() -> void
- func test_get_standard_resolutions_includes_landscape_options() -> void
- func test_set_orientation_switches_current_resolution_pool() -> void
- func test_set_resolution_index_clamps_to_available_range() -> void
- func test_display_orientation_string_conversions() -> void

### tests/test_enemy_roster.gd
- func before_test() -> void
- func test_get_enemy_scene_valid_index() -> void
- func test_get_enemy_scene_invalid_index() -> void
- func test_get_enemy_scene_empty_roster() -> void
- func test_get_random_enemy_scene_empty() -> void
- func test_get_random_enemy_scene_single() -> void
- func test_get_random_enemy_scene_multiple() -> void

### tests/test_file_paths_loader.gd
- func _make_loader(injected_dict: Dictionary) -> FilePathsLoader
- func test_get_path_single_level_key() -> void
- func test_get_path_two_level_dot_notation() -> void
- func test_get_path_three_level_dot_notation() -> void
- func test_get_path_missing_key_returns_empty_and_logs_error() -> void
- func test_get_path_value_not_string_returns_empty_and_logs_error() -> void
- func test_get_category_returns_dict_for_known_category() -> void
- func test_get_category_missing_category_returns_empty() -> void
- func test_get_category_value_not_dict_returns_empty() -> void
- func test_get_warnings_returns_warnings_from_meta() -> void
- func test_get_warnings_empty_when_no_meta() -> void
- func test_get_warnings_empty_when_meta_has_no_warnings_key() -> void
- func test_get_dynamic_paths_returns_dynamic_section() -> void
- func test_get_dynamic_paths_empty_when_missing() -> void
- func test_print_summary_does_not_crash() -> void
- func test_validate_paths_detects_valid_resources() -> void
- func test_validate_paths_detects_missing_resources() -> void
- func test_validate_paths_checks_directory_paths() -> void

### tests/test_game_objective_controller_extended.gd
- func get_task_by_id(id: String) -> Task
- func test_get_target_task_delegates_to_task_manager() -> void
- func test_create_target_texture_returns_image_texture() -> void

### tests/test_game_session_builder.gd
- func before_test() -> void
- func test_builder_returns_context_with_dependencies() -> void
- func test_builder_assigns_dialogue_service_to_command_context() -> void
- func test_builder_uses_custom_service_factory() -> void
- func test_builder_uses_assigned_roster_loader() -> void
- func _create_builder_config() -> GameSessionBuilder.Config
- func create_services() -> Dictionary
- func load_player_roster(provided_roster: PlayerRoster, save_manager: Node, fallback_path: String = DEFAULT_PLAYER_ROSTER_PATH) -> PlayerRoster
- func load_enemy_roster(provided_roster: EnemyRoster, fallback_path: String = DEFAULT_ENEMY_ROSTER_PATH) -> EnemyRoster
- func load_neutral_roster(provided_roster: NeutralRoster, fallback_path: String = DEFAULT_NEUTRAL_ROSTER_PATH) -> NeutralRoster

### tests/test_game_session_extended.gd
- func get_current_side() -> int
- func get_turn_system() -> FakeTurnSystem
- func set_enabled(value: bool) -> void
- func start_next_turn() -> void
- func reset_joy_state() -> void
- func set_process_unhandled_input(val: bool) -> void
- func set_physics_process(val: bool) -> void
- func test_game_session_handle_pause_state_changed() -> void
- func test_game_session_disable_gameplay() -> void

### tests/test_gameplay_analog.gd
- func apply_configs(_actions: Array, _defaults: Array = []) -> void
- func before_test() -> void
- func after_test() -> void
- func _set_axis(scene: Node, axis: Vector2) -> void
- func _wait_for_player_coord_change(runner, scene, old_coord: Vector2i, max_frames: int) -> bool

### tests/test_gameplay_camera.gd
- func _action_event(action: String) -> InputEventAction
- func before_test() -> void
- func after_test() -> void
- func test_camera_is_current_on_ready() -> void
- func test_camera_rotate_and_zoom_do_not_affect_movement() -> void
- func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level

### tests/test_gameplay_freecam.gd
- func _action_event(action: String) -> InputEventAction
- func before_test() -> void
- func after_test() -> void
- func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level
- func test_toggle_free_cam_action() -> void
- func test_free_cam_disables_centering_on_selection_cycle() -> void

### tests/test_gameplay_level_loading.gd
- func before_test() -> void
- func after_test() -> void

### tests/test_gameplay_selection_mouse.gd
- func before_test() -> void
- func after_test() -> void
- func test_camera_centers_on_selected_when_cycled() -> void
- func test_primary_action_selects_unit() -> void
- func test_primary_action_moves_unit() -> void
- func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level

### tests/test_gameplay_task.gd
- func before_test() -> void
- func after_test() -> void
- func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level
- func test_gameplay_scene_builds_locations() -> void
- func test_interact_location_triggers_task_manager() -> void

### tests/test_gameplay_turns.gd
- func before_test() -> void
- func after_test() -> void
- func _expected_coord_for(action: String, index: int) -> Vector2i
- func test_player_unit_cannot_move_twice_before_turn_resets() -> void
- func test_enemy_units_are_consumed_between_player_moves() -> void
- func test_wait_skips_to_next_available_unit() -> void

### tests/test_gameplay_units.gd
- func before_test() -> void
- func after_test() -> void
- func _expected_coord_for(index: int, action: String) -> Vector2i
- func test_unit_cannot_move_into_occupied_tile() -> void
- func test_cannot_select_enemy_unit_via_click() -> void
- func test_cycling_skips_enemy_units() -> void
- func test_dynamic_control_change() -> void
- func test_enemies_spawn_from_level_resource() -> void
- func _make_enemy_roster_definition(coords: Array[Vector2i]) -> UnitRosterDefinition
- func test_gameplay_set_unit_controlled_by_player_updates_unit_manager_and_roster()

### tests/test_grid_and_sprite_scale.gd
- func _assert_equal(actual, expected, message: String) -> void
- func _assert_not_null(value, message: String) -> void
- func test_grid_tile_size_is_96x96() -> void
- func test_generic_unit_sprite_scale_is_0_5() -> void
- func test_generic_enemy_sprite_scale_is_0_5() -> void
- func test_location_sprite_scale_is_0_5() -> void

### tests/test_grid_extended.gd
- func _add_and_free(node: Node) -> Node
- func test_map_controller_on_loot_added() -> void
- func has_active_dialogue_with(_u1, _u2) -> bool
- func _init(p)
- func get_units() -> Array
- func get_selected_unit() -> Unit
- func get_selected_index() -> int
- func is_player_controlled(idx: int) -> bool
- func is_within_bounds(_c)
- func test_grid_visuals_methods() -> void

### tests/test_grid_visuals_extended.gd
- func _make_visuals() -> Node2D
- func after_test() -> void
- func test_update_hover_indicator() -> void
- func test_update_terrain_overlay() -> void
- func test_toggle_enemy_range_view() -> void
- func test_show_threatened_path_hex() -> void
- func test_update_path_preview() -> void

### tests/test_gui_extended.gd
- func _add_and_free(node: Node) -> Node
- func test_action_panel_focus_first_button() -> void
- func test_action_panel_update_actions_missing_unit() -> void
- func test_combat_preview_panel_show_forecast() -> void
- func test_feedback_display_show_feedback() -> void
- func test_journal_ui_find_item() -> void
- func test_location_display_item() -> void
- func test_task_display_item() -> void
- func test_task_list_item() -> void
- func test_lists_panels_empty() -> void
- func test_morale_panel_update_morale_display() -> void
- func test_morale_panel_faction_label_to_id() -> void

### tests/test_gui_info.gd
- func _init(_unit_ref: Unit) -> void
- func has_tentative_move() -> bool
- func has_move_available() -> bool
- func get_selected_unit() -> Unit
- func get_selected_index() -> int
- func register_unit(unit: Unit, index: int, coord: Vector2i = Vector2i.ZERO) -> void
- func get_unit_index(unit: Unit) -> int
- func get_coord(index: int) -> Vector2i
- func _execute_command(command_name: String, payload = null) -> CommandResult
- func before_test() -> void
- func after_test() -> void
- func test_wait_action_executes_wait_command() -> void
- func test_action_aborts_when_no_selected_unit() -> void
- func test_wait_action_confirms_tentative_move_before_wait() -> void
- func test_attack_action_routes_payload_to_input_controller() -> void
- func test_show_warning_message_creates_overlay() -> void
- func _create_test_unit() -> Unit
- func _get_command_names() -> Array

### tests/test_handlers_extended.gd
- func _make_unit() -> Unit
- func after_test() -> void
- func test_unit_death_handler_die() -> void
- func test_unit_interaction_handler_work_on_task_fails_without_task() -> void
- func can_be_worked_on_by(_u: Unit, _c: Vector2i = Vector2i.ZERO) -> bool
- func interact(u: Unit, _ctx: Dictionary = {}) -> void
- func test_unit_interaction_handler_work_on_task_succeeds() -> void

### tests/test_hex_navigator.gd
- func test_get_neighbor_offsets_for_odd_column_includes_down_right() -> void
- func test_get_neighbor_offsets_for_even_column_excludes_down_right_diagonal() -> void

### tests/test_hex_navigator_extended.gd
- func map_to_local(coord: Vector2i) -> Vector2
- func test_cache_analog_vectors() -> void
- func test_get_action_from_joy_axis() -> void

### tests/test_hometown_pop_watch.gd
- func get_levels() -> Array[Dictionary]
- func get_all_skits() -> Array[Skit]
- func mark_skit_seen(_id: String) -> void
- func before_test() -> void
- func after_test() -> void
- func _make_service(level_ids: Array, skits: Array[Skit]) -> HometownProgressionService
- func _make_skit(level_id: String, seen: bool, unlocked: bool, path: String = "res://d.dialogue") -> Skit
- func test_pop_skit_returns_null_when_no_skits() -> void
- func test_pop_skit_returns_null_when_all_locked() -> void
- func test_pop_skit_returns_null_when_all_seen() -> void
- func test_pop_skit_returns_first_unlocked_unseen_skit() -> void
- func test_pop_skit_returns_earliest_by_level_order() -> void
- func test_pop_skit_skips_locked_prefers_unlocked() -> void
- func test_watch_skit_queues_dialogue_for_first_skit() -> void
- func test_watch_skit_does_nothing_when_no_skit_available() -> void
- func test_watch_skit_does_not_add_duplicate_if_called_twice() -> void

### tests/test_hometown_progression_service.gd
- func get_levels() -> Array[Dictionary]
- func get_all_skits() -> Array[Skit]
- func mark_skit_seen(_id: String) -> void
- func before_test() -> void
- func after_test() -> void
- func _make_service(level_ids: Array, skits: Array[Skit]) -> HometownProgressionService
- func _make_skit(level_id: String, seen: bool = false, unlocked: bool = true, path: String = "") -> Skit
- func test_get_all_level_ids_returns_ids_in_order() -> void
- func test_get_all_level_ids_empty_catalog() -> void
- func test_sort_skits_by_level_orders_by_catalog_index() -> void
- func test_sort_skits_does_not_mutate_original_array() -> void
- func test_filter_skits_by_unseen_returns_only_unseen() -> void
- func test_filter_skits_by_unseen_empty_when_all_seen() -> void
- func test_filter_skits_by_unseen_returns_all_when_none_seen() -> void
- func test_filter_skits_by_unlocked_returns_only_unlocked() -> void
- func test_filter_skits_by_unlocked_empty_when_all_locked() -> void
- func test_queue_dialogue_adds_path_and_emits_signal() -> void
- func test_queue_dialogue_deduplicates_same_path() -> void
- func test_queue_dialogue_allows_different_paths() -> void

### tests/test_hover_manager_extended.gd
- func set_cell_at(_c, _d) -> void
- func get_global_mouse_position() -> Vector2
- func _init() -> void
- func get_grid() -> TileMapLayer
- func test_hover_info_manager_get_occupants() -> void

### tests/test_hud_action_executor.gd
- func before_test() -> void
- func _on_menu_requested(menu_name: String, action: UnitAction) -> void
- func test_execute_action_open_attack_menu() -> void

### tests/test_hud_action_select_extended.gd
- func get_selected_unit() -> Unit
- func get_selected_index() -> int
- func get_unit_index(_u) -> int
- func _execute_command(cmd_name: String, _args = {}) -> CommandResult
- func _add_and_free(node: Node) -> Node
- func test_hud_on_action_selected_dispatch() -> void

### tests/test_hud_and_weather_extended.gd
- func _add_and_free(node: Node) -> Node
- func test_weather_panel_update_compass() -> void
- func test_pause_handler_show_pause_menu() -> void
- func test_aim_cursor_connect_input_handler() -> void
- func test_hud_hover_service_process_hover() -> void
- func test_hud_controller_handle_actions_updated() -> void
- func test_hud_controller_refresh_after_state_restore() -> void

### tests/test_hud_command_refresh.gd
- func test_hud_on_command_executed_emits_refresh_on_success() -> void
- func test_hud_on_command_executed_skips_refresh_on_failure() -> void

### tests/test_hud_component_factory.gd
- func test_create_components_landscape() -> void
- func test_create_components_portrait() -> void
- func test_instantiate_panel_adds_child() -> void
- func test_create_button_applies_spec() -> void

### tests/test_hud_controller_actions.gd
- func test_on_hud_action_executed_reemits_actions_updated() -> void
- func test_on_hud_action_executed_ignores_attack_menu_request() -> void
- func test_task_manager_signal_updates_progress() -> void

### tests/test_hud_controller_auto_battle.gd
- func before_test() -> void
- func test_set_auto_battle_state_updates_button_and_panel() -> void
- func test_auto_battle_button_emits_toggle_signal() -> void

### tests/test_hud_controller_extended_2.gd
- func test_handle_dialogue_finished() -> void
- func test_hud_signal_connector_connect_all() -> void

### tests/test_hud_controller_nav.gd
- func enable_navigation_mode() -> void
- func disable_navigation_mode() -> void
- func test_set_ui_navigation_mode_delegates_to_actions_panel() -> void
- func test_safe_zone_mode_hides_combat_panels() -> void
- func test_safe_zone_mode_restores_panels_when_disabled() -> void

### tests/test_hud_controller_turn_counts.gd
- func is_player_controlled(index: int) -> bool
- func test_calculate_faction_turn_counts() -> void

### tests/test_hud_helpers.gd
- func _execute_command(command_name: String, payload = null) -> CommandResult
- func _init(unit: Unit) -> void
- func has_tentative_move() -> bool
- func _init()
- func before_test() -> void
- func after_test() -> void
- func test_sync_selected_unit_tracks_manager() -> void
- func test_command_success_helper_detects_status() -> void
- func test_run_input_command_returns_null_without_controller() -> void
- func test_resolve_tentative_move_confirms_command() -> void
- func test_execute_attack_and_support_commands_route_payloads() -> void
- func test_execute_loot_skill_and_talk_commands() -> void

### tests/test_hud_hover_service.gd
- func can_enter(_controller: Node, _cell: Vector2i) -> bool
- func update(_controller: Node, _cell: Vector2i) -> void
- func enter(_controller: Node, _cell: Vector2i) -> void
- func exit(_controller: Node) -> void
- func before_test() -> void
- func after_test() -> void
- func test_update_hover_info_clears_states_when_no_unit_manager() -> void
- func test_update_hover_info_clears_states_when_no_grid() -> void
- func _setup_valid_deps() -> void
- func _cleanup_valid_deps() -> void
- func test_update_hover_enters_state_when_can_enter_true() -> void
- func test_update_hover_does_not_enter_state_when_can_enter_false() -> void
- func test_update_hover_exits_state_that_no_longer_can_enter() -> void
- func test_update_hover_calls_update_for_already_active_state() -> void
- func test_update_hover_multiple_states_only_active_ones_entered() -> void
- func test_force_hover_update_does_nothing_when_grid_invalid() -> void

### tests/test_input_binding_service.gd
- func apply_configs(_configs, _defaults) -> void
- func before_test() -> void
- func after_test() -> void
- func test_apply_bindings_with_null_mapper() -> void
- func test_apply_bindings_with_mapper() -> void
- func test_apply_bindings_with_empty_settings() -> void
- func test_apply_bindings_with_null_settings() -> void
- func test_dialogue_action_mirrors_primary_bindings() -> void
- func _collect_event_signatures(action: String) -> Array
- func _event_signature(event: InputEvent) -> String
- func _clear_registered_actions() -> void
- func test_save_bindings_persists_to_file() -> void
- func test_restore_defaults_overwrites_with_empty_config() -> void

### tests/test_input_commands.gd
- func has_tentative_move() -> bool
- func block_movement_this_turn() -> void
- func block_action_this_turn() -> void
- func get_selected_coord() -> Vector2i
- func get_selected_index() -> int
- func get_unit_count() -> int
- func get_unit(index: int)
- func is_player_controlled(index: int) -> bool
- func select_index(index: int) -> void
- func cycle_selection(direction: int) -> void
- func index_of_unit_at(_cell: Vector2i) -> int
- func map_action_by_camera(action: String, _from: Vector2i, _rotation: float, _grid) -> String
- func get_rotation() -> float
- func request_move(action: String) -> void
- func request_move_tentative(action: String) -> void
- func request_move_to_coord(target_coord: Vector2i) -> void
- func is_move_locked() -> bool
- func cancel_move() -> void
- func confirm_move() -> void
- func force_action_menu_update() -> void
- func is_enabled() -> bool
- func can_act_on_index(index: int) -> bool
- func complete_player_activation(index: int) -> void
- func lock_active_player_unit(index: int) -> void
- func set_ui_navigation_mode(enabled: bool) -> void
- func execute(context: GameCommandContext, payload = null) -> CommandResult
- func apply_configs(_configs, _defaults) -> void
- func apply_bindings(controls: Node, mapper: Node) -> void
- func _on_select_index_requested(index: int) -> void
- func _on_selection_cycle_requested(direction: int) -> void
- func _on_wait_requested() -> void
- func _register_input_actions() -> void
- func test_move_action_command_requests_mapped_direction_tentative() -> void
- func test_selection_cycle_command_cycles_units_even_when_turn_locked() -> void
- func test_select_index_command_allows_selection_when_turn_locked() -> void
- func test_wait_command_respects_location_and_turn_state() -> void
- func test_input_command_router_set_commands_and_execute() -> void
- func test_input_command_router_register_command_overrides_entry() -> void
- func test_input_controller_apply_command_set_overrides_wait_command() -> void
- func test_input_controller_default_command_set_includes_wait() -> void
- func test_input_controller_request_select_index_invokes_handler() -> void
- func test_input_controller_request_selection_cycle_invokes_handler() -> void
- func test_input_controller_request_wait_invokes_handler() -> void
- func test_input_controller_register_input_actions_invokes_internal_registration() -> void
- func test_input_controller_selection_cycle_bypasses_turn_lock() -> void
- func test_input_controller_select_index_bypasses_turn_lock() -> void
- func _build_full_context() -> GameCommandContext
- func _make_control_settings() -> Node
- func _build_input_controller_for_signals(input_handler: InputHandler) -> InputController
- func _build_input_controller_with_turn_permissions(allowed_indexes: Dictionary) -> Dictionary
- func test_wait_command_blocks_actions_and_updates_ui() -> void
- func test_set_ui_navigation_mode_updates_handler_and_hud() -> void
- func test_move_to_coord_command_executes_request() -> void
- func test_move_to_coord_command_rejects_missing_payload() -> void
- func test_execute_command_skips_lock_for_tentative_move() -> void
- func test_execute_command_skips_lock_for_cancel_move() -> void
- func test_execute_command_locks_after_confirm_move() -> void

### tests/test_input_controller_auto_battle.gd
- func is_player_auto_control_locked() -> bool
- func show_warning_message(text: String) -> void
- func test_undo_blocked_when_auto_battle_locked() -> void
- func test_undo_emits_when_auto_battle_unlocked() -> void
- func _create_controller() -> Dictionary

### tests/test_input_handler.gd
- func _action_event(action: String) -> InputEventAction
- func _send_input(event: InputEvent) -> void
- func before_test() -> void
- func after_test() -> void
- func test_move_action_emits_move_requested() -> void
- func test_cycle_action_emits_selection_cycle_requested() -> void
- func test_primary_action_emits_primary_action_at() -> void
- func test_zoom_action_emits_zoom_requested() -> void
- func test_refresh_action_cache_picks_up_new_actions() -> void
- func test_reset_joy_state_clears_axis() -> void
- func test_toggle_enemy_range_requested_emitted() -> void
- func test_ui_nav_toggle_emits_signal() -> void
- func test_ui_nav_mode_blocks_move_requests() -> void

### tests/test_input_registration.gd
- func before_test() -> void
- func after_test() -> void
- func test_input_actions_are_registered_in_inputmap() -> void

### tests/test_inventory_additions.gd
- func test_unit_inventory_add_item_to_inventory_success() -> void
- func test_unit_inventory_add_item_to_inventory_null_fails() -> void
- func test_unit_inventory_add_item_to_inventory_duplicate_fails() -> void
- func test_inventory_component_add_item_to_inventory_success() -> void
- func test_inventory_component_add_item_to_inventory_null_inventory_fails() -> void

### tests/test_inventory_item.gd
- func test_duplicate_instance_preserves_values_without_regenerating_uuid() -> void
- func test_duplicate_instance_regenerates_uuid_when_requested() -> void
- func test_to_dict_contains_all_fields() -> void
- func test_from_dict_restores_all_fields() -> void
- func test_to_dict_from_dict_uuid_preserved() -> void
- func test_quest_item_recognition() -> void

### tests/test_inventory_management_menu.gd
- func before_test() -> void
- func after_test() -> void
- func _make_item(item_name: String) -> InventoryItem
- func test_handle_item_drop_stash_to_stash() -> void
- func test_handle_item_drop_stash_to_unit() -> void
- func test_handle_item_drop_unit_to_stash() -> void
- func test_handle_item_drop_unit_to_unit() -> void

### tests/test_item_registry_race.gd
- func test_lazy_loading_templates() -> void

### tests/test_item_system.gd
- func before_test() -> void
- func test_item_registry_instancing() -> void
- func test_item_serialization() -> void

### tests/test_journal_data.gd
- func before_test() -> void
- func _make_section(id: String, title: String = "Section") -> JournalSection
- func _make_topic(id: String, section_id: String, title: String = "Topic") -> JournalTopic
- func _make_entry(id: String, topic_id: String, section_id: String = "sec", unlocked: bool = false) -> LevelJournalEntry
- func test_add_section_stores_section() -> void
- func test_add_section_duplicate_id_ignored() -> void
- func test_add_topic_stores_topic() -> void
- func test_add_topic_auto_creates_missing_section() -> void
- func test_add_topic_registers_in_section() -> void
- func test_add_topic_duplicate_ignored() -> void
- func test_add_entry_stores_entry() -> void
- func test_add_entry_auto_creates_topic_when_missing() -> void
- func test_add_entry_registers_in_topic() -> void
- func test_add_entry_duplicate_ignored() -> void
- func test_replace_entry_updates_existing() -> void
- func test_replace_entry_adds_when_not_yet_present() -> void
- func test_replace_entry_removes_from_old_topic() -> void
- func test_get_unlocked_topics_empty_when_no_entries_unlocked() -> void
- func test_get_unlocked_topics_returns_topic_with_unlocked_entry() -> void
- func test_get_unlocked_topics_empty_for_missing_section() -> void
- func test_get_unlocked_entries_returns_only_unlocked() -> void
- func test_get_unlocked_entries_empty_for_missing_topic() -> void
- func test_get_all_unlocked_entries_empty_when_none_unlocked() -> void
- func test_get_all_unlocked_entries_returns_all_unlocked_across_topics() -> void

### tests/test_journal_manager_extended.gd
- func _make_manager() -> JournalManagerScript
- func test_unlock_entry_succeeds() -> void
- func test_unlock_entry_fails_on_missing() -> void
- func test_unlock_coupled_entry_creates_and_unlocks() -> void
- func test_clear_journal() -> void

### tests/test_level_auto_fix_service.gd
- func _make_level(rows: Array[String]) -> Level
- func _make_report_stub() -> Dictionary
- func test_apply_moves_location_from_impassable_tile() -> void
- func test_apply_relocates_overlapping_player_start() -> void
- func test_build_context_exposes_helpers() -> void
- func test_repair_locations_updates_report() -> void
- func test_repair_player_starts_handles_overlap() -> void
- func test_repair_neutral_starts_updates_entries() -> void
- func test_apply_respects_enemy_spawns_from_start_rows() -> void
- func test_repair_task_metadata_handles_missing_params() -> void

### tests/test_level_builder.gd
- func _spawn_unit(_scene: PackedScene, _coord: Vector2i, _is_player: bool, _is_neutral: bool, _modulate: Color = Color.WHITE, _inventory: Array[InventoryItem] = []) -> void
- func _make_stub_scene(label: String) -> PackedScene
- func _make_unit_scene_with_willpower(current: int, max_value: int) -> PackedScene
- func test_spawn_player_units_exhausts_roster() -> void
- func test_spawn_unit_resets_player_willpower_to_max() -> void
- func test_spawn_unit_does_not_change_enemy_willpower() -> void
- func _log_impassable_location(coord: Vector2i) -> void
- func test_logs_when_location_on_impassable_tile() -> void
- func test_location_passable_when_tile_allows() -> void
- func test_build_resets_loot_manager_before_spawning() -> void
- func test_hometown_neutral_roster_skips_by_unit_name() -> void
- func test_should_skip_neutral_spawn_by_hometown_coord() -> void
- func test_hometown_spawns_player_leader_unit() -> void
- func _make_level_build_context() -> LevelBuildContext
- func _cleanup_level_build_context(context: LevelBuildContext) -> void
- func _make_unit_scene_with_name(unit_name: String) -> PackedScene

### tests/test_level_builder_extended.gd
- func test_build_environment() -> void
- func test_spawn_global_content() -> void

### tests/test_level_catalog_extended.gd
- func test_get_level_by_id() -> void
- func test_find_level_by_path() -> void

### tests/test_level_chaining.gd
- func before_test() -> void
- func after_test() -> void
- func _vector_to_action(scene: Node, from: Vector2i, delta: Vector2i) -> String
- func _await_scene_change(runner: GdUnitSceneRunner, tree: SceneTree, context: String) -> void

### tests/test_level_dialogue_entry.gd
- func test_get_flag_id_uses_flag_name_when_set() -> void
- func test_get_flag_id_falls_back_to_resource_path() -> void
- func test_get_flag_id_falls_back_to_name_pair() -> void
- func test_get_flag_id_returns_hash_when_all_empty() -> void
- func test_get_flag_id_name_pair_requires_both_names() -> void
- func test_get_flag_id_priority_flag_name_over_path() -> void

### tests/test_level_factory.gd
- static func create_default() -> TestLevel
- static func create_with_player_location(
- static func create_multi_unit(
- static func create_custom(

### tests/test_level_flow_controller_extended.gd
- func test_start_level() -> void
- func test_start_first_level() -> void
- func test_handle_level_complete() -> void
- func test_handle_quit_to_title() -> void

### tests/test_level_manager.gd
- func before_test() -> void
- func after_test() -> void
- func test_connects_signals_manually() -> void

### tests/test_level_manager_gameplay.gd
- func _is_hometown_level(_level: Level) -> bool
- func set_free_roam_mode(enabled: bool) -> void
- func _init(units: Array, player_indices: Array[int]) -> void
- func get_unit_count() -> int
- func is_player_controlled(index: int) -> bool
- func get_unit(index: int)
- func _init() -> void
- func test_handle_selected_unit_move_emits_once_exit() -> void
- func test_handle_selected_unit_move_ignores_non_hometown_or_coord() -> void
- func test_apply_hometown_rules_toggle_free_roam_for_player_unit() -> void
- func _make_manager() -> StubLevelManagerGameplay
- func _cleanup_manager(manager: StubLevelManagerGameplay) -> void

### tests/test_level_manager_gameplay_extended.gd
- func handle_event(event_name: String, _payload: Dictionary = {}) -> void
- func is_task_reached() -> bool
- func check_objective_conditions() -> void
- func reset_task_state() -> void
- func prepare_for_level(lvl: Level) -> void
- func update_roster(p_units: Array[Unit], _full_reset: bool = false) -> void
- func add_to_stash(items: Array) -> void
- func get_selected_index() -> int
- func get_unit_count() -> int
- func is_player_controlled(_idx: int) -> bool
- func collect_all_loot_items() -> Array
- func before_test() -> void
- func after_test() -> void
- func _make_manager() -> LevelManagerGameplay
- func test_set_dialogue_service_connects_signal_and_prepares() -> void
- func test_update_task_progress_checks_conditions_and_updates_state() -> void
- func test_on_unit_moved_emits_quit_if_hometown_exit_reached() -> void
- func test_on_task_reached_updates_roster_and_emits_complete() -> void

### tests/test_level_manager_gameplay_extended_2.gd
- func _make_manager() -> LevelManagerGameplay
- func test_set_save_manager() -> void
- func test_set_auto_fix_enabled() -> void
- func test_prepare_level_data() -> void
- func test_clear_world() -> void
- func test_build_environment() -> void
- func test_spawn_global_content() -> void

### tests/test_level_repairers.gd
- func test_repairers() -> void

### tests/test_level_roster_service_extended.gd
- func get_leader_unit_name() -> String
- func set_leader_unit_name(v: String) -> void
- func test_refresh_player_roster() -> void
- func test_determine_leader_name() -> void

### tests/test_level_row_loader.gd
- func _inject(loader
- func _create_level() -> Level
- func test_apply_rows_populates_spawns_and_entries() -> void
- func _create_loot_entry(level_id: StringName, coord: Vector2i, items: Array[InventoryItem]) -> LevelLootEntry
- func _create_location_entry(level_id: StringName, coord: Vector2i, scene: PackedScene) -> LevelTaskEntry
- func _create_unit_spawn_entry(level_id: StringName, coord: Vector2i, faction: int, slot: int, scene: PackedScene = null) -> LevelUnitSpawnEntry
- func _create_dialogue_entry(level_id: StringName, entry_id: StringName, coord: Vector2i, path: String) -> LevelDialogueEntry
- func _create_journal_entry(level_id: StringName, id: String, related_id: String) -> LevelJournalEntry
- func _verify_level_entities(level: Level, neutral_start: LevelUnitSpawnEntry, enemy_start: LevelUnitSpawnEntry) -> void
- func test_duplicate_roster_rows_reported() -> void
- func test_out_of_bounds_location_reported() -> void
- func test_duplicate_start_coordinate_reported() -> void
- func test_dialogue_missing_timeline_reported() -> void
- func test_auto_fix_moves_location_from_impassable_tile() -> void
- func test_rows_for_level_returns_keyed_arrays() -> void
- func test_apply_rows_to_level_with_null_objective() -> void

### tests/test_level_row_loader_extended.gd
- func test_level_row_loader_refresh_for_level_caches() -> void

### tests/test_level_select_hometown.gd
- func get_available_levels() -> Array
- func start_level_by_id(_id: String) -> void
- func get_value(key: String, default: Variant = null)
- func _add_autoload_stub(node: Node) -> void
- func _remove_autoload_stub(node: Node) -> void
- func test_hometown_listed_first_and_repeatable() -> void

### tests/test_level_state_controller_extended.gd
- func test_get_task_reached_state() -> void
- func test_set_task_reached_state() -> void
- func test_update_safe_zone_ui() -> void

### tests/test_level_state_controller_retreats.gd
- func test_handle_player_defeat() -> void
- func test_handle_enemy_retreat() -> void
- func test_handle_neutral_retreat() -> void

### tests/test_locale_service.gd
- func _make_service() -> Node
- func after_test() -> void
- func test_apply_locale_settings() -> void

### tests/test_localization_strings.gd
- func test_supported_languages_include_defaults() -> void
- func test_get_text_returns_spanish_value() -> void
- func test_get_text_handles_region_variants() -> void
- func test_get_text_falls_back_to_default_language_when_missing_language() -> void
- func test_get_text_returns_key_when_missing_entry() -> void
- func test_round_label_template_formats_value() -> void
- func test_enemy_fallback_translates() -> void

### tests/test_location_action_provider_extended.gd
- func test_location_action_provider_append_location_action() -> void

### tests/test_location_exploration.gd
- func test_explore_action_added() -> void
- func test_reachable_explore_action_added() -> void
- func test_abstract_task_no_action() -> void

### tests/test_location_service_extended.gd
- func test_location_service_explore_location() -> void
- func test_location_service_visit_location() -> void

### tests/test_loot.gd
- func _make_loot() -> Loot
- func _make_item(item_name: String) -> InventoryItem
- func after_test() -> void
- func test_hover_info_empty_loot_shows_empty() -> void
- func test_hover_info_with_items_lists_names() -> void
- func test_hover_info_does_not_show_empty_when_items_present() -> void
- func test_add_items_appends_inventory_items() -> void
- func test_add_items_ignores_non_inventory_item_entries() -> void
- func test_add_items_mixed_array_only_adds_valid() -> void
- func test_is_empty_true_when_no_items() -> void
- func test_is_empty_false_after_add() -> void
- func test_take_all_items_returns_copies() -> void
- func test_take_all_items_clears_inventory() -> void

### tests/test_loot_action_provider.gd
- func _init() -> void
- func get_loot_at(coord: Vector2i) -> Loot
- func get_loot_count() -> int
- func get_loot(index: int) -> Loot
- func get_coord(index: int) -> Vector2i
- func add_fake_loot(loot: Loot, coord: Vector2i) -> void
- func can_be_looted_by(_u: Unit, _d: float = 0.0) -> bool
- func is_type_loot() -> bool
- func get_loot_manager() -> LootManager
- func test_append_loot_action_adds_immediate_and_reachable() -> void
- func test_append_loot_action_changes_label_for_traps() -> void
- func test_append_loot_action_no_loot_returns_empty() -> void

### tests/test_loot_manager.gd
- func test_take_all_items_clears_inventory() -> void
- func test_collect_all_loot_items_removes_entries() -> void
- func test_collect_routing_pool() -> void

### tests/test_managers_extended.gd
- func test_location_service_get_all_locations_data() -> void
- func test_unit_controller_configure_dependencies() -> void
- func create_memento() -> Dictionary
- func restore_from_memento(_d) -> void
- func create_memento() -> Dictionary
- func restore_from_memento(_d) -> void
- func create_memento() -> Dictionary
- func restore_from_memento(_d) -> void
- func test_checkpoint_manager_history_and_redo() -> void

### tests/test_map_controller_extended.gd
- func test_map_controller_build_grid() -> void

### tests/test_menu_callbacks.gd
- func before_test() -> void
- func after_test() -> void
- func test_credits_set_return_delay() -> void
- func test_title_screen_set_quit_callback() -> void

### tests/test_misc_coverage.gd
- func test_dialogue_state_methods() -> void
- func test_task_stage_spawner_methods() -> void
- func test_inventory_ui_methods() -> void

### tests/test_morale_system.gd
- func _init(p_faction: int, p_willpower: int, p_max_willpower: int)
- func set_willpower_test(value: int) -> void
- func _init(initial_units: Array[Unit] = [])
- func get_units_by_faction(p_faction: int) -> Array[Unit]
- func get_player_units() -> Array[Unit]
- func get_enemy_units() -> Array[Unit]
- func get_neutral_units() -> Array[Unit]
- func get_units() -> Array[Unit]
- func remove_unit(unit: Unit) -> void
- func add_unit(unit: Unit, _coord: Vector2i = Vector2i.ZERO, _player_controlled: bool = false) -> void
- func get_faction_max_willpower(p_faction: int, _include_debug := false) -> int
- func _trigger_all_for_lint() -> void
- func _init(p_morale_panel: Node)
- func show_warning_message(message: String) -> void
- func _init(p_hud: Node, p_unit_manager: UnitManager)
- func _register(node: Node) -> Node
- func _setup_morale_panel_nodes(morale_panel: Control) -> void
- func test_morale_panel_initial_state() -> void
- func test_morale_panel_updates_on_willpower_change() -> void
- func test_morale_panel_player_retreat_trigger() -> void
- func test_morale_panel_enemy_retreat_trigger() -> void

### tests/test_move_controller_cancel.gd
- func has_tentative_move() -> bool
- func get_start_of_turn_grid_coord() -> Vector2i
- func clear_tentative_move() -> void
- func get_unit(index: int)
- func set_coord(index: int, coord: Vector2i) -> void
- func get_terrain_map()
- func test_cancel_tentative_move_for_index_clears_pending_move() -> void

### tests/test_move_services.gd
- func test_validate_direction_move_accepts_open_hex() -> void
- func test_validate_coordinate_move_includes_path_cost() -> void
- func test_execute_move_consumes_points_and_updates_behavior() -> void
- func test_finalize_tentative_move_commits_unit() -> void
- func test_evaluate_post_move_flags_completion_without_actions() -> void
- func test_threat_warning_service_detects_threat() -> void
- func test_threat_warning_service_acknowledge_and_reset() -> void
- func get_coord(index: int) -> Vector2i
- func is_occupied(_target: Vector2i, _selected_idx: int = -1) -> bool
- func get_direction_map(_current, _grid) -> Dictionary
- func is_passable(_coord: Vector2i) -> bool
- func get_movement_cost(coord: Vector2i) -> int
- func get_terrain_map()
- func get_remaining_movement_points() -> int
- func has_tentative_move() -> bool
- func get_start_of_turn_grid_coord() -> Vector2i
- func get_path_to_coord(target: Vector2i, _terrain_map, _origin: Vector2i, _budget: int) -> Array[Vector2i]
- func get_path_to_coord(_target: Vector2i, _terrain_map, _origin: Vector2i, _budget: int) -> Array[Vector2i]
- func consume_move(amount: int) -> void
- func has_move_available() -> bool
- func has_action_available() -> bool
- func get_tentative_grid_coord() -> Vector2i
- func get_tentative_cost() -> int
- func clear_tentative_move() -> void
- func set_start_of_turn_grid_coord(coord: Vector2i) -> void
- func set_coord(_index: int, coord: Vector2i) -> void
- func check_location_progress() -> void
- func get_available_actions(_unit, _terrain_map, _unit_manager) -> Array
- func get_threatened_hexes(_unit_manager, _terrain_map) -> Array
- func _init() -> void

### tests/test_movement_range.gd
- func test_compute_limits_by_cost() -> void
- func test_compute_blocks_impassable_tiles() -> void

### tests/test_movement_range_calculator.gd
- func is_within_bounds(coord: Vector2i) -> bool
- func is_passable(_coord: Vector2i) -> bool
- func get_movement_cost(_coord: Vector2i) -> int
- func get_neighbors(coord: Vector2i) -> Array[Vector2i]
- func is_within_bounds(_coord: Vector2i) -> bool
- func is_passable(_coord: Vector2i) -> bool
- func get_movement_cost(_coord: Vector2i) -> int
- func get_neighbors(coord: Vector2i) -> Array[Vector2i]
- func get_offset_axis() -> int
- func before_test() -> void
- func test_find_path_same_start_and_target() -> void
- func test_find_path_target_not_reachable() -> void
- func test_find_path_simple() -> void
- func test_find_path_prefers_non_threatened_hexes() -> void
- func test_find_path_avoids_blocked_hexes() -> void

### tests/test_movement_range_service.gd
- func _create_unit_setup(coord: Vector2i) -> Dictionary
- func _create_plain_terrain() -> TerrainMap
- func test_calculate_reports_move_spaces() -> void
- func test_calculate_uses_tentative_action_origin() -> void
- func test_tentative_action_origin_cost_is_zero() -> void

### tests/test_neutral_loyalty.gd
- func _make_unit(faction: Unit.Faction) -> Unit
- func test_neutral_handles_attack_from_player() -> void
- func test_neutral_persuasion_changes_loyalty() -> void
- func test_reset_neutral_loyalty_clears_alignment() -> void
- func test_rally_spreads_loyalty_to_targets() -> void
- func test_unit_manager_reset_all_neutral_loyalties() -> void

### tests/test_objective.gd
- func _make_level() -> Level
- func _make_stage(tasks_count: int = 0) -> Stage
- func _make_objective(obj_id: String = "obj_test") -> Objective
- func test_start_objective_with_no_stages_emits_completed() -> void
- func test_start_objective_sets_is_active() -> void
- func test_start_objective_uses_starting_stage_when_set() -> void
- func test_start_objective_stage_with_no_tasks_completes_immediately() -> void
- func test_start_objective_uses_stages_array_when_starting_stage_null() -> void
- func test_stage_completion_propagates_to_objective_completed() -> void
- func test_start_objective_stores_level_reference() -> void

### tests/test_pathfinding_execution.gd
- func test_request_move_to_coord_calculates_path() -> void
- func test_hex_navigator_can_find_path() -> void
- func test_move_controller_respects_movement_points() -> void
- func test_path_stops_at_terrain_obstacle() -> void
- func test_game_command_context_validates_dependencies() -> void
- func test_game_command_context_reports_missing_deps() -> void
- func test_primary_action_command_validates_context() -> void

### tests/test_pause_handler.gd
- func before_test() -> void
- func after_test() -> void
- func test_handle_pause_input_toggles_state() -> void

### tests/test_pause_menu.gd
- func before_test() -> void
- func after_test() -> void
- func test_resume_button_emits_signal() -> void
- func test_controls_button_emits_signal() -> void
- func test_quit_button_emits_signal() -> void
- func test_volume_slider_updates_audio_and_config() -> void
- func test_mute_check_updates_audio_and_config() -> void
- func test_orientation_selection_updates_display_settings_and_config() -> void
- func test_resolution_selection_updates_display_settings_and_config() -> void
- func test_auto_advance_toggle_updates_dialogic_and_config() -> void
- func test_auto_advance_speed_slider_updates_settings_and_config() -> void
- func test_text_speed_slider_updates_settings_and_config() -> void

### tests/test_pause_workflow.gd
- func before_test() -> void
- func after_test() -> void
- func _action_event(action: String) -> InputEventAction
- func test_pause_menus_process_during_tree_pause() -> void
- func test_pause_controls_reset_defaults() -> void
- func test_pause_volume_and_mute_controls() -> void
- func test_pause_menu_disables_turn_controller() -> void
- func test_resume_action_clears_focus() -> void
- func test_quit_request_disables_gameplay_processing() -> void

### tests/test_player_roster.gd
- func before_test() -> void
- func test_get_units_empty() -> void
- func test_get_units_returns_array() -> void
- func test_update_roster_empty() -> void
- func test_update_roster_with_units() -> void
- func test_update_roster_multiple_units() -> void
- func test_update_roster_handles_null_units() -> void
- func test_update_roster_preserves_missing_units_when_permadeath_disabled() -> void
- func test_add_to_stash_and_clear() -> void
- func test_set_remaining_location_titles_tracks_value() -> void

### tests/test_quest_flow.gd
- func spawn_loot(coord: Vector2i, items: Array[InventoryItem]) -> void
- func test_unit_death_handler_drops_quest_item_on_hard_difficulty() -> void
- func test_task_round_changed_attribution() -> void
- func test_task_reward_item_granting() -> void

### tests/test_roster_loader.gd
- func test_load_player_roster_prefers_provided_units() -> void
- func test_load_player_roster_falls_back_when_empty() -> void
- func test_load_player_roster_uses_default_resource_when_missing() -> void
- func test_load_enemy_roster_populates_units_from_default() -> void
- func test_load_enemy_roster_falls_back_when_provided_empty() -> void
- func test_load_neutral_roster_populates_units_from_default() -> void
- func test_load_neutral_roster_falls_back_when_provided_empty() -> void
- func test_build_core_player_roster_loads_core_characters() -> void
- func test_load_player_roster_falls_back_to_core_directory() -> void

### tests/test_roster_persistence.gd
- func test_unit_to_entry_captures_unit_metadata() -> void
- func test_entry_to_scene_restores_memento() -> void
- func test_scene_to_entry_preserves_fallback_scene() -> void

### tests/test_round_info_panel.gd
- func _make_panel() -> Node
- func after_test() -> void
- func test_update_round() -> void
- func test_update_turn() -> void
- func test_update_enabled() -> void
- func test_update_turn_status() -> void

### tests/test_save_level_managers.gd
- func before_test() -> void
- func after_test() -> void
- func test_save_manager_initially_has_no_completed_levels() -> void
- func test_save_manager_saves_and_loads_completed_levels() -> void
- func test_save_manager_get_completed_levels_count() -> void
- func test_level_manager_initializes_with_level_data() -> void
- func test_level_manager_level1_is_unlocked_by_default() -> void
- func test_level_manager_prerequisites_unlock_levels() -> void
- func test_level_manager_mark_level_completed_updates_and_saves() -> void
- func test_level_manager_get_available_levels() -> void
- func test_level_manager_start_level_by_id() -> void
- func test_level_manager_on_level_complete_transitions_to_credits_when_no_more_unlocked() -> void

### tests/test_save_manager.gd
- func before_test() -> void
- func test_set_and_get_value() -> void
- func test_get_value_returns_default() -> void
- func test_overwrite_value() -> void
- func test_set_multiple_values() -> void
- func test_set_global_flag() -> void
- func test_set_level_flag() -> void

### tests/test_save_manager_extended.gd
- func test_set_and_get_hometown_skit_shown() -> void
- func test_set_and_get_leader_unit_name() -> void
- func test_create_and_restore_game_memento() -> void
- func test_undo_and_redo_state() -> void
- func test_save_and_load_roster() -> void

### tests/test_scene_transition_methods.gd
- func before_test() -> void
- func after_test() -> void
- func test_is_changing() -> void

### tests/test_scene_transition_signals.gd
- func before_test() -> void
- func after_test() -> void
- func _on_scene_change_requested(path: String) -> void
- func _on_scene_change_completed(path: String) -> void
- func test_scene_change_requested_signal_emits() -> void
- func test_scene_change_completed_signal_emits_after_transition() -> void
- func test_scene_change_signal_order_is_correct() -> void
- func test_scene_change_with_delay_signals_emit() -> void
- func test_scene_change_requested_signal_only_emits() -> void
- func test_reload_current_emits_signals() -> void
- func test_concurrent_scene_change_requests_ignored() -> void
- func test_signal_timeout_protection() -> void

### tests/test_skills_extended.gd
- func test_heal_skill_activate_unit_adds_willpower() -> void
- func test_heal_skill_activate_non_unit_fails() -> void
- func test_weather_skill_activate_fails_if_manager_null() -> void

### tests/test_stage.gd
- func _make_task(event: String = "interact", effort: int = 1) -> Task
- func _make_stage(tasks: Array[Task], mode: Stage.CompletionMode = Stage.CompletionMode.ALL_REQUIRED, auto_adv: bool = true) -> Stage
- func test_start_stage_activates_all_tasks() -> void
- func test_start_stage_clears_previous_active_tasks() -> void
- func test_start_stage_duplicates_tasks_for_isolation() -> void
- func test_all_required_completes_when_all_tasks_done() -> void
- func test_all_required_does_not_complete_when_only_one_done() -> void
- func test_any_required_completes_when_first_task_done() -> void
- func test_any_with_branching_uses_branching_transitions() -> void
- func test_manual_advance_emits_stage_completed_after_ready() -> void
- func test_advance_does_nothing_when_no_pending_stage() -> void
- func test_end_stage_cancels_active_tasks() -> void
- func test_end_stage_does_not_cancel_completed_tasks() -> void
- func test_optional_task_does_not_block_completion() -> void

### tests/test_talk_to_unit_command.gd
- func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult
- func _create_context(service = null) -> GameCommandContext
- func test_execute_requires_dialogue_service() -> void
- func test_execute_invokes_service_with_payload() -> void

### tests/test_target.gd
- func before_test() -> void
- func test_get_grid_location_with_explicit_grid_map() -> void
- func test_get_grid_location_with_parent_grid() -> void
- func test_get_grid_location_no_grid() -> void
- func test_snap_to_grid_with_explicit_grid_map() -> void
- func test_snap_to_grid_with_parent_grid() -> void
- func test_snap_to_grid_no_grid() -> void

### tests/test_target_and_loot_extended.gd
- func test_target_is_pixel_inside() -> void
- func test_target_is_pixel_inside_with_sprite() -> void
- func test_loot_manager_remove_loot_cleans_up_loot() -> void

### tests/test_target_grid_coords.gd
- func test_target_returns_external_grid_coord() -> void
- func test_distance_to_target_uses_external_coords() -> void
- func test_location_interaction_respects_external_coord() -> void
- func test_target_clear_external_coord_resets_state() -> void
- func test_loot_can_be_looted_by_uses_external_coord() -> void

### tests/test_target_interaction_handler_extended.gd
- func test_explore() -> void
- func test_visit_location() -> void
- func test_convince_unit() -> void

### tests/test_task_condition_handler_extended.gd
- func test_check_objective_failed_returns_false_if_no_unit_manager() -> void
- func test_check_objective_failed_returns_false_if_zero_units() -> void
- func test_check_objective_failed_returns_true_if_no_player_units() -> void
- func test_check_objective_failed_returns_true_if_all_player_units_dead() -> void
- func test_check_objective_failed_returns_false_if_player_unit_alive() -> void

### tests/test_task_controller_extended.gd
- func prepare_objective(lvl: Level, obj: Objective) -> void
- func start_active_objective() -> void
- func get_active_objective() -> Objective
- func get_task_by_id(id: String) -> Task
- func _init()
- func handle_event(event_name: String, payload: Dictionary) -> void
- func get_unit_count() -> int
- func get_unit(_i: int) -> Unit
- func _init()
- func _make_controller() -> TaskController
- func test_set_level_updates_manager() -> void
- func test_on_unit_defeated_passes_event_to_objective() -> void
- func test_on_round_changed_passes_event_to_objective() -> void
- func test_check_inventory_objectives_passes_event_to_objective() -> void
- func test_check_objective_conditions_checks_inventory() -> void
- func test_get_task_info_returns_transformed_dict() -> void
- func test_get_task_info_returns_empty_when_not_found() -> void

### tests/test_task_controller_extended_2.gd
- func test_task_controller_finish_setup() -> void
- func test_task_controller_bootstrap_and_activate() -> void
- func test_task_controller_on_task_completed() -> void
- func test_task_controller_is_narrative_blocking() -> void

### tests/test_task_details_panel.gd
- func test_location_details_panel_displays_dictionary_payload() -> void

### tests/test_task_dialogue_handler.gd
- func test_queue_stage_dialogues() -> void
- func test_process_queue() -> void

### tests/test_task_dialogue_handler_extended_2.gd
- func test_task_dialogue_handler_queue_task_dialogues() -> void
- func test_task_dialogue_handler_get_queue_contents() -> void

### tests/test_task_filters.gd
- func _make_task() -> Task
- func test_target_filters_match_multiple_event_types() -> void
- func test_target_filters_coordinate_gating() -> void

### tests/test_task_manager_extended.gd
- func before_test() -> void
- func after_test() -> void
- func _setup_active_objective(task: Task) -> Objective
- func _make_task(event: String = "interact", target_id: String = "", coord: Vector2i = Vector2i(-999, -999)
- func test_get_task_by_id_returns_matching_task() -> void
- func test_get_task_by_id_returns_null_for_unknown_id() -> void
- func test_get_task_by_id_returns_null_with_no_objective() -> void
- func test_get_task_by_id_returns_null_with_no_stage() -> void
- func test_get_active_tasks_for_target_returns_null_with_no_objective() -> void
- func test_get_active_tasks_for_target_matches_by_coord() -> void
- func test_get_active_tasks_for_target_no_match_wrong_coord() -> void
- func test_get_active_tasks_for_target_null_target_returns_empty() -> void
- func test_register_loot_adds_to_loot_nodes() -> void
- func test_register_loot_adds_to_loot_lookup() -> void
- func test_register_loot_does_not_double_connect_signal() -> void

### tests/test_task_manager_final.gd
- func before_test() -> void
- func after_test() -> void
- func _setup_active_objective(task: Task) -> Objective
- func test_final_loot_interaction() -> void
- func test_final_visit_interaction() -> void
- func test_final_convince_interaction() -> void

### tests/test_task_methods.gd
- func test_task_force_complete() -> void
- func test_task_get_progress_ratio() -> void
- func test_task_manager_prepare_objective() -> void
- func test_task_manager_debug_complete() -> void

### tests/test_task_round_changed.gd
- func test_task_controller_receives_round_changed() -> void

### tests/test_task_validator.gd
- func before_test() -> void
- func test_validate_item_target_null_task_returns_false() -> void
- func test_validate_item_target_empty_target_id_returns_false() -> void
- func test_validate_item_target_item_not_in_world_returns_false() -> void
- func test_validate_item_target_holder_location_returns_true() -> void
- func test_validate_item_target_holder_unit_npc_returns_true() -> void
- func test_validate_item_target_quest_item_in_stash_returns_true() -> void
- func test_validate_item_target_quest_item_not_in_stash_returns_false() -> void
- func test_validate_item_target_non_quest_player_held_returns_false() -> void
- func test_validate_location_target_null_task_returns_false() -> void
- func test_validate_location_target_by_id_present_in_world() -> void
- func test_validate_location_target_by_id_absent_from_world() -> void
- func test_validate_location_target_by_coord_found() -> void
- func test_validate_location_target_by_coord_not_found() -> void
- func test_validate_location_target_no_id_no_coord_returns_false() -> void
- func test_validate_unit_target_null_task_returns_false() -> void
- func test_validate_unit_target_empty_target_id_returns_false() -> void
- func test_validate_unit_target_unit_present_in_world() -> void
- func test_validate_unit_target_unit_absent_from_world() -> void
- func _make_active_task(event: String = "interact", required: int = 1) -> Task
- func test_handle_event_ignored_when_not_active() -> void
- func test_handle_event_wrong_type_does_not_progress() -> void
- func test_handle_event_interact_matching_completes_when_effort_met() -> void
- func test_handle_event_interact_coord_match_required() -> void
- func test_handle_event_interact_coord_match_progresses() -> void
- func test_handle_event_interact_id_mismatch_does_not_progress() -> void
- func test_handle_event_interact_id_match_progresses() -> void
- func test_handle_event_accumulates_effort_across_calls() -> void
- func test_handle_event_pickup_type() -> void
- func test_handle_event_pickup_id_mismatch() -> void
- func test_handle_event_cancel_prevents_further_progress() -> void
- func test_handle_event_progress_changed_signal_emitted() -> void

### tests/test_terrain_interaction.gd
- func test_map_controller_loads_terrain() -> void
- func test_terrain_map_has_passability_data() -> void
- func test_movement_respects_grid_boundaries() -> void
- func test_occupied_hex_blocks_movement() -> void
- func test_pathfinding_avoids_obstacles() -> void
- func test_movement_cost_calculated_per_terrain() -> void
- func test_config_movement_constants_available() -> void
- func test_config_grid_constants_available() -> void

### tests/test_terrain_map.gd
- func test_load_from_rows_defaults_unknown_codes_to_grass() -> void
- func test_out_of_bounds_returns_null_terrain() -> void
- func test_version_increments_on_load() -> void
- func test_get_neighbors_respects_offset_axis() -> void
- func test_get_color_for_code() -> void
- func test_get_all_terrain_colors() -> void

### tests/test_terrain_tile.gd
- func test_get_movement_adjustment_combines_bonus_and_penalty() -> void
- func test_apply_to_unit_enforces_effects() -> void

### tests/test_terrain_tile_extended.gd
- func _make_tile() -> TerrainTile
- func _make_weather(humidity: float = 0.0, temperature: float = 0.0, move_modifier: float = 0.0) -> WeatherAttribute
- func after_test() -> void
- func test_hover_info_passable_no_modifiers() -> void
- func test_hover_info_impassable_shows_impassable() -> void
- func test_hover_info_movement_penalty_shown() -> void
- func test_hover_info_movement_bonus_shown() -> void
- func test_hover_info_status_effect_shown() -> void
- func test_hover_info_blocks_action_shown() -> void
- func test_hover_info_penalty_hidden_when_impassable() -> void
- func test_movement_cost_no_weather_no_modifiers() -> void
- func test_movement_cost_no_weather_with_penalty() -> void
- func test_movement_cost_no_weather_with_bonus() -> void
- func test_movement_cost_minimum_is_one() -> void
- func test_movement_cost_weather_move_modifier_increases_cost() -> void
- func test_movement_cost_very_wet_adds_one_for_passable() -> void
- func test_movement_cost_very_cold_adds_one_for_passable() -> void
- func test_movement_cost_neutral_weather_unchanged() -> void

### tests/test_turn_controller.gd
- func execute_turn(unit: Unit) -> bool
- func before_test() -> void
- func test_start_next_turn_with_empty_queue() -> void
- func test_complete_turn() -> void
- func test_get_current_unit_index() -> void
- func test_get_current_side() -> void
- func test_get_round() -> void
- func test_set_player_auto_battle_enabled_emits_signal() -> void
- func test_force_disable_auto_battle_emits_failure_signal() -> void
- func test_player_auto_control_lock_clears_after_ai_turn() -> void
- func test_auto_battle_enabling_runs_current_turn() -> void
- func test_auto_battle_disables_when_ai_cannot_act() -> void
- func test_auto_battle_switches_to_other_unit_when_one_is_stuck() -> void
- func test_auto_battle_disables_after_exhausting_all_units() -> void
- func test_rebuild_turn_roster_handles_player_only_units() -> void
- func test_rebuild_turn_roster_handles_player_and_neutral_only() -> void
- func test_restore_memento_rehydrates_auto_battle_state() -> void
- func test_player_can_act_with_any_available_unit() -> void
- func test_player_queue_reorders_when_switching_units() -> void

### tests/test_turn_controller_auto_battle_toggle.gd
- func execute_turn(unit: Unit) -> bool
- func test_auto_battle_toggle_mid_turn_runs_selected_unit() -> void
- func test_auto_battle_preserves_turn_for_free_roam_unit() -> void

### tests/test_turn_flow_with_ai.gd
- func before_test() -> void
- func test_player_turn_starts_first_round() -> void
- func test_turn_queue_alternates_player_and_enemy() -> void
- func test_enemy_turn_calculation() -> void
- func test_ai_controller_is_configured() -> void
- func test_neutral_units_are_included_in_turn_queue() -> void
- func test_ai_controller_execute_turn_does_not_crash_with_valid_unit() -> void

### tests/test_turn_queue_builder.gd
- func before_test() -> void
- func test_get_side_rotation() -> void
- func test_build_from_active_units() -> void
- func test_determine_start_side() -> void
- func test_find_next_active_side() -> void
- func test_classify_unit_side() -> void
- func test_get_active_units_by_side_empty() -> void

### tests/test_turn_system.gd
- func get_round() -> int
- func get_current_unit_index() -> int
- func get_current_side() -> int
- func before_test() -> void
- func test_get_current_round_with_controller() -> void
- func test_get_current_unit_index_with_controller() -> void
- func test_get_current_side_with_controller() -> void
- func test_get_current_round_without_controller() -> void
- func test_get_current_unit_index_without_controller() -> void
- func test_get_current_side_without_controller() -> void

### tests/test_turn_system_extended.gd
- func before_test() -> void
- func test_peek_next_index_empty_queue_returns_minus_one() -> void
- func test_peek_next_index_single_item() -> void
- func test_peek_next_index_multiple_items_returns_first() -> void
- func test_peek_next_index_does_not_consume() -> void
- func test_move_index_to_front_swaps_with_position_zero() -> void
- func test_move_index_to_front_position_zero_is_noop() -> void
- func test_move_index_to_front_out_of_bounds_position_is_noop() -> void
- func test_move_index_to_front_last_valid_position() -> void
- func test_reset_turns_taken_this_round_clears_all_sides() -> void
- func test_reset_turns_taken_this_round_idempotent() -> void
- func test_turns_taken_increments_correctly_after_reset() -> void

### tests/test_unit_action_manager.gd
- func test_unit_action_manager_is_callable() -> void
- func test_can_reach_coord_detects_exact_tile() -> void
- func test_get_available_actions_includes_wait_when_turn_enabled() -> void
- func test_get_available_actions_uses_unit_manager_coord() -> void
- func test_is_unit_stuck_with_tentative_move() -> void
- func test_loot_action_available_after_tentative_move() -> void
- func test_move_and_interact_action_generates_attack_option() -> void
- func test_move_and_interact_action_includes_loot() -> void
- func test_move_and_interact_loot_requires_reachable_tile() -> void
- func test_move_and_interact_action_includes_location() -> void
- func test_move_and_interact_location_requires_reachable_tile() -> void
- func test_move_and_interact_attack_prefers_lowest_move_cost() -> void
- func test_move_and_attack_uses_zero_move_when_tentative_origin_is_adjacent() -> void
- func test_resolve_move_cost_respects_remaining_move() -> void
- func test_build_move_and_interact_action_merges_extra_fields() -> void
- func test_move_and_loot_action_skipped_when_path_blocked() -> void
- func test_resolve_move_origin_uses_committed_coord_for_tentative_move() -> void

### tests/test_unit_combat_and_interaction.gd
- func execute_combat(_attacker: Unit, defender: Unit, _attr: int) -> Dictionary
- func _make_unit(faction: Unit.Faction, coord: Vector2i) -> Unit
- func after_test() -> void
- func test_interaction_handler_interact_routes_to_units() -> void
- func test_combat_behavior_attack_fails_if_no_action() -> void
- func test_combat_behavior_attack_fails_if_not_adjacent() -> void
- func test_combat_behavior_aid_ally_fails_if_not_adjacent() -> void

### tests/test_unit_components.gd
- func _register(node)
- func test_action_points_component_tracks_turn_state() -> void
- func test_inventory_component_applies_item_modifiers() -> void
- func test_set_start_of_turn_grid_coord_updates_anchor() -> void
- func test_movement_range_cache_reacts_to_unit_manager() -> void
- func test_inventory_component_item_management() -> void

### tests/test_unit_extended.gd
- func get_willpower() -> int
- func set_willpower(v: int) -> void
- func get_max_willpower() -> int
- func set_max_willpower(v: int) -> void
- func _init(u: Unit) -> void
- func set_animation_service(service) -> void
- func _make_unit() -> Unit
- func after_test() -> void
- func test_is_at_full_willpower_returns_true_when_equal() -> void
- func test_is_at_full_willpower_returns_true_when_greater() -> void
- func test_is_at_full_willpower_returns_false_when_less() -> void
- func test_is_at_full_willpower_returns_true_if_max_is_zero() -> void
- func test_get_combat_profile_returns_assigned_profile() -> void
- func test_get_combat_profile_returns_default_when_unassigned() -> void
- func test_set_animation_service_assigns_internal_var() -> void
- func test_set_animation_service_propagates_to_death_handler() -> void
- func test_finalize_setup_emits_ready_signal() -> void
- func test_finalize_setup_idempotent() -> void
- func test_aid_buffs() -> void
- func test_set_location_service() -> void

### tests/test_unit_inventory.gd
- func test_remove_item_from_inventory() -> void
- func test_has_item_by_id() -> void

### tests/test_unit_manager.gd
- func before_test() -> void
- func _make_unit(name: String) -> Unit
- func test_get_nearest_empty_coord() -> void
- func test_get_units() -> void
- func test_remove_unit() -> void
- func test_remove_unit_not_found() -> void
- func test_get_selected_unit() -> void
- func test_get_selected_unit_none() -> void
- func test_get_unit_index_by_iterating() -> void
- func test_remove_unit_adjusts_selection() -> void
- func test_remove_unit_from_middle() -> void
- func test_get_unit_index() -> void
- func test_unit_manager_get_selected_sprite() -> void
- func test_unit_manager_set_coord() -> void
- func test_unit_manager_set_player_controlled() -> void
- func test_set_faction_leader_assigns_unique_per_faction() -> void

### tests/test_unit_manager_extended.gd
- func before_test() -> void
- func after_test() -> void
- func test_set_roster_stores_roster_for_faction() -> void
- func test_set_roster_null_erases_existing_roster() -> void
- func test_set_roster_different_factions_are_independent() -> void
- func test_force_select_index_changes_selection_and_emits_signal() -> void
- func test_force_select_index_out_of_bounds_does_nothing() -> void
- func test_force_select_index_negative_does_nothing() -> void
- func test_can_player_act_true_for_player_controlled_index() -> void
- func test_can_player_act_false_for_non_player_controlled() -> void
- func test_can_player_act_false_for_negative_index() -> void
- func test_can_player_act_false_for_out_of_bounds_index() -> void
- func test_can_player_act_multiple_units_correct_index() -> void
- func test_apply_faction_stat_boost() -> void
- func test_get_faction_max_willpower() -> void

### tests/test_unit_manager_spatial.gd
- func _make_manager() -> Node
- func test_get_coord_by_unit() -> void
- func test_get_nearest_empty_coord() -> void

### tests/test_unit_manager_spawn.gd
- func test_add_unit_emits_spawn_signal() -> void

### tests/test_unit_movement_behavior.gd
- func is_within_bounds(coord: Vector2i) -> bool
- func get_offset_axis() -> int
- func _make_unit(faction: Unit.Faction, coord: Vector2i) -> Unit
- func after_test() -> void
- func test_get_blocked_hexes_returns_enemy_coords() -> void
- func test_process_path_for_opportunity_attacks_without_combat_system_returns_destination() -> void
- func test_move_along_path_updates_coords_and_consumes_moves() -> void

### tests/test_unit_query_service.gd
- func test_get_units_in_range_without_full_willpower_filters_full_units() -> void
- func test_get_units_in_range_without_full_willpower_respects_range() -> void
- func test_invalidate_cache_sets_all_dirty_flags() -> void
- func test_invalidate_cache_clears_cached_arrays() -> void
- func test_invalidate_cache_idempotent() -> void

### tests/test_unit_system.gd
- func _get_shared_grid() -> TileMapLayer
- func _create_unit(position: Vector2 = Vector2.ZERO, unit_manager: UnitManager = null) -> Unit
- func _create_unit_with_saved_item(item: InventoryItem) -> Unit
- func test_has_nearby_units_detects_units() -> void
- func test_inventory_item_modifies_attributes() -> void
- func test_locations_in_range_and_acting() -> void
- func test_attribute_helpers_and_inventory_accessors() -> void
- func test_unit_attributes_preserve_scene_values() -> void
- func test_range_helpers_cover_faction_and_morale() -> void
- func test_turn_state_methods_manage_resources() -> void
- func test_status_effects_and_on_enter_terrain() -> void
- func test_compute_movement_range_accounts_for_terrain() -> void
- func test_movement_range_cache_invalidates_on_changes() -> void
- func test_unit_set_loot_manager() -> void
- func test_unit_set_task_manager() -> void
- func test_unit_set_combat_system() -> void
- func test_unit_components_receive_injected_dependencies() -> void
- func test_unit_work_on_task_consumes_action_and_applies_progress_no_mock() -> void
- func test_unit_get_path_to_coord_returns_valid_path() -> void
- func test_unit_get_path_to_coord_prefers_lower_cost_route() -> void
- func test_unit_get_path_to_coord_prefers_shorter_path_on_equal_cost() -> void
- func test_unit_apply_consumable_updates_active_consumables() -> void
- func test_unit_prepare_for_save_stores_action_points_and_items() -> void
- func test_set_free_roam_mode_prevents_action_and_move_consumption() -> void
- func test_unit_saved_items_produce_unique_instances_per_unit() -> void
- func test_unit_get_path_to_coord_blocks_occupied_hexes() -> void
- func test_unit_get_path_to_coord_allows_friendly_hexes() -> void

### tests/test_utils.gd
- func HexTestUtils.assert_eq(self, actual, expected, message
- func HexTestUtils._simulate_frames(runner
- func HexTestUtils._create_scene_runner(self, scene_path
- func HexTestUtils.ensure_manager(get_tree(),
- func HexTestUtils.setup_autoloads(get_tree(), autoload_configs
- func HexTestUtils.teardown_autoloads(get_tree()) -> void
- func after_test() -> void
- func HexTestUtils._clear_save_game() -> void
- static func HexTestUtils.free_tree(node

### tests/test_weather_manager.gd
- func _make_manager() -> Node
- func after_test() -> void
- func test_is_hard_mode_without_game_config() -> void
- func test_add_pressure_adds_to_forecast_by_default() -> void
- func test_add_pressure_adds_to_current_if_specified() -> void
- func test_add_pressure_cancels_opposite() -> void
- func test_add_pressure_limits_to_two_by_removing_oldest() -> void
- func test_remove_pressure_removes_from_forecast() -> void
- func test_clear_pressures_clears_forecast() -> void
- func test_clear_pressures_clears_current() -> void
- func test_get_weather_info_empty_pressures_returns_temperate() -> void
- func test_get_weather_info_single_pressure_focus_returns_calm() -> void
- func test_get_weather_info_single_pressure_returns_condition() -> void
- func test_get_weather_info_combo() -> void
- func test_apply_weather_effects_emits_signals() -> void
- func test_advance_weather_with_no_channeler_does_nothing() -> void
- func test_advance_weather_with_living_channeler_applies_forecast() -> void
- func test_get_current_weather_attribute_returns_weather_attribute_resource() -> void

### tests/test_weather_manager_checkpoint.gd
- func test_weather_checkpoint_restores_pressures_and_channeling() -> void

### tests/tmp_test.gd
- func _init()

