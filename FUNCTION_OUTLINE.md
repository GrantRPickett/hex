# Project Function Outline

## Autoloads

### Autoloads/achievement_manager.gd
- `func _ready() -> void:`
- `func unlock_achievement(achievement_id: String) -> bool:`
- `func get_savable_data() -> Dictionary:`
- `func load_savable_data(data: Dictionary):`

### Autoloads/audio_bus_controller.gd
- `func _ready() -> void:`
- `func set_bus_volume_db(bus_name: String, volume_db: float) -> void:`
- `func get_bus_volume_db(bus_name: String) -> float:`
- `func mute_bus(bus_name: String, mute := true) -> void:`
- `func is_bus_muted(bus_name: String) -> bool:`
- `func play_music(stream: AudioStream, bus_name: String = "Music") -> void:`
- `func stop_music() -> void:`
- `func _ensure_bus(bus_name: String) -> void:`

### Autoloads/control_settings.gd
- `func _ready() -> void:`
- `func reset_inputs_to_defaults() -> void:`

### Autoloads/difficulty_service.gd
- `func _ready() -> void:`
- `func _on_config_changed(path: String, value) -> void:`
- `func get_ai_scaling_factor() -> float:`
- `func get_ai_morale_weight() -> float:`
- `func get_retreat_threshold() -> float:`
- `func get_combat_modifier() -> float:`

### Autoloads/display_settings.gd
- `func _ready() -> void:`
- `func get_standard_resolutions(orientation: DisplayOrientation.Orientation) -> Array[Vector2i]:`
- `func get_current_orientation() -> DisplayOrientation.Orientation:`
- `func get_current_resolution_index() -> int:`
- `func get_current_resolution() -> Vector2i:`
- `func set_orientation(orientation: DisplayOrientation.Orientation) -> void:`
- `func set_resolution_index(index: int) -> void:`

### Autoloads/event_bus.gd
- (No functions found or purely signals)

### Autoloads/file_paths.gd
- `static func get_dialogue_path(level_id: String, dialogue_id: String) -> String:`
- `static func get_level_path(level_id: String) -> String:`
- `static func get_path_separator() -> String:`
- `static func join_path(base: String, extra: String) -> String:`
- `static func path_exists(path: String) -> bool:`
- `static func get_all_categories() -> Array[String]:`
- `static func get_all_paths() -> Dictionary:`

### Autoloads/game_config.gd
- `func _ready() -> void:`
- `func reset_to_defaults() -> void:`
- `func set_value(path: String, value) -> void:`
- `func get_value(path: String, default_value = null):`
- `func save_config() -> void:`
- `func load_config() -> void:`
- `func _set_by_path(path: String, value) -> void:`
- `func _get_by_path(path: String, default_value):`
- `func _deep_merge(base: Dictionary, update: Dictionary) -> Dictionary:`

### Autoloads/game_constants.gd
- `static func colorize_attributes(text: String) -> String:`
- `static func get_faction_name(faction: int) -> String:`

### Autoloads/input_mapper.gd
- `func apply_configs(configs: Array, fallback: Array = []) -> void:`
- `func map_action(action: String, keys: Array, buttons: Array = [], mouse_buttons: Array = []) -> void:`
- `func clear_action(action: String) -> void:`
- `func _as_int_array(value) -> Array:`

### Autoloads/journal_manager.gd
- `func setup(task_manager: TaskManager) -> void:`
- `func _ready():`
- `func set_level(level: Level) -> void:`
- `func _ensure_initialized() -> void:`
- `func _initialize_default_content():`
- `func unlock_entry(entry_id: String) -> bool:`
- `func clear_journal() -> void:`
- `func unlock_coupled_entry(entry_id: String, section_id: String, topic_id: String, notes: String, _flag_name: StringName) -> void:`
- `func get_journal_data() -> JournalData:`
- `func get_entry(entry_id: String) -> LevelJournalEntry:`
- `func get_section(section_id: String) -> JournalSection:`
- `func get_savable_data() -> Dictionary:`
- `func load_savable_data(data: Dictionary):`
- `func _on_objective_updated(objective: Objective) -> void:`
- `func _on_task_completed_signal(_faction_id: int, _unit: Unit, task: Task, objective: Objective) -> void:`
- `func _on_task_failed_signal(task: Task, objective: Objective) -> void:`
- `func _on_objective_completed(objective: Objective) -> void:`
- `func _add_or_update_objective_entry(objective: Objective, status: String = "active") -> void:`
- `func _add_or_update_stage_entry(stage: Stage, objective: Objective, status: String = "active") -> void:`
- `func _add_or_update_task_entry(task: Task, status: String = "active", objective: Objective = null) -> void:`
- `func _generate_entry_id(prefix: String, game_object_id: String) -> String:`
- `func _get_objective_section() -> JournalSection:`
- `func _on_task_status_changed(task: Task, new_status_str: String, objective: Objective, _args = null) -> void:`
- `func _task_status_to_string(status_enum: Task.Status) -> String:`

### Autoloads/level_manager.gd
- `func _ready() -> void:`
- `func start_level_by_id(level_id: String) -> void:`
- `func start_first_level() -> void:`
- `func get_level_info(level_id: String) -> Dictionary:`
- `func is_level_unlocked(level_id: String) -> bool:`
- `func mark_level_completed(level_id: String) -> void:`
- `func get_available_levels() -> Array[Dictionary]:`
- `func get_current_level_path() -> String:`
- `func get_current_level_id() -> String:`
- `func is_level_completed(level_id: String) -> bool:`
- `func reset_completed_levels() -> void:`
- `func _on_level_complete() -> void:`
- `func _on_quit_to_title() -> void:`
- `func _on_quit_to_level_select() -> void:`

### Autoloads/locale_service.gd
- `func _ready() -> void:`
- `func _notification(what: int) -> void:`
- `func apply_locale_settings() -> void:`
- `func _apply_font_for_locale(locale: String) -> void:`

### Autoloads/resource_loader_service.gd
- `func collect_resources_recursive(path: String, extension: String = ".tres", type_hint: String = "") -> Array[Resource]:`
- `func load_resources_in_dir(path: String, extension: String = ".tres") -> Array[Resource]:`

### Autoloads/roster_manager.gd
- `func _ready() -> void:`
- `func _exit_tree() -> void:`
- `func get_roster() -> PlayerRoster:`
- `func get_units() -> Array[Unit]:`
- `func save_roster() -> void:`
- `func transfer_item(item: InventoryItem, source_unit: Unit, target_unit: Unit) -> void:`
- `func auto_equip() -> void:`
- `func debug_reset_roster() -> void:`
- `func sync_from_combat(unit_manager: UnitManager, stash_items: Array[InventoryItem]) -> void:`
- `func sync_unit(combat_unit: Unit) -> void:`
- `func _sync_single_unit_to_roster(combat_unit: Unit) -> void:`
- `func _load_roster() -> void:`
- `func _instantiate_units() -> void:`
- `func _setup_unit(unit: Unit) -> void:`
- `func _clear_loaded_units() -> void:`

### Autoloads/save_manager.gd
- `func _ready() -> void:`
- `func setup() -> void:`
- `func set_global_flag(flag_id: String, value: Variant) -> void:`
- `func get_global_flags() -> Dictionary:`
- `func set_level_flag(level_id: String, flag_id: String, value: Variant) -> void:`
- `func get_level_flags(level_id: String) -> Dictionary:`
- `func set_value(key: String, value: Variant) -> void:`
- `func get_value(key: String, default: Variant = null) -> Variant:`
- `func save_roster(roster: PlayerRoster) -> void:`
- `func load_roster() -> PlayerRoster:`
- `func has_saved_roster() -> bool:`
- `func set_hometown_skit_shown(skit_path: String, shown: bool) -> void:`
- `func get_hometown_skits() -> Dictionary:`
- `func get_leader_unit_name() -> String:`
- `func set_leader_unit_name(unit_name: String) -> void:`
- `func get_completed_levels_count() -> int:`
- `func _load_data() -> void:`
- `func _save_data() -> void:`
- `func create_game_memento(game_state: GameState = null) -> Dictionary:`
- `func restore_game_state(memento: Dictionary) -> void:`
- `func _distribute_loaded_data(data: Dictionary) -> void:`
- `func _load_saved_roster_resource() -> PlayerRoster:`
- `func _restore_roster_units(roster: PlayerRoster) -> void:`
- `func _load_default_player_roster() -> PlayerRoster:`
- `func _load_roster_from_resource(path: String) -> PlayerRoster:`
- `func save_current_state_for_undo() -> void:`
- `func undo_state() -> bool:`
- `func redo_state() -> bool:`
- `func _get_journal_manager() -> Node:`
- `func _get_achievement_manager() -> Node:`
- `func get_all_skits() -> Array[Skit]:`

### Autoloads/scene_transition.gd
- `func change_scene(path: String, delay := -1.0, emit_signal_only := false) -> bool:`
- `func reload_current(emit_signal_only := false) -> bool:`
- `func is_changing() -> bool:`

### Autoloads/weather_manager.gd
- `func is_hard_mode() -> bool:`
- `func _ready() -> void:`
- `func add_pressure(pressure: String, to_forecast: bool = true) -> void:`
- `func remove_pressure(pressure: String, from_forecast: bool = true) -> void:`
- `func clear_pressures(forecast_only: bool = true) -> void:`
- `func _notify_changed(forecast: bool) -> void:`
- `func advance_weather() -> void:`
- `func start_channeling(unit: Unit) -> bool:`
- `func get_channeling_unit() -> Unit:`
- `func create_memento() -> Dictionary:`
- `func restore_from_memento(memento: Dictionary) -> void:`
- `func get_weather_info(pressures: Array[String] = current_pressures) -> Dictionary:`
- `func _get_basic_weather_info(pressures: Array[String]) -> Dictionary:`
- `func _get_hard_mode_weather_info(pressures: Array[String]) -> Dictionary:`
- `func apply_weather_effects() -> void:`
- `func get_current_weather_attribute() -> WeatherAttribute:`


## Gameplay

### Gameplay/game_session.gd
- (No functions listed in snippet, but exists)

### Gameplay/gameplay.gd
- (No functions listed in snippet, but exists)

### Gameplay/targets/unit.gd
- `func _init() -> void:`
- `func _ready() -> void:`
- `func _on_action_points_willpower_changed() -> void:`
- `func _exit_tree() -> void:`
- `func set_unit_manager(unit_manager: UnitManager) -> void:`
- `func get_unit_manager() -> UnitManager:`
- `func set_animation_service(service) -> void:`
- `func set_task_manager(manager: TaskManager) -> void:`
- `func get_task_manager() -> TaskManager:`
- `func set_location_service(service: LocationService) -> void:`
- `func get_location_service() -> LocationService:`
- `func set_loot_manager(manager: LootManager) -> void:`
- `func get_loot_manager() -> LootManager:`
- `func set_combat_system(system: CombatSystem) -> void:`
- `func get_combat_system() -> CombatSystem:`
- `func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]:`
- `func is_at_full_morale() -> bool:`
- `func adjust_remaining_movement(amount: int) -> void:`
- `func on_enter_terrain(terrain: Variant) -> void:`
- `func add_skill(skill: Skill) -> void:`
- `func remove_skill(skill: Skill) -> void:`
- `func get_combat_profile() -> CombatPriorityProfile:`
- `func is_at_full_willpower() -> bool:`
- `func refresh_for_new_round() -> void:`
- `func set_free_roam_mode(enabled: bool) -> void:`
- `func is_in_free_roam_mode() -> bool:`
- `func consume_action() -> void:`
- `func block_movement_this_turn() -> void:`
- `func block_action_this_turn() -> void:`
- `func is_faction_leader(p_faction: int) -> bool:`
- `func set_faction_leader(p_faction: int, enabled: bool) -> void:`
- `func is_player_leader() -> bool:`
- `func set_player_leader(enabled: bool) -> void:`
- `func is_friendly(other: Unit) -> bool:`
- `func is_hostile(other: Unit) -> bool:`
- `func _die() -> void:`
- `func apply_consumable(pair_index: int, bonus: int) -> void:`
- `func prepare_for_save() -> void:`
- `func get_hover_info() -> String:`
- `func finalize_setup() -> void:`
- `func add_aid_buff(p_value: int, pair_index: int = -1) -> void:`
- `func consume_aid_buffs() -> void:`

### Gameplay/targets/unit_manager.gd
- `func reset() -> void:`
- `func begin_batch_placement() -> void:`
- `func end_batch_placement() -> void:`
- `func add_unit(unit: Unit, coord: Vector2i, player_controlled: bool = false) -> void:`
- `func get_nearest_empty_coord(requested_coord: Vector2i, max_radius: int = 5) -> Vector2i:`
- `func mark_retreat(unit: Unit) -> void:`
- `func remove_unit(unit: Unit) -> void:`
- `func get_all_units() -> Array[Unit]:`
- `func get_units() -> Array[Unit]:`
- `func get_unit_count() -> int:`
- `func get_player_units() -> Array[Unit]:`
- `func get_enemy_units() -> Array[Unit]:`
- `func get_neutral_units() -> Array[Unit]:`
- `func get_allied_units(unit: Unit) -> Array[Unit]:`
- `func get_faction_leader(faction: int) -> Unit:`
- `func set_faction_leader(leader: Unit, faction: int) -> void:`
- `func set_roster_for_faction(faction: int, roster: Resource) -> void:`
- `func get_roster_for_faction(faction: int) -> Resource:`
- `func reset_all_neutral_loyalties() -> void:`
- `func get_selected_unit() -> Unit:`
- `func get_selected_sprite() -> Unit:`
- `func get_units_by_faction(faction: int) -> Array[Unit]:`
- `func get_fleet_willpower(faction: int) -> int:`
- `func get_selected_index() -> int:`
- `func get_selected_coord() -> Vector2i:`
- `func get_coord_by_unit(unit: Unit) -> Vector2i:`
- `func get_unit(index: int) -> Unit:`
- `func get_coord(index: int) -> Vector2i:`
- `func set_coord(index: int, coord: Vector2i) -> void:`
- `func is_occupied(coord: Vector2i, ignore_index: int = GameConstants.INVALID_INDEX) -> bool:`
- `func get_unit_at_coord(coord: Vector2i) -> Unit:`
- `func is_player_controlled(index: int) -> bool:`
- `func set_player_controlled(index: int, is_controlled: bool) -> void:`
- `func force_select_index(index: int) -> void:`
- `func select_index(index: int) -> void:`
- `func cycle_selection(direction: int) -> void:`
- `func get_unit_index(unit: Unit) -> int:`
- `func apply_faction_stat_boost(faction: int, amount: int) -> void:`
- `func _apply_unit_stat_boost(unit: Unit, amount: int) -> void:`
- `func get_faction_max_willpower(faction: int, include_debug_boost: bool = true) -> int:`
- `func index_of_unit_at(coord: Vector2i) -> int:`
- `func can_player_act(index: int) -> bool:`
- `func create_memento() -> Dictionary:`
- `func restore_from_memento(memento: Dictionary) -> void:`

### Gameplay/targets/discovery/unit_discovery.gd
- `static func get_all_units(unit: Node) -> Dictionary:`
- `static func get_adjacent_units(unit: Node) -> Dictionary:`
- `static func get_relationship_units(unit: Node, unit_manager: Node, type: String) -> Array:`
- `static func get_units_in_range(source: Node2D, targets: Array, range_val: float, grid_map: TileMapLayer = null, filter: Callable = Callable()) -> Array:`
- `static func get_closest_target(source: Node2D, targets: Array, grid_map: TileMapLayer = null) -> Node2D:`
- `static func get_fleet_willpower(unit_manager: Node, faction: int) -> int:`
- `static func get_persuadable_neutrals(unit: Node, units: Array, axis: int) -> Array:`

### Gameplay/targets/components/unit_query_service.gd
- `func _init(unit: Unit) -> void:`
- `func has_nearby_units(units: Array, detection_range: float) -> bool:`
- `func get_units_in_range(units: Array, detection_range: float) -> Array[Unit]:`
- `func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array[Unit]:`
- `func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: int) -> Array[Unit]:`
- `func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]:`
- `func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array[Unit]:`
- `func list_locations_in_range(locations: Array, detection_range: float) -> Array:`
- `func invalidate_cache() -> void:`
- `func get_hostile_units() -> Array[Unit]:`
- `func get_friendly_units() -> Array[Unit]:`
- `func get_neutral_units() -> Array[Unit]:`
- `func get_closest_unit(units: Array) -> Unit:`
- `func get_unit_at(coord: Vector2i) -> Unit:`
- `func get_loot_at(coord: Vector2i) -> Loot:`
- `func get_location_at(coord: Vector2i) -> Location:`
- `func is_occupied(coord: Vector2i) -> bool:`
- `func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:`
- `func _get_relationship_units(type: String) -> Array[Unit]:`
- `func _get_axis() -> int:`
- `func _get_or_build(cache: Array, dirty_flag_var: String, builder_callable: Callable) -> Array:`

### Gameplay/turn/turn_controller.gd
- `func _init() -> void:`
- `func reset() -> void:`
- `func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:`
- `func configure_dependencies(checkpoint_manager: CheckpointManager, hud: Node, terrain_map) -> void:`
- `func start_next_turn() -> void:`
- `func complete_turn() -> void:`
- `func _start_unit_turn(index: int) -> void:`
- `func _start_new_round() -> void:`
- `func classify_unit_side(unit: Unit, index: int) -> int:`
- `func rebuild_turn_roster(preserve_state: bool = false) -> void:`
- `func _preserve_queue_state(old_queue: Array[int], units_by_side: Dictionary) -> void:`
- `func _consume_current_turn_entry() -> void:`
- `func _process_ai_turn(unit: Unit) -> void:`
- `func on_turn_changed(unit: Unit) -> void:`
- `func can_act_on_index(index: int) -> bool:`
- `func lock_active_player_unit(index: int) -> void:`
- `func complete_player_activation(index: int) -> void:`
- `func _sync_unit_manager_selection(index: int) -> void:`
- `func _is_unit_active(index: int) -> bool:`
- `func _refresh_all_units() -> void:`
- `func set_enabled(enabled: bool) -> void:`
- `func is_enabled() -> bool: return _enabled`
- `func set_player_auto_battle_enabled(enabled: bool) -> void: _auto_battle_service.set_enabled(enabled)`
- `func is_player_auto_battle_enabled() -> bool: return _auto_battle_service.is_enabled()`
- `func is_player_auto_control_locked() -> bool: return _auto_battle_service.is_in_progress()`
- `func force_disable_auto_battle(reason: String = "") -> void: _auto_battle_service.force_disable(reason)`
- `func is_queue_empty() -> bool: return _turn_system.is_queue_empty()`
- `func get_turn_queue() -> Array[int]: return _turn_system.get_turn_queue()`
- `func get_turn_system() -> TurnSystem: return _turn_system`
- `func get_current_unit_index() -> int: return _current_unit_index`
- `func get_current_side() -> int: return _current_turn_side`
- `func get_round() -> int: return _round`
- `func move_index_to_front(target_index: int, list_position: int) -> void: _turn_system.move_index_to_front(target_index, list_position)`
- `func set_current_unit_index(index: int) -> void: _turn_system.set_current_unit_index(index)`
- `func create_memento() -> Dictionary:`
- `func restore_from_memento(memento: Dictionary) -> void:`

## GUI

### GUI/hud_controller.gd
- `func emit_unit_details_visibility_changed(p_visible: bool) -> void:`
- `func emit_combat_preview_shown(attacker: Target, defender: Target) -> void:`
- `func emit_combat_preview_hidden() -> void:`
- `func emit_location_details_updated(location_data) -> void:`
- `func emit_task_details_updated(task_data) -> void:`
- `func emit_loot_details_updated(loot: Loot) -> void:`
- `func emit_terrain_details_updated(terrain: TerrainTile, distance: String) -> void:`
- `func emit_auto_battle_toggle_requested(enabled: bool) -> void:`
- `func _ready() -> void:`
- `func setup(state: GameState, components: HUDComponentFactory.Components, config: GameSessionBuilder.Config) -> void:`
- `func _on_locale_changed() -> void:`
- `func _update_initial_state() -> void:`
- `func set_aim_cursor(cursor: AimCursor) -> void:`
- `func set_safe_zone_mode(is_safe_zone: bool) -> void:`
- `func set_auto_battle_state(enabled: bool) -> void:`
- `func set_auto_battle_enabled(interactable: bool) -> void:`
- `func _process(_delta: float) -> void:`
- `func handle_actions_updated(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, _unit_index: int = -1) -> void:`
- `func handle_dialogue_finished(_flag_id: StringName) -> void:`
- `func _setup_hover_service() -> void:`
- `func refresh_after_state_restore() -> void:`
- `func set_ui_navigation_mode(enabled: bool) -> void:`
- `func _on_round_changed(_round: int = 0) -> void:`
- `func _on_turn_changed(_unit: Unit = null) -> void:`
- `func _on_turn_queue_updated() -> void:`
- `func _on_task_updated(_index: int, _faction: int) -> void:`
- `func _on_task_completed(_index: int, _faction: int, _unit: Unit = null) -> void:`
- `func _on_task_failed(_index: int, _faction: int) -> void:`
- `func _apply_safe_zone_visibility() -> void:`
- `func _set_panel_visible(panel: Node, p_visible: bool) -> void:`
- `func _update_round_and_turn() -> void:`
- `func _on_turn_system_enabled_changed(enabled: bool) -> void:`
- `func _on_objective_updated(objective: Objective) -> void:`
- `func _on_objective_completed(objective: Objective) -> void:`
- `func _update_objective_from_manager() -> void:`
- `func _update_objective_display(objective: Objective) -> void:`
- `func _update_task_progress() -> void:`
- `func _on_unit_manager_selection_changed(index: int) -> void:`
- `func _on_unit_removed(_unit: Unit) -> void:`
- `func _on_task_completion_requested(task_id: String) -> void:`
- `func _on_menu_requested(type: String, data: UnitAction) -> void:`
- `func update_compass(p_rotation: float) -> void:`
- `func show_feedback(text: String) -> void:`
- `func _on_hud_action_executed(action_type: int) -> void:`
- `func _on_attribute_hovered(idx: int) -> void:`
- `func calculate_distance_to_cell(cell: Vector2i) -> String:`
- `func _calculate_faction_turn_counts() -> Dictionary:`

### GUI/actions_panel.gd
- `func _ready() -> void:`
- `func _setup_hint_label() -> void:`
- `func _on_locale_changed() -> void:`
- `func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool = true) -> void:`
- `func _should_defer_update(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool) -> bool:`
- `func _handle_invalid_states(unit: Unit, unit_manager: UnitManager) -> bool:`
- `func _handle_no_actions(unit: Unit, available_actions: Array) -> bool:`
- `func _handle_no_actions(unit: Unit, available_actions: Array) -> bool:`
- `func _add_action_button(unit: Unit, action: UnitAction) -> Button:`
- `func show_attribute_menu(unit: Unit, action: UnitAction, move_info: Dictionary = {}) -> void:`
- `func _prepare_attribute_menu(_unit: Unit, action: UnitAction, move_info: Dictionary) -> bool:`
- `func _add_target_selector(unit: Unit, action: UnitAction, targets: Array[Target]) -> void:`
- `func _build_attribute_grid(unit: Unit, action: UnitAction) -> bool:`
- `func _build_aid_attribute_grid(unit: Unit, action: UnitAction, attrs) -> bool:`
- `func _build_standard_attribute_grid(_unit: Unit, action: UnitAction, attrs) -> bool:`
- `func _emit_attribute_action(action: UnitAction, idx: int, name: String, interact_type: UnitAction.Type) -> void:`
- `func _create_grid(cols: int) -> GridContainer:`
- `func _create_grid_button(grid: Control, txt: String) -> Button:`
- `func _add_label(txt: String) -> void:`
- `func _add_back_button() -> void:`
- `func _clear_actions() -> void:`
- `func _update_hint_visibility() -> void:`
- `func _show_hint(msg: String) -> void:`
- `func _show_actions_hint() -> void:`
- `func enable_navigation_mode() -> void:`
- `func disable_navigation_mode() -> void:`
- `func _focus_first() -> bool:`
- `func _register_focus_target(c: Control) -> void:`
- `func set_auto_battle_mode(active: bool) -> void:`
- `func get_current_attack_target() -> Target: return _current_attack_target`
- `func _get_action_label(a: UnitAction) -> String: return ActionLabelFormatter.get_label(a, ActionTargetHandler.get_target_name(a.target, _loc))`
- `func _get_action_hint(a: UnitAction) -> String: return ActionLabelFormatter.get_hint(a)`
- `func _get_target_name(t: Target) -> String: return ActionTargetHandler.get_target_name(t, _loc)`


## Level

### level/Level.gd
- `func _init() -> void:`
- `func _ensure_default_terrain_data() -> void:`
- `func _regenerate_location_entries_from_coords() -> void:`

### level/level_manager_gameplay.gd
- `func _init(game_state: GameState, controls: Node) -> void:`
- `func set_save_manager(save_manager: SaveManager) -> void:`
- `func set_dialogue_service(service: DialogueActionService) -> void:`
- `func set_auto_fix_enabled(enabled: bool) -> void:`
- `func set_level_resource(level: Level) -> void:`
- `func prepare_level_data() -> void:`
- `func clear_world() -> void:`
- `func build_environment() -> Dictionary:`
- `func spawn_global_content() -> void:`
- `func finalize_setup() -> void:`
- `func apply_level_if_available() -> void:`
- `func _create_build_context() -> LevelBuildContext:`
- `func _handle_build_result(result: Dictionary) -> void:`
- `func _connect_morale_panel_signals() -> void:`
- `func set_level_and_rebuild(level: Level) -> void:`
- `func on_task_reached() -> void:`
- `func update_task_progress() -> void:`
- `func on_task_failed() -> void:`
- `func _get_level_id_for_level(level: Level) -> StringName:`
- `func _apply_row_resources(level: Level) -> void:`
- `func _is_hometown_level(level: Level) -> bool:`
- `func _queue_hometown_progression_dialogues() -> void:`
- `func on_unit_moved(index: int, coord: Vector2i) -> void:`
- `func _apply_hometown_exploration_rules() -> void:`
- `func _get_primary_player_unit() -> Unit:`

## Menus

### Menus/title_screen.gd
- `func _ready() -> void:`
- `func set_quit_callback(callback: Callable) -> void:`
- `func _on_start_pressed() -> void:`
- `func _on_quit_pressed() -> void:`
- `func _on_level_select() -> void:`
- `func _unhandled_input(event: InputEvent) -> void:`
- `func _is_relevant_press(event: InputEvent) -> bool:`
- `func _is_quit_event(event: InputEvent) -> bool:`
- `func _is_start_event(event: InputEvent) -> bool:`
- `func _contains(values: PackedInt32Array, value: int) -> bool:`
- `func _mark_input_handled() -> void:`

## Resources

### Resources/file_paths_loader.gd
- `static func load_paths() -> FilePathsLoader:`
- `func _load_internal() -> void:`
- `func get_path(path_key: String) -> String:`
- `func get_category(category: String) -> Dictionary:`
- `func get_warnings() -> Array[String]:`
- `func get_dynamic_paths() -> Dictionary:`
- `func validate_paths() -> Dictionary:`
- `func _validate_category_recursive(category: String, dict: Dictionary, results: Dictionary) -> void:`
- `func get_errors() -> Array[String]:`
- `func print_summary() -> void:`
- `func _count_paths(dict: Dictionary) -> int:`
- `static func get_scene(scene_key: String) -> String:`
- `static func get_autoload(autoload_key: String) -> String:`
