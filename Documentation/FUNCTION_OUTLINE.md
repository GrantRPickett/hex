# Project Function Outline

## Autoloads

### Autoloads/achievement_manager.gd

- func _ready()
- func unlock_achievement()
- func get_savable_data()
- func load_savable_data()

### Autoloads/audio_bus_controller.gd

- func _ready()
- func _apply_saved_settings()
- func set_bus_volume_db()
- func get_bus_volume_db()
- func mute_bus()
- func is_bus_muted()
- func play_music()
- func stop_music()
- func _ensure_bus()

### Autoloads/audio_manager.gd

- func _ready()
- func _setup_sfx_pool()
- func _connect_to_event_bus()
- func play_sfx()
- func _get_next_player()

### Autoloads/control_settings.gd

- func _ready()
- func _initialize_input_map()
- func reset_inputs_to_defaults()

### Autoloads/difficulty_service.gd

- func _ready()
- func _on_config_changed()
- func get_ai_scaling_factor()
- func get_ai_morale_weight()
- func get_retreat_threshold()
- func get_combat_modifier()

### Autoloads/display_settings.gd

- func _ready()
- func _load_stored_settings()
- func _get_stored_orientation_name()
- func _resolve_resolution()
- func _find_resolution_index()
- func _apply_window_settings()
- func _get_active_window_id()
- func get_standard_resolutions()
- func get_current_orientation()
- func get_current_resolution_index()
- func get_current_resolution()
- func set_orientation()
- func set_resolution_index()

### Autoloads/event_bus.gd

- (No functions defined)

### Autoloads/file_paths.gd

- static func get_dialogue_path()
- static func get_level_path()
- static func get_path_separator()
- static func join_path()
- static func path_exists()
- static func get_all_categories()
- static func get_all_paths()

### Autoloads/game_config.gd

- func _ready()
- func reset_to_defaults()
- func set_value()
- func get_value()
- func save_config()
- func load_config()
- func _set_by_path()
- func _get_by_path()
- func _deep_merge()

### Autoloads/game_constants.gd

- func get_attribute_name()
- func get_attribute_index()
- func get_attribute_color()
- func get_attribute_opposite()
- func get_opposite_name()
- func get_attribute_value()
- func colorize_attributes()
- func get_faction_name()

### Autoloads/game_logger.gd

- func _format_msg()
- func info()
- func debug()
- func warning()
- func error()
- func _log_message()
- func _log_error()
- func _init()

### Autoloads/input_mapper.gd

- func apply_configs()
- func map_action()
- func clear_action()
- func _as_int_array()

### Autoloads/item_registry.gd

- func _ready()
- func _load_templates()
- func get_template()
- func get_all_templates()
- func create_instance()

### Autoloads/journal_manager.gd

- func setup()
- func _ready()
- func set_level()
- func _ensure_initialized()
- func _initialize_default_content()
- func unlock_entry()
- func clear_journal()
- func unlock_coupled_entry()
- func get_journal_data()
- func get_entry()
- func get_section()
- func get_savable_data()
- func load_savable_data()
- func _on_objective_updated()
- func _on_task_completed_signal()
- func _on_task_failed_signal()
- func _on_objective_completed()
- func _add_or_update_objective_entry()
- func _add_or_update_stage_entry()
- func _add_or_update_task_entry()
- func _generate_entry_id()
- func _get_objective_section()
- func _on_task_status_changed()
- func _task_status_to_string()

### Autoloads/level_manager.gd

- func _ready()
- func start_level_by_id()
- func start_first_level()
- func get_level_info()
- func is_level_unlocked()
- func mark_level_completed()
- func get_available_levels()
- func get_current_level_path()
- func get_current_level_id()
- func is_level_completed()
- func reset_completed_levels()
- func _on_level_complete()
- func _on_quit_to_title()
- func _on_quit_to_level_select()

### Autoloads/locale_service.gd

- func _ready()
- func _notification()
- func apply_locale_settings()
- func _apply_font_for_locale()

### Autoloads/resource_loader_service.gd

- func collect_resources_recursive()
- func load_resources_in_dir()

### Autoloads/roster_manager.gd

- func _ready()
- func _exit_tree()
- func get_roster()
- func get_units()
- func save_roster()
- func transfer_item()
- func toggle_item_equip()
- func swap_items()
- func add_to_stash()
- func auto_equip()
- func debug_reset_roster()
- func sync_from_combat()
- func sync_to_combat()
- func sync_unit()
- func _sync_single_unit_to_roster()
- func _load_roster()
- func _instantiate_units()
- func _setup_unit()
- func _clear_loaded_units()

### Autoloads/save_manager.gd

- func _ready()
- func _setup_timer()
- func setup()
- func set_global_flag()
- func get_global_flags()
- func set_level_flag()
- func get_level_flags()
- func set_value()
- func get_value()
- func save_roster()
- func load_roster()
- func has_saved_roster()
- func set_hometown_skit_shown()
- func get_hometown_skits()
- func get_leader_unit_name()
- func set_leader_unit_name()
- func get_completed_levels_count()
- func get_difficulty()
- func _load_data()
- func _save_data()
- func _perform_actual_save()
- func trigger_hard_save()
- func get_hard_save_metadata()
- func load_hard_save()
- func has_resumable_session()
- func get_last_hard_save_index()
- func flush_mementos()
- func create_game_memento()
- func _merge_system_data()
- func _capture_state_mementos()
- func restore_game_state()
- func _distribute_loaded_data()
- func _distribute_session_state()
- func _distribute_config_data()
- func _distribute_roster_data()
- func _distribute_journal_data()
- func _distribute_achievement_data()
- func _distribute_weather_data()
- func _load_saved_roster_resource()
- func _restore_roster_units()
- func _load_default_player_roster()
- func _load_roster_from_resource()
- func save_current_state_for_undo()
- func undo_state()
- func redo_state()
- func _get_journal_manager()
- func _get_achievement_manager()
- func get_all_skits()

### Autoloads/scene_transition.gd

- func change_scene()
- func reload_current()
- func is_changing()

### Autoloads/weather_manager.gd

- func is_hard_mode()
- func _ready()
- func add_pressure()
- func remove_pressure()
- func set_current_pressures()
- func clear_pressures()
- func _notify_changed()
- func advance_weather()
- func start_channeling()
- func get_channeling_unit()
- func create_memento()
- func restore_from_memento()
- func get_weather_info()
- func _get_basic_weather_info()
- func _get_hard_mode_weather_info()
- func apply_weather_effects()
- func get_current_weather_attribute()

## GUI

### GUI/action_target_handler.gd

- static func populate_target_lists()
- static func get_target_name()
- static func format_target_button_text()

### GUI/actions_panel.gd

- func _ready()
- func _setup_hint_label()
- func _on_locale_changed()
- func update_actions()
- func _should_defer_update()
- func _handle_invalid_states()
- func _handle_no_actions()
- func _add_action_button()
- func _needs_attribute_grid()
- func show_attribute_menu()
- func _prepare_attribute_menu()
- func _add_target_selector()
- func _emit_target_action()
- func _build_attribute_grid()
- func _build_aid_attribute_grid()
- func _build_standard_attribute_grid()
- func _emit_attribute_action()
- func _create_grid()
- func _create_grid_button()
- func _add_label()
- func _add_back_button()
- func _clear_actions()
- func _update_hint_visibility()
- func _show_hint()
- func _show_actions_hint()
- func enable_navigation_mode()
- func disable_navigation_mode()
- func _focus_first()
- func _register_focus_target()
- func set_auto_battle_mode()
- func get_current_attack_target()
- func get_active_action()
- func _get_action_label()
- func _get_action_hint()
- func _get_target_name()

### GUI/combat_preview_panel.gd

- func _ready()
- func _on_locale_changed()
- func show_preview()
- func show_forecast()
- func show_aid_forecast()
- func _format_attribute_name()
- func _get_target_name()
- func _update_panel_layout()
- func _on_display_settings_changed()
- func _update_layout()
- func hide_preview()

### GUI/Compass.gd

- func _ready()

### GUI/custom_resizable_panel.gd

- func _ready()
- func _update_padding()
- func _update_min_size()
- func force_fit_content()

### GUI/feedback_display.gd

- func _init()
- func show_feedback()

### GUI/hover_info_panel.gd

- func set_info()

### GUI/HUD/aim_cursor.gd

- func _draw()
- func _ready()
- func set_initial_position()
- func connect_input_handler()
- func get_effective_cursor_position()
- func is_virtual_active()
- func _on_joy_aim_held()
- func _process()
- func _update_crosshair()

### GUI/HUD/hover_info_manager.gd

- func _init()
- func _ready()
- func _reparent_to_root()
- func set_info()
- func _hide_hover_info()
- func _process()
- func _update_position()
- func _get_hovered_object_at()
- func _show_hover_info()
- func get_hex_occupants_at_mouse_position()
- func get_unit_at_mouse_position()

### GUI/HUD/HoverStates/combat_preview_state.gd

- func can_enter()
- func update()
- func _get_combat_target_at()
- func exit()

### GUI/HUD/HoverStates/hover_state.gd

- func can_enter()
- func enter()
- func update()
- func exit()

### GUI/HUD/HoverStates/idle_state.gd

- func can_enter()

### GUI/HUD/HoverStates/location_hover_state.gd

- func can_enter()
- func update()
- func exit()

### GUI/HUD/HoverStates/loot_hover_state.gd

- func can_enter()
- func update()
- func exit()

### GUI/HUD/HoverStates/task_hover_state.gd

- func can_enter()
- func update()
- func exit()

### GUI/HUD/HoverStates/terrain_hover_state.gd

- func can_enter()
- func update()
- func exit()

### GUI/HUD/HoverStates/unit_hover_state.gd

- func can_enter()
- func update()
- func exit()

### GUI/HUD/hud_component_factory.gd

- func setup()
- func update_layout()
- func _get_setup_method_info()
- static func create_components()
- static func _populate_from_scene()
- static func _populate_landscape()
- static func _populate_portrait()
- static func _create_layout_containers()
- static func _populate_components()
- static func _populate_left_column()
- static func _populate_right_column()
- static func _create_right_column_buttons()
- static func _create_right_column_panels()
- static func _populate_center_sections()
- static func _instantiate_panel()
- static func _create_button()

### GUI/HUD/hud_config.gd

- func with_components()
- func with_turn_system()
- func with_unit_manager()
- func with_task_manager()
- func with_loot_manager()
- func with_combat_system()
- func with_pause_handler()
- func with_terrain_map()
- func with_map_controller()
- func with_animation_service()
- func with_locations_list_panel()
- func with_location_details_panel()
- func with_tasks_list_panel()
- func with_task_details_panel()
- func with_task_controller()
- func with_location_service()
- func build()

### GUI/HUD/hud_controller.gd

- func emit_unit_details_visibility_changed()
- func emit_combat_preview_shown()
- func emit_combat_preview_hidden()
- func emit_location_details_updated()
- func emit_task_details_updated()
- func emit_loot_details_updated()
- func emit_terrain_details_updated()
- func emit_auto_battle_toggle_requested()
- func _ready()
- func setup()
- func _on_unit_damaged()
- func _on_combat_action_performed()
- func _on_aid_action_performed()
- func _trigger_action_feedback()
- func setup()
- func _on_locale_changed()
- func _update_initial_state()
- func set_aim_cursor()
- func set_safe_zone_mode()
- func set_auto_battle_state()
- func set_auto_battle_enabled()
- func _process()
- func handle_actions_updated()
- func handle_dialogue_finished()
- func _setup_hover_service()
- func refresh_after_state_restore()
- func set_ui_navigation_mode()
- func _on_round_changed()
- func _on_turn_changed()
- func _on_turn_queue_updated()
- func _on_task_updated()
- func _on_task_completed()
- func _on_task_failed()
- func _apply_safe_zone_visibility()
- func _set_panel_visible()
- func _on_display_settings_changed()
- func _update_layout()
- func _swap_hud_layout()
- func _connect_portrait_tabs()
- func _on_portrait_tab_pressed()
- func _get_portrait_tabs()
- func _is_tab_already_visible()
- func _hide_all_portrait_tabs()
- func _update_portrait_tab_visibility()
- func _handle_tab_specific_activation()
- func _update_round_and_turn()
- func _on_turn_system_enabled_changed()
- func _on_objective_updated()
- func _on_objective_completed()
- func _update_objective_from_manager()
- func _update_objective_display()
- func _update_task_progress()
- func _on_unit_manager_selection_changed()
- func _on_selected_unit_willpower_changed()
- func _on_unit_manager_unit_moved()
- func _refresh_unit_details()
- func _on_unit_removed()
- func _on_task_completion_requested()
- func _on_location_selected()
- func _on_task_selected()
- func _on_menu_requested()
- func update_compass()
- func show_feedback()
- func _on_hud_action_executed()
- func _on_attribute_hovered()
- func _hide_combat_preview()
- func _resolve_hover_target()
- func _show_action_preview()
- func _show_aid_preview()
- func calculate_distance_to_cell()
- func _calculate_faction_turn_counts()

### GUI/HUD/hud_hover_service.gd

- func setup()
- func _init_hover_states()
- func process_hover()
- func update_hover_info()
- func _are_hover_dependencies_valid()
- func _clear_all_hover_states()
- func force_hover_update()

### GUI/HUD/hud_signal_connector.gd

- func setup()
- func connect_all()
- func _connect_task_manager_signals()
- func _connect_turn_system_signals()
- func _connect_components()
- func _connect_round_info()
- func _connect_locations_list()
- func _connect_terrain_details()
- func _connect_tasks_list()
- func _connect_unit_details()
- func _connect_combat_preview()
- func _connect_location_details()
- func _connect_task_details()
- func _connect_loot_details()
- func _connect_actions_panel()
- func _connect_system_controls()
- func _connect_auto_battle_controls()
- func _connect_pause_controls()
- func _connect_debug_controls()
- func _connect_debug_stat_buttons()
- func _apply_debug_stat_boost()
- func _connect_hud_signals()
- func _connect_unit_manager_signals()

### GUI/HUD/hud_task_presenter.gd

- static func transform_objective_to_data()
- static func _transform_task()

### GUI/HUD/interaction_log_panel.gd

- func _ready()
- func setup()
- func _on_interaction_logged()
- func _on_mouse_entered()
- func _on_mouse_exited()
- func _on_gui_input()

### GUI/HUD/threat_warning_service.gd

- func evaluate()
- func needs_confirmation()
- func acknowledge_warning()
- func reset()

### GUI/hud.gd

- func _ready()
- func setup()
- func set_animation_service()
- func _create_default_ui()
- func on_action_selected()
- func on_command_executed()
- func _refresh_actions_after_command()
- func _sync_selected_unit()
- func _resolve_tentative_move_if_needed()
- func _await_tentative_resolution()
- func show_warning_message()
- func _create_warning_label()
- func _fallback_warning_flash()
- func _create_panel()
- func _create_vbox()
- func _create_label()

### GUI/hud_action_executor.gd

- func _init()
- func execute_action()
- func _try_execute_mapped_command()
- func _run_input_command()
- func _command_success()
- func _execute_attack_command()
- func _execute_attack_payload()
- func _execute_aid_command()
- func _execute_convince_command()
- func _execute_convince_payload()
- func _execute_loot_command()
- func _execute_loot_payload()
- func _execute_skill_command()
- func _execute_talk_command()
- func _execute_move_and_interact_action()
- func _move_unit_to_coord()
- func _convert_action_to_dict()

### GUI/inventory/inventory_character_panel.gd

- func setup()
- func _on_item_changed()
- func _ready()
- func refresh()
- func _update_layout()
- func _add_stat_row()
- func _can_drop_data()
- func _drop_data()
- func set_highlight()

### GUI/inventory/inventory_item_slot.gd

- func setup()
- func _ready()
- func _update_ui()
- func _get_drag_data()
- func set_highlight()
- func _can_drop_data()
- func _drop_data()

### GUI/journal_ui.gd

- func _unhandled_input()
- func _ready()
- func _on_locale_changed()
- func _on_display_settings_changed()
- func _update_layout()
- func setup()
- func _on_journal_updated()
- func _populate_sections()
- func _on_section_selected()
- func _populate_topics()
- func find_item_by_metadata()
- func _on_topic_selected()

### GUI/location_details_panel.gd

- func setup()
- func _ready()
- func _setup_back_button()
- func _on_back_pressed()
- func _on_locale_changed()
- func update_details()

### GUI/location_display_item.gd

- func _ready()
- func _on_gui_input()
- func set_location_data()

### GUI/locations_list_panel.gd

- func _init()
- func _ready()
- func update_locations()
- func _update_display()
- func _on_show_more_pressed()
- func _on_display_settings_changed()
- func _update_layout()

### GUI/loot_details_panel.gd

- func _init()
- func _ready()
- func update_details()
- func _on_display_settings_changed()
- func _update_layout()

### GUI/morale_panel.gd

- func _ready()
- func _on_locale_changed()
- func setup()
- func _connect_unit_signals()
- func _on_unit_data_changed()
- func _on_willpower_changed()
- func _ensure_controls_ready()
- func update_morale_display()
- func _safe_ratio()
- func _update_labels()
- func _update_label_tooltip()
- func _update_bars()
- func _check_all_retreats()
- func _get_willpower_stats()
- func _check_retreat_condition()
- func faction_label_to_id()
- func _recalculate_initial_max_willpower()
- func reset_state()

### GUI/round_info_panel.gd

- func _init()
- func _ready()
- func _on_locale_changed()
- func update_round()
- func update_turn()
- func update_enabled()
- func update_turn_status()
- func _on_display_settings_changed()
- func _update_layout()

### GUI/task_details_panel.gd

- func _ready()
- func _setup_back_button()
- func _on_back_pressed()
- func setup()
- func _on_locale_changed()
- func update_details()

### GUI/task_display_item.gd

- func _ready()
- func set_task_data()

### GUI/task_list_item.gd

- func _ready()
- func _on_gui_input()
- func _setup_debug_button()
- func _on_debug_button_pressed()
- func _on_mouse_entered()
- func _on_mouse_exited()
- func update_task()

### GUI/tasks_list_panel.gd

- func _ready()
- func _on_header_toggled()
- func _on_locale_changed()
- func update_tasks()
- func _update_display()
- func _on_show_more_pressed()
- func _on_display_settings_changed()
- func _update_layout()

### GUI/terrain_details_panel.gd

- func _ready()
- func _on_locale_changed()
- func update_details()

### GUI/unit_details_panel.gd

- func _init()
- func _ready()
- func _on_locale_changed()
- func update_details()
- func _on_unit_attributes_changed()
- func _handle_null_unit()
- func _capture_unit_state()
- func _has_state_changed()
- func _apply_unit_details()
- func _on_display_settings_changed()
- func _update_layout()
- func _update_basic_info()
- func _update_stats_display()
- func _update_stress_display()
- func _update_movement_display()
- func _update_status_display()
- func _update_attributes_display()
- func _update_inventory_display()

### GUI/weather_display_ui.gd

- func _ready()
- func _on_weather_changed()

### GUI/weather_panel.gd

- func _ready()
- func _on_locale_changed()
- func _on_pressures_changed()
- func _on_forecast_changed()
- func _update_ui()
- func force_fit_content()
- func update_compass()
- func _on_display_settings_changed()
- func _update_layout()
- func _update_font_sizes()
- func _update_visibility()

## Gameplay

### Gameplay/animation_request_service.gd

- func should_skip_delays()
- func setup()
- func set_tween_factory()
- func request_unit_move()
- func on_unit_moved()
- func request_feedback_float()
- func request_warning_flash()
- func request_property_animation()
- func _get_style()
- func _create_tween_for()
- func _connect_completion()
- func set_batch_deferred()
- func flush_batch()
- func _is_batch_mode_active()
- func _prepare_move_data()
- func _execute_move_animation()
- func get_effective_duration()

### Gameplay/batch_animation_buffer.gd

- func add_move()
- func add_generic()
- func clear()
- func get_requests()
- func is_empty()

### Gameplay/camera_controller.gd

- func setup()
- func init_camera_snap()
- func set_batch_mode()
- func center_on_selected()
- func on_unit_moved()
- func get_camera_rotation()
- func toggle_free_cam()
- func zoom()
- func pan_camera()
- func handle_camera_input()

### Gameplay/camera_handler.gd

- func setup()
- func init_camera_snap()
- func rotate_camera()
- func zoom()
- func set_initial_rotation()
- func center_on_position()
- func set_free_cam()
- func is_free_cam()
- func pan_camera()
- func get_camera_rotation()
- func handle_camera_input()
- func _unhandled_input()
- func _apply_camera_rotation_from_step()

### Gameplay/combat/combat_priority_profile.gd

- func get_weight()

### Gameplay/commands/aid_ally_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/attack_unit_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/cancel_move_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/command_factory.gd

- static func _get_script_metadata()
- static func create_default_command_set()
- static func create_command_by_id()
- static func get_command_metadata()

### Gameplay/commands/command_history.gd

- static func push_snapshot()
- static func pop_snapshot()
- static func undo()

### Gameplay/commands/command_result.gd

- func _init()
- static func success()
- static func failed()
- static func invalid_context()
- static func invalid_payload()
- static func precondition_failed()
- func is_success()
- func is_failure()
- func get_description()
- func get_error_message()

### Gameplay/commands/command_validator.gd

- static func validate_context()
- static func validate_payload_exists()
- static func validate_payload_type()
- static func validate_payload_dict_keys()
- static func validate_int()
- static func validate_vector2i_in_bounds()
- static func validate_active_unit()
- static func type_string()

### Gameplay/commands/confirm_move_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/convince_unit_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/explore_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()
- func _resolve_task_and_location()
- func _find_task_for_location()
- func _get_task_manager()

### Gameplay/commands/game_command.gd

- static func get_command_name()
- static func get_command_description()
- static func _get_command_id()
- func execute()
- func get_required_context_fields()
- func validate_context()

### Gameplay/commands/game_command_context.gd

- func _init()
- func is_valid()
- func get_missing_dependencies()
- func get_field()
- func get_grid_dimensions()
- func get_selected_unit_index()
- func get_selected_unit()

### Gameplay/commands/input_command_router.gd

- func _init()
- func set_context()
- func set_commands()
- func register_command()
- func _get_command_name()
- func execute()

### Gameplay/commands/joy_move_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/loot_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()
- func _get_loot_target()

### Gameplay/commands/move_action_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/move_to_coord_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()
- func _extract_coord()

### Gameplay/commands/primary_action_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()
- func _resolve_interaction_type()

### Gameplay/commands/select_index_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/selection_cycle_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/talk_to_unit_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/toggle_enemy_range_command.gd

- static func _get_command_id()
- func execute()
- func get_required_context_fields()

### Gameplay/commands/toggle_free_cam_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/trapped_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()
- func _resolve_loot_target()

### Gameplay/commands/trigger_dialogue_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/undo_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/use_skill_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/visit_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()
- func _resolve_task_and_location()
- func _find_task_for_location()
- func _get_task_manager()

### Gameplay/commands/wait_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/commands/zoom_camera_command.gd

- static func _get_command_id()
- func get_required_context_fields()
- func execute()

### Gameplay/default_game_session_service_factory.gd

- func create_services()
- func _create_unit_controller()

### Gameplay/game_session.gd

- func _init()
- func initialize()
- func _initialize_technical_systems()
- func _attach_services()
- func end_session()
- func add_unit()
- func set_unit_controlled_by_player()
- func handle_pause_state_changed()
- func handle_hud_toggle()
- func _update_terrain_overlay()
- func disable_gameplay()

### Gameplay/game_session_builder.gd

- func set_roster_loader()
- func build()
- func _prepare_services()
- func _validate_required_services()
- func _setup_core_systems()
- func _setup_input_and_hud()
- func _setup_hud()
- func _setup_command_infrastructure()
- func _setup_dialogue_logic()
- func _register_observers()
- func _register_ui_signals()
- func _register_task_dialogue_signals()
- func _register_turn_and_task_signals()
- func _register_combat_and_world_signals()
- func _register_visual_signals()
- func _create_game_state()
- func load_player_roster()
- func load_enemy_roster()
- func load_neutral_roster()
- func _get_roster_loader()

### Gameplay/game_session_service_factory.gd

- func create_services()

### Gameplay/game_state.gd

- func _init()
- func get_tree_nodes()
- func get_hud()

### Gameplay/gameplay.gd

- func _ready()
- func _init_dependencies()
- func _init_session()
- func _setup_level_manager()
- func _connect_game_signals()
- func _finish_setup()
- func _resolve_dependency()
- func _on_quit_requested()
- func set_turn_system_enabled()
- func set_level_and_rebuild()
- func _update_terrain_overlay()
- func _disable_gameplay()
- func _exit_tree()

### Gameplay/hometown_progression_service.gd

- func _init()
- func get_all_level_ids()
- func get_all_skits()
- func sort_skits_by_level()
- func filter_skits_by_unseen()
- func filter_skits_by_unlocked()
- func queue_dialogue()
- func pop_skit()
- func watch_skit()
- func mark_skit_seen()

### Gameplay/inputs/combat_input_state.gd

- func handle_action()
- func handle_input()

### Gameplay/inputs/input_actions.gd

- (No functions defined)

### Gameplay/inputs/input_binding_service.gd

- func apply_bindings()
- func save_bindings()
- func restore_defaults()
- func _register_events()
- func _apply_from_controls()
- func _apply_action_group()

### Gameplay/inputs/input_controller.gd

- func setup()
- func apply_command_set()
- func _connect_signals()
- func _unhandled_input()
- func _on_move_requested()
- func _on_selection_cycle_requested()
- func _on_select_index_requested()
- func _on_free_cam_toggle_requested()
- func _on_toggle_enemy_range_requested()
- func _on_joy_axis_held()
- func _on_zoom_requested()
- func _on_primary_action_at()
- func _on_secondary_action_at()
- func _on_wait_requested()
- func _on_confirm_move_requested()
- func _on_ui_nav_toggle_requested()
- func _on_drag_interacted()
- func _on_pan_requested()
- func execute_command()
- func _execute_command()
- func _register_input_actions()
- func _default_command_set()
- func set_ui_navigation_mode()
- func request_select_index()
- func request_selection_cycle()
- func request_wait()
- func register_input_actions()
- func _mark_input_handled()

### Gameplay/inputs/input_handler.gd

- func _ready()
- func _notification()
- func _physics_process()
- func _unhandled_input()
- func _handle_drag()
- func _should_ignore_input()
- func _handle_auto_battle_toggle()
- func _handle_camera_interception()
- func _handle_core_gameplay_inputs()
- func reset_joy_state()
- func set_ui_navigation_mode()
- func refresh_action_cache()
- func _handle_gameplay_actions()
- func _handle_selection_actions()
- func _handle_camera_actions()
- func _handle_camera_pan_actions()
- func _mark_input_handled()
- func _event_matches_action()
- func _handle_joypad_motion()
- func _process_joy_axis()
- func _handle_ui_nav_toggle()

### Gameplay/inputs/input_state.gd

- func _init()
- func enter()
- func exit()
- func handle_action()
- func handle_input()

### Gameplay/interaction/interaction_rules.gd

- static func location_interaction_cost()
- static func unit_talk_cost()

### Gameplay/map/display_orientation.gd

- static func from_string()
- static func to_name()

### Gameplay/map/grid_query_service.gd

- func setup()
- func world_to_map()
- func map_to_world()
- func get_distance()
- func snap_to_grid()
- func is_unit_at()
- func get_unit_at()
- func is_loot_at()
- func get_loot_at()
- func get_terrain()
- func is_passable()
- func get_location_at()
- func is_blocked()
- func get_all_at()
- func get_neighbors()
- func get_nearest_empty_coord()

### Gameplay/map/grid_utility.gd

- static func find_nearest()

### Gameplay/map/grid_visuals.gd

- func _ready()
- func set_suppress_updates()
- func setup_hex_shape()
- func update_hover_indicator()
- func update_path_preview()
- func update_range_indicator()
- func update_terrain_overlay()
- func toggle_enemy_range_view()
- func is_enemy_range_visible()
- func update_enemy_range_overlay()
- func update_dialogue_indicators()
- func _clear_children()
- func _try_draw_tentative_path_preview()
- func _draw_hover_path_preview()
- func _draw_range_indicators()
- func _draw_aoo_threats()
- func _get_threatened_hexes()
- func _draw_threatened_hexes_overlay()
- func _create_overlay_polygon()
- func _get_cached_texture()
- func _build_hex_points()
- func refresh_visuals()
- func show_threatened_path_hex()

### Gameplay/map/hex_lib.gd

- static func get_distance()
- static func get_neighbor_offsets()
- static func map_to_axial()
- static func axial_to_map()
- static func is_in_bounds()
- static func key_of()
- static func dims_of()

### Gameplay/map/hex_navigator.gd

- func get_direction_map()
- func cache_analog_vectors()
- func map_action_by_camera()
- func get_action_from_joy_axis()
- func _get_closest_action()

### Gameplay/map/map_controller.gd

- func setup()
- func get_terrain_map()
- func get_grid()
- func on_loot_added()
- func configure_tileset()
- func build_grid()

### Gameplay/map/move_controller.gd

- func _ready()
- func setup()
- func update_grid_dimensions()
- func request_move()
- func request_move_tentative()
- func request_move_to_coord()
- func confirm_move()
- func cancel_move()
- func cancel_tentative_move_for_index()
- func force_action_menu_update()
- func is_move_locked()
- func _release_move_lock_deferred()
- func _release_move_lock()
- func _is_move_blocked()
- func _reset_warnings()
- func _validate_manager_state()
- func _handle_existing_tentative_move()
- func _check_post_move_actions()
- func _should_abort_move()
- func _get_active_unit_context()
- func _prepare_move_operation()
- func _prepare_confirmation_operation()
- func _execute_direction_move()
- func _execute_tentative_direction_move()
- func _execute_coordinate_move()
- func _validate_tentative_move_exists()
- func _handle_threat_confirmation()
- func _finalize_move()
- func _perform_cancellation()
- func _on_weather_effect_applied()
- func _on_unit_selection_changed()

### Gameplay/map/move_execution_service.gd

- func execute_move()
- func finalize_tentative_move()
- func evaluate_post_move()

### Gameplay/map/move_request_validator.gd

- func validate_direction_move()
- func _resolve_next_coord()
- func _validate_basic_movement()
- func _calculate_move_cost()
- func validate_coordinate_move()

### Gameplay/map/movement_range_calculator.gd

- func compute()
- func _validate_compute_inputs()
- func _process_compute_node()
- func _can_enter_neighbor_compute()
- func find_path()
- func _pop_best_frontier_entry()
- func _is_valid_neighbor_for_path()
- func _process_path_neighbor()
- func _reconstruct_path()

### Gameplay/map/movement_range_service.gd

- static func calculate_reachable_state()
- static func find_path()

### Gameplay/map/reachable_state.gd

- static func create_empty()

### Gameplay/map/terrain_map.gd

- func set_source_id()
- func get_source_id()
- func set_offset_axis()
- func get_offset_axis()
- func load_from_rows()
- func is_within_bounds()
- func get_terrain()
- func is_passable()
- func get_movement_cost()
- func get_neighbors()
- func get_version()
- func get_code()
- func get_color_for_code()
- func get_all_terrain_colors()
- func _clear_tiles()
- func _get_code()

### Gameplay/narrative/dialogue/dialogue_action_service.gd

- func setup()
- func _on_flag_changed()
- func _get_grid_axis()
- func set_level()
- func prepare_for_level()
- func register_triggers()
- func append_dialogue_actions()
- func get_trigger_at()
- func trigger_at_coord()
- func handle_dialogue_request()
- func _start_direct_dialogue()
- func set_autoplay_enabled()
- func set_autoplay_delay()
- func set_text_speed()
- func skip_active_dialogue()
- func is_dialogue_active()
- func has_active_dialogue_with()
- func start_dialogue()
- func _load_dialogue_resource()
- func _create_fallback_dialogue_resource()
- func _on_dialogue_finished()
- func _hide_hud_before_dialogue()
- func _show_hud_after_dialogue()
- func _setup_dialogue_state()
- func _get_character_states()
- func _mark_dialogue_seen_globally()
- func _resolve_level_identifier()
- func show_floating_text()

### Gameplay/narrative/dialogue/dialogue_state.gd

- func has_flag()
- func set_flag()
- func get_character_stat()
- func get_character()

### Gameplay/narrative/dialogue/dialogue_trigger.gd

- func configure_from_entry()
- func set_group()
- func get_dialogue_id()
- func get_action_label()
- func get_dialogue_resource()
- func matches_initiator()
- func matches_partner()
- func mark_seen()
- func reset_seen()
- func requires_initiator_action()
- func allows_partner_initiation()
- func assign_coord_on_grid()
- func _matches_role()
- func has_journal()
- func get_journal_entry_id()
- func get_journal_section_id()
- func get_journal_topic_id()
- func get_journal_notes()
- func get_journal_flag_name()
- func get_resource_path()

### Gameplay/narrative/dialogue/dialogue_trigger_evaluator.gd

- func setup()
- func set_grid_axis()
- func is_trigger_available()
- func append_dialogue_actions()
- func collect_partner_indices()
- func collect_initiator_indices()
- func can_proceed_without_partner()
- func are_coords_near()
- func build_dialogue_action()

### Gameplay/narrative/dialogue/dialogue_trigger_group.gd

- func _init()
- func register_trigger()
- func mark_seen()
- func reset()

### Gameplay/narrative/dialogue/dialogue_trigger_manager.gd

- func setup()
- func register_triggers()
- func get_trigger()
- func get_all_triggers()
- func get_trigger_at()
- func mark_seen()
- func _cleanup_registered_triggers()
- func _load_seen_flags()
- func _save_seen_flags()
- func clear_triggers()

### Gameplay/narrative/dialogue/skit.gd

- (No functions defined)

### Gameplay/narrative/journal/journal_data.gd

- func _init()
- func add_section()
- func add_topic()
- func add_entry()
- func has_entry()
- func replace_entry()
- func get_section()
- func get_topic()
- func get_entry()
- func get_unlocked_topics_in_section()
- func get_unlocked_entries_in_topic()
- func get_all_unlocked_entries()

### Gameplay/narrative/journal/journal_section.gd

- func _init()

### Gameplay/narrative/journal/journal_topic.gd

- func _init()

### Gameplay/narrative/task/completion_condition.gd

- (No functions defined)

### Gameplay/narrative/task/defeat_enemies_task.gd

- func handle_event()

### Gameplay/narrative/task/game_objective_controller.gd

- func setup()
- func check_location_progress()
- func is_task_reached()
- func process_turn_progress()
- func _on_task_completed()
- func reset_task_state()
- func get_target_task()
- func create_memento()
- func restore_from_memento()
- func create_target_texture()

### Gameplay/narrative/task/objective.gd

- func _init()
- func start_objective()
- func handle_event()
- func transplant_task()
- func _transition_to_stage()
- func _connect_stage_signals()
- func _disconnect_stage_signals()
- func _on_task_completed_relay()
- func _on_task_failed_relay()
- func _on_task_updated_relay()
- func _on_stage_completed()
- func _complete_objective()
- func _fail_objective()
- func create_memento()
- func restore_from_memento()

### Gameplay/narrative/task/stage.gd

- func start_stage()
- func _connect_task_signals()
- func _disconnect_task_signals()
- func _on_task_dialogue_requested()
- func handle_event()
- func _on_task_completed()
- func advance()
- func _on_task_failed()
- func _on_task_progress_changed()
- func _are_faction_required_tasks_complete()
- func _are_all_required_tasks_complete()
- func end_stage()
- func create_memento()
- func restore_from_memento()

### Gameplay/narrative/task/task.gd

- func initialize()
- func handle_event()
- func _apply_progress()
- func _apply_duration_progress()
- func _complete_task()
- func force_complete()
- func _fail_task()
- func cancel()
- func get_progress_ratio()
- func create_memento()
- func restore_from_memento()
- func can_be_worked_on_by()
- func _can_work_filters()
- func _coord_matches_requirement()

### Gameplay/narrative/task/task_action_provider.gd

- func append_task_action()
- func _is_location_task()
- func _is_loot_task()
- func _is_unit_task()
- func _add_task_action()

### Gameplay/narrative/task/task_condition_handler.gd

- func setup()
- func check_objective_failed()
- func get_player_units()
- func handle_inventory_check()

### Gameplay/narrative/task/task_controller.gd

- func setup()
- func _connect_task_manager_signals()
- func finish_setup()
- func bootstrap_level()
- func activate_initial_stage()
- func set_level()
- func handle_event()
- func on_unit_defeated()
- func _on_stage_completed()
- func _on_stage_failed()
- func on_task_completed()
- func _grant_mid_stage_reward()
- func _on_objective_updated()
- func _on_objective_completed()
- func _on_objective_failed()
- func on_round_changed()
- func _gather_round_requirements()
- func _collect_faction_data()
- func check_objective_conditions()
- func check_inventory_objectives()
- func _check_defeat_conditions()
- func _grant_end_of_level_rewards()
- func _handle_stage_spawns()
- func _update_turn_blocking()
- func is_narrative_blocking()
- func is_task_reached()
- func is_game_over()
- func reset_task_state()
- func create_memento()
- func restore_from_memento()
- func get_task_by_id()
- func get_task_info()
- func get_task_at_coord()
- func _transform_task_to_info()
- func handle_dialogue_finished()
- func _on_dialogue_finished()
- func _on_dialogue_requested()

### Gameplay/narrative/task/task_definition.gd

- (No functions defined)

### Gameplay/narrative/task/task_dialogue_handler.gd

- func setup()
- func queue_stage_dialogues()
- func queue_task_dialogues()
- func queue_dialogue()
- func process_queue()
- func on_dialogue_finished()
- func is_queue_empty()
- func is_processing()
- func get_queue_contents()
- func _add_to_queue()
- func _resolve_dialogue_path()

### Gameplay/narrative/task/task_manager.gd

- static func from_target()
- static func from_raw()
- static func resolve_target_id()
- func setup()
- func prepare_objective()
- func start_active_objective()
- func set_level_and_objective()
- func register_unit()
- func register_location()
- func _on_loot_added()
- func _on_loot_removed()
- func register_loot()
- func get_active_objective()
- func get_all_locations()
- func get_location_at()
- func get_loot_at()
- func _on_target_interacted()
- func _on_unit_moved()
- func _on_objective_updated()
- func _on_objective_completed()
- func _on_objective_failed()
- func _check_stage_spawns()
- func _spawn_location()
- func _on_game_action()
- func get_task_for_target()
- func get_task_by_id()
- func debug_complete_task()
- func _debug_eliminate_faction()
- func get_active_tasks_for_target()
- func get_active_tasks_for_target_ctx()
- func _on_task_completed_relay()
- func _on_task_failed_relay()
- func _on_task_updated_relay()
- func create_memento()
- func restore_from_memento()

### Gameplay/narrative/task/task_processor.gd

- static func is_event_type_supported()
- static func is_event_processed()
- static func validate_interaction_data()
- static func matches_any_filter()
- static func filter_matches()
- static func process_move()
- static func process_ability_used()
- static func process_dialogue_started()
- static func process_unit_defeated()
- static func process_round_changed()
- static func duration_condition_holds()
- static func calculate_event_progress()
- static func get_best_attribute_index()
- static func to_vector2i()

### Gameplay/narrative/task/task_reward.gd

- (No functions defined)

### Gameplay/narrative/task/task_stage_spawner.gd

- func _init()
- func handle_stage_spawns()
- func _spawn_stage_units()
- func _spawn_stage_loot()
- func _spawn_stage_locations()
- func _spawn_stage_dialogue_triggers()

### Gameplay/narrative/task/task_validator.gd

- func validate_item_target()
- func validate_location_target()
- func validate_unit_target()

### Gameplay/roster/enemy_roster.gd

- (No functions defined)

### Gameplay/roster/enemy_roster_definition.gd

- (No functions defined)

### Gameplay/roster/inventory_service.gd

- static func handle_item_transfer()
- static func handle_item_swap()
- static func _can_accept_item_swap()
- static func auto_equip_roster()
- static func save_roster_state()
- static func _get_highest_stat()
- static func _get_unit_item_count()

### Gameplay/roster/neutral_roster.gd

- (No functions defined)

### Gameplay/roster/player_roster.gd

- func update_roster()
- func _build_active_entries()
- func _merge_inactive_entries()
- func _get_previous_entries()
- func _sync_units_from_entries()
- func add_to_stash()
- func clear_stash()
- func get_remaining_location_titles()
- func set_remaining_location_titles()
- func create_memento()
- func restore_from_memento()

### Gameplay/roster/roster_loader.gd

- func load_player_roster()
- func load_enemy_roster()
- func load_neutral_roster()
- func _load_saved_player_roster()
- func _load_player_roster_resource()
- func _load_unit_roster()
- func _populate_roster_from_resource()
- func build_core_player_roster()
- func _build_core_player_roster()
- func _instantiate_core_units()
- func _add_starting_item_set()

### Gameplay/roster/roster_persistence.gd

- static func unit_to_entry()
- static func entry_to_scene()
- static func entry_to_unit()
- static func _set_owner_recursive()
- static func scene_to_entry()

### Gameplay/roster/unit_roster.gd

- func get_unit_scene()
- func get_random_unit_scene()
- func get_units()

### Gameplay/roster/unit_roster_definition.gd

- (No functions defined)

### Gameplay/skills/heal_skill.gd

- func activate()

### Gameplay/skills/skill.gd

- func activate()
- func on_equip()
- func on_unequip()
- func get_tooltip_text()
- func apply_willpower_change()

### Gameplay/skills/weather_change_skill.gd

- func activate()
- func get_tooltip_text()

### Gameplay/targets/action_utility.gd

- static func build_move_data()
- static func set_reachable_info()
- static func _is_coord_keyed_lookup()
- static func _clone_move_info()

### Gameplay/targets/components/action_points_component.gd

- func _init()
- func set_owner_unit()
- func refresh_for_new_round()
- func has_move_available()
- func has_action_available()
- func has_reaction_available()
- func get_reactions_available()
- func get_max_reactions()
- func set_max_reactions()
- func consume_move()
- func consume_action()
- func consume_reaction()
- func adjust_reactions_available()
- func adjust_remaining_movement()
- func block_movement_this_turn()
- func block_action_this_turn()
- func get_remaining_movement_points()
- func get_movement_points()
- func set_movement_points()
- func get_willpower()
- func set_willpower()
- func get_max_willpower()
- func set_max_willpower()

### Gameplay/targets/components/inventory_component.gd

- func setup()
- func _find_or_create_inventory()
- func cleanup()
- func get_inventory()
- func equip_item()
- func unequip_item()
- func add_item_to_inventory()
- func remove_item_from_inventory()
- func get_equipped_items()
- func has_item_by_id()
- func clear_items()
- func clear()

### Gameplay/targets/components/movement_range_cache.gd

- func setup()
- func set_unit_manager()
- func compute_range()
- func invalidate()
- func cleanup()

### Gameplay/targets/components/target_interaction_handler.gd

- func _init()
- func set_loot_manager()
- func set_task_manager()
- func set_location_service()
- func set_unit_manager()
- func interact()
- func loot()
- func _handle_trapped_loot()
- func _collect_items_from_node()
- func _try_loot_item()
- func _cleanup_loot_node()
- func explore()
- func visit_location()
- func convince_unit()
- func fight_unit()
- func _auto_loot_from_node()
- func _try_interaction_detailed()
- func _try_interaction()

### Gameplay/targets/components/threat_cache.gd

- func setup()
- func set_unit_manager()
- func get_cached_result()
- func update_cache()
- func invalidate()
- func cleanup()

### Gameplay/targets/components/unit_combat_behavior.gd

- func _init()
- func set_combat_system()
- func attack()
- func aid_ally()
- func _is_near_to_target()

### Gameplay/targets/components/unit_death_handler.gd

- func _init()
- func set_unit_manager()
- func set_loot_manager()
- func set_animation_service()
- func die()
- func is_dying()
- func _drop_loot()
- func _should_drop_standard_loot()
- func _get_current_difficulty()
- func _drop_quest_items()
- func _route_remaining_items()
- func _drop_inventory()
- func _finalize_death()

### Gameplay/targets/components/unit_loyalty_component.gd

- func _init()
- func is_faction_leader()
- func set_faction_leader()
- func reset_neutral_loyalty()
- func set_neutral_loyalty()
- func _can_change_loyalty()
- func _normalize_faction()
- func _rally_allies()
- func _can_rally_ally()
- func apply_persuasion()
- func handle_attack_from()

### Gameplay/targets/components/unit_movement_behavior.gd

- func _init()
- func setup()
- func has_move_available()
- func consume_move()
- func adjust_remaining_movement()
- func block_movement_this_turn()
- func get_remaining_movement_points()
- func get_max_movement_points()
- func compute_movement_range()
- func get_path_to_coord()
- func get_path_to_near()
- func get_blocked_hexes()
- func get_threatened_hexes()
- func _can_unit_threaten()
- func _add_unit_threats()
- func process_path_for_opportunity_attacks()
- func _resolve_aoo_at_pos()
- func _can_trigger_aoo()
- func _get_opportunity_attack_context()
- func _select_best_attack_attribute()
- func set_free_roam_mode()
- func is_free_roam_mode()
- func refresh_for_new_round()
- func get_start_of_turn_grid_coord()
- func set_start_of_turn_grid_coord()
- func set_tentative_move()
- func clear_tentative_move()
- func get_tentative_grid_coord()
- func has_tentative_move()
- func get_tentative_path()
- func get_tentative_cost()
- func move_along_path()
- func on_enter_terrain()
- func get_pass_through_blockers()
- func get_stop_blockers()

### Gameplay/targets/components/unit_query_service.gd

- func _init()
- func has_nearby_units()
- func get_units_in_range()
- func get_near_units()
- func get_units_in_range_by_faction()
- func get_units_in_range_without_full_willpower()
- func list_locations_in_range()
- func invalidate_cache()
- func get_hostile_units()
- func get_friendly_units()
- func get_neutral_units()
- func get_all_units_categorized()
- func get_near_units_categorized()
- func get_persuadable_neutrals()
- func get_closest_unit()
- func get_unit_at()
- func get_loot_at()
- func get_location_at()
- func is_occupied()
- func _collect_targets_in_range()
- func _get_relationship_units()
- func _get_axis()
- func _get_or_build()
- func get_total_attribute()
- func get_attribute_bonus()
- func _get_weather_manager()

### Gameplay/targets/components/unit_status_component.gd

- func _init()
- func apply_status_effect()
- func has_status_effect()
- func clear_status_effect()
- func get_status_effects()

### Gameplay/targets/discovery/dialogue_discovery.gd

- static func get_potential_partners()
- static func get_potential_initiators()
- static func has_active_dialogue()

### Gameplay/targets/discovery/target_discovery_service.gd

- static func discover_nearby()
- static func discover_reachable()
- static func is_convincable()
- static func split_units_for_combat()
- static func split_targets()
- static func get_potential_loot_items()
- static func get_categorized_loot()
- static func get_immediate_loot()
- static func can_be_looted_by()
- static func get_categorized_locations()
- static func get_active_tasks()
- static func get_immediate_tasks()
- static func get_categorized_location_tasks()
- static func _get_units_nearby()
- static func _get_units_categorized_nearby()
- static func _get_units_reachable()
- static func _get_units_categorized_reachable()
- static func _get_loot_nearby()
- static func _get_loot_reachable()
- static func _get_tasks_nearby()
- static func _get_tasks_reachable()
- static func _get_locations_nearby()
- static func _get_locations_reachable()

### Gameplay/targets/inventory_item.gd

- func _init()
- func get_item_name()
- func get_modifiers()
- func is_quest_item()
- func _generate_uuid()
- func generate_uuid()
- func to_dict()
- static func from_dict()
- func duplicate_instance()

### Gameplay/targets/location.gd

- func _ready()
- func _ensure_sprite_setup()
- func set_task_manager()
- func _on_task_event()
- func _on_task_event_unit()
- func _on_objective_updated()
- func update_visuals()
- func set_grid_coord()
- func mark_explored()

### Gameplay/targets/location_action_provider.gd

- func append_location_action()
- func _add_task_summary_action()

### Gameplay/targets/location_service.gd

- func setup()
- func get_all_locations_data()
- func get_location_data_at_coordinate()
- func _transform_location_to_data()
- func visit_location()
- func explore_location()
- func create_memento()
- func restore_from_memento()

### Gameplay/targets/loot.gd

- func _ready()
- func _ensure_sprite_setup()
- func disarm_trap()
- func can_be_looted_by()
- func add_items()
- func is_empty()
- func get_hover_info()
- func take_all_items()
- func set_task_manager()
- func _on_task_event()
- func _on_task_event_unit()
- func _on_task_event_objective()
- func update_visuals()

### Gameplay/targets/loot_action_provider.gd

- func append_loot_action()
- func _add_categorized_loot_actions()
- func _add_loot_action()

### Gameplay/targets/loot_manager.gd

- func reset()
- func add_to_routing_pool()
- func collect_routing_pool()
- func add_loot()
- func remove_loot()
- func get_loot_at()
- func has_loot_at()
- func get_loot_count()
- func get_loot()
- func get_coord()
- func get_all_loot()
- func spawn_loot()
- func _spawn_new_loot()
- func create_memento()
- func restore_from_memento()
- func collect_all_loot_items()

### Gameplay/targets/move_and_interact_provider.gd

- static func append_move_and_interact_actions()
- static func _append_move_and_attack_actions()
- static func _process_move_and_unit_interaction()
- static func _append_move_and_loot_actions()
- static func _append_move_and_task_actions()
- static func _get_near_coords()
- static func _resolve_move_cost()
- static func _has_unblocked_path()
- static func _resolve_move_origin()
- static func _build_move_and_interact_action()
- static func _select_best_attack_attribute()

### Gameplay/targets/target.gd

- func _ready()
- func interact()
- func get_attribute()
- func get_attribute_by_name()
- func get_attribute_by_index()
- func get_grid_location()
- func snap_to_grid()
- func set_external_grid_coord()
- func clear_external_grid_coord()
- func has_external_grid_coord()
- func distance_to_target()
- func is_pixel_inside()

### Gameplay/targets/target_spawner.gd

- static func spawn_unit()
- static func _set_unit_identity()
- static func _inject_unit_dependencies()
- static func _apply_attributes()
- static func spawn_loot()
- static func spawn_location()
- static func spawn_or_update_location()
- static func spawn_dialogue_trigger()

### Gameplay/targets/unit.gd

- func get_effective_faction()
- func _init()
- func _ready()
- func _ensure_sprite_setup()
- func update_visuals()
- func _on_action_points_willpower_changed()
- func _sync_max_willpower()
- func _exit_tree()
- func set_unit_manager()
- func apply_attribute_modifier()
- func remove_attribute_modifier()
- func get_attribute_modifiers()
- func get_base_attribute_from_target()
- func get_attribute()
- func get_attribute_by_name()
- func get_attribute_by_index()
- func get_unit_manager()
- func set_animation_service()
- func set_task_manager()
- func get_task_manager()
- func set_location_service()
- func get_location_service()
- func set_loot_manager()
- func get_loot_manager()
- func set_combat_system()
- func get_combat_system()
- func get_units_in_range_without_full_morale()
- func is_at_full_morale()
- func adjust_remaining_movement()
- func on_enter_terrain()
- func add_skill()
- func remove_skill()
- func get_combat_profile()
- func is_at_full_willpower()
- func refresh_for_new_round()
- func set_free_roam_mode()
- func is_in_free_roam_mode()
- func consume_action()
- func block_movement_this_turn()
- func block_action_this_turn()
- func is_faction_leader()
- func set_faction_leader()
- func is_player_leader()
- func set_player_leader()
- func is_friendly()
- func is_hostile()
- func _die()
- func apply_consumable()
- func prepare_for_save()
- func get_hover_info()
- func finalize_setup()
- func get_aid_buff()
- func add_aid_buff()
- func consume_aid_buffs()

### Gameplay/targets/unit_action_manager.gd

- static func set_dialogue_service()
- static func get_dialogue_service()
- static func is_unit_stuck()
- static func get_available_actions()
- static func get_available_actions_with_weather()
- static func _collect_actions()
- static func _get_grid_axis()
- static func _append_combat_actions()
- static func _append_location_action()
- static func _append_loot_action()
- static func _append_task_action()
- static func _append_skill_actions()
- static func _append_wait_action()

### Gameplay/targets/unit_component_factory.gd

- static func create_components()
- static func _init_inventory()
- static func _init_movement_cache()
- static func _init_threat_cache()
- static func _init_behaviors()
- static func _inject_dependencies()

### Gameplay/targets/unit_controller.gd

- func configure_dependencies()
- func setup()
- func get_unit_manager()
- func add_unit()
- func set_coord()
- func set_player_controlled()

### Gameplay/targets/unit_inventory.gd

- func add_item_to_inventory()
- func remove_item_from_inventory()
- func equip_item()
- func _ensure_item_tracked()
- func _check_equip_capacity()
- func _find_by_uuid()
- func _equip_existing_item()
- func _perform_equip()
- func unequip_item()
- func clear_items()
- func clear()
- func get_items()
- func get_non_quest_items()
- func get_equipped_items()
- func get_equipped_non_quest_items()
- func has_item_by_id()

### Gameplay/targets/unit_manager.gd

- func reset()
- func begin_batch_placement()
- func end_batch_placement()
- func add_unit()
- func get_nearest_empty_coord()
- func mark_retreat()
- func remove_unit()
- func get_all_units()
- func get_units()
- func get_unit_count()
- func get_player_units()
- func get_enemy_units()
- func get_neutral_units()
- func get_allied_units()
- func get_faction_leader()
- func set_faction_leader()
- func set_roster_for_faction()
- func get_roster_for_faction()
- func reset_all_neutral_loyalties()
- func get_selected_unit()
- func get_selected_sprite()
- func get_units_by_faction()
- func get_fleet_willpower()
- func get_selected_index()
- func get_selected_coord()
- func get_coord_by_unit()
- func get_unit()
- func get_coord()
- func set_coord()
- func is_occupied()
- func get_unit_at_coord()
- func is_player_controlled()
- func set_player_controlled()
- func force_select_index()
- func select_index()
- func cycle_selection()
- func get_unit_index()
- func apply_faction_stat_boost()
- func _apply_unit_stat_boost()
- func get_faction_max_willpower()
- func index_of_unit_at()
- func can_player_act()
- func create_memento()
- func restore_from_memento()

### Gameplay/targets/unit_presenter.gd

- static func get_hover_info()

### Gameplay/targets/unit_serializer.gd

- static func create_memento()
- static func restore_from_memento()

### Gameplay/terrain/ash.gd

- func _init()

### Gameplay/terrain/bridge_causeway.gd

- func _init()

### Gameplay/terrain/cave_entrance.gd

- func _init()

### Gameplay/terrain/courtyard.gd

- func _init()

### Gameplay/terrain/crossroads.gd

- func _init()

### Gameplay/terrain/crystal.gd

- func _init()

### Gameplay/terrain/desert_oasis.gd

- func _init()

### Gameplay/terrain/enchanted_forest.gd

- func _init()

### Gameplay/terrain/floating_island.gd

- func _init()

### Gameplay/terrain/fort.gd

- func _init()

### Gameplay/terrain/grass.gd

- func _init()

### Gameplay/terrain/graveyard.gd

- func _init()

### Gameplay/terrain/hill_high_ground.gd

- func _init()

### Gameplay/terrain/ice.gd

- func _init()

### Gameplay/terrain/jungle.gd

- func _init()

### Gameplay/terrain/keep.gd

- func _init()

### Gameplay/terrain/lava_flow.gd

- func _init()

### Gameplay/terrain/leaf_platform.gd

- func _init()

### Gameplay/terrain/monastery.gd

- func _init()

### Gameplay/terrain/mountain_peak.gd

- func _init()

### Gameplay/terrain/mud.gd

- func _init()

### Gameplay/terrain/oasis.gd

- func _init()

### Gameplay/terrain/path.gd

- func _init()

### Gameplay/terrain/plaza.gd

- func _init()

### Gameplay/terrain/quagmire.gd

- func _init()

### Gameplay/terrain/river.gd

- func _init()

### Gameplay/terrain/rock_dune.gd

- func _init()

### Gameplay/terrain/ruins.gd

- func _init()

### Gameplay/terrain/sand.gd

- func _init()

### Gameplay/terrain/stone.gd

- func _init()

### Gameplay/terrain/swamp.gd

- func _init()

### Gameplay/terrain/terrain_tile.gd

- func get_movement_adjustment()
- func get_modified_movement_cost()
- func apply_to_unit()
- func get_hover_info()
- func _init()

### Gameplay/terrain/tree_village.gd

- func _init()

### Gameplay/terrain/underground.gd

- func _init()

### Gameplay/terrain/vines.gd

- func _init()

### Gameplay/terrain/wall.gd

- func _init()

### Gameplay/terrain/waterfall.gd

- func _init()

### Gameplay/turn/action_availability_service.gd

- func is_unit_stuck()
- func _can_move_somewhere()
- func _can_act_somewhere()

### Gameplay/turn/action_label_formatter.gd

- static func format()
- static func get_label()
- static func get_hint()

### Gameplay/turn/ai/ai_action.gd

- func _init()

### Gameplay/turn/ai/ai_action_evaluator.gd

- func evaluate()
- func _discover_nearby()

### Gameplay/turn/ai/ai_command_builder.gd

- func build()
- func _convince()
- func _attack()
- static func _select_best_attack_attribute()
- func _explore()
- func _visit()
- func _trapped()
- func _loot()
- func _aid_ally()

### Gameplay/turn/ai/ai_context.gd

- func get_discovery_results()
- func get_near_units_categorized()

### Gameplay/turn/ai/aid_ally_evaluator.gd

- func evaluate()
- func _get_best_aid_attribute()

### Gameplay/turn/ai/attack_evaluator.gd

- func evaluate()
- func _is_neutral()
- func _fallback_enemy_action()

### Gameplay/turn/ai/center_fallback_evaluator.gd

- func evaluate()

### Gameplay/turn/ai/convince_evaluator.gd

- func evaluate()

### Gameplay/turn/ai/loot_evaluator.gd

- func evaluate()
- func _get_threatened_hexes()

### Gameplay/turn/ai/talk_evaluator.gd

- func evaluate()
- func _resolve_dialogue_service()
- func _find_talk_actions()
- func _find_move_to_talk_actions()
- func _find_path_to_near()

### Gameplay/turn/ai/task_evaluator.gd

- func evaluate()
- func _add_move_to_task_actions()
- func _is_opposed_task()
- func _is_invalid_coord()
- func _get_threatened_hexes()
- func _fallback_task_action()

### Gameplay/turn/ai_controller.gd

- func _ready()
- func _exit_tree()
- func setup()
- func _calculate_initial_max_willpower()
- func set_turn_controller()
- func set_command_context()
- func execute_turn()
- func _build_context()
- func _rebuild_evaluators()
- func _gather_actions()
- func _execute_action()
- func _execute_movement()
- func _truncate_path_to_reachable()
- func _execute_interaction()
- func _execute_command()
- func _promote_move_action()
- func _promote_task_move()
- func _promote_loot_move()
- func _promote_talk_move()
- func _on_weather_effect_applied()

### Gameplay/turn/auto_battle_diagnostics.gd

- static func report_unsupported_actions()
- static func get_unsupported_history()

### Gameplay/turn/auto_battle_service.gd

- func _init()
- func setup()
- func reset()
- func is_enabled()
- func is_in_progress()
- func set_enabled()
- func force_disable()
- func maybe_run_turn()
- func _can_run_auto_turn()
- func _resolve_current_player_unit()
- func _is_valid_auto_unit()
- func _process_auto_turn()
- func _handle_ai_result()
- func _execute_ai_turn_logic()
- func _handle_unit_invalidated_after_action()
- func _handle_ai_success()
- func _handle_ai_failure()
- func _find_player_unit_candidate()
- func _get_fallback_candidate()
- func _activate_candidate_unit()
- func _try_select_alternate_unit()
- func _reset_attempts()
- func _record_attempt()
- func _attempts_exhausted()
- func _should_preserve_turn()
- func create_memento()
- func restore_from_memento()

### Gameplay/turn/checkpoint_manager.gd

- func setup()
- func on_checkpoint_requested()
- func on_undo_requested()
- func on_redo_requested()
- func create_checkpoint()
- func undo()
- func redo()
- func has_history()
- func has_redo()
- func _capture_state()
- func _restore_state()
- func _validate_unique_items()

### Gameplay/turn/combat_action_calculator.gd

- func append_combat_actions()
- func _find_near_combat_targets()
- func _find_reachable_combat_targets()
- func _find_reachable_targets_with_move()
- func _should_skip_target()
- func _add_attack_action()
- func _add_convince_action()
- func _add_aid_action()
- func _find_best_near_coord()
- func has_reachable_near()

### Gameplay/turn/combat_system.gd

- func execute_combat()
- func execute_attack_of_opportunity()
- func _execute_attack()
- func _apply_damage_and_loyalty()
- func _consume_reactions()
- func _emit_attack_events()
- func get_combat_forecast()
- func get_combat_pair_forecast()
- func get_attack_of_opportunity_forecast()
- func _validate_combatants()
- func _get_stat()
- func _compute_defense()
- func _simulate_attack()

### Gameplay/turn/turn_controller.gd

- func set_player_turn_locked()
- func is_player_turn_locked()
- func _init()
- func reset()
- func setup()
- func configure_dependencies()
- func start_next_turn()
- func complete_turn()
- func _start_unit_turn()
- func _start_new_round()
- func classify_unit_side()
- func rebuild_turn_roster()
- func _preserve_queue_state()
- func _consume_current_turn_entry()
- func _process_ai_turn()
- func on_turn_changed()
- func can_act_on_index()
- func lock_active_player_unit()
- func complete_player_activation()
- func _sync_unit_manager_selection()
- func _is_unit_active()
- func _refresh_all_units()
- func set_enabled()
- func is_enabled()
- func set_player_auto_battle_enabled()
- func _on_auto_battle_changed()
- func is_player_auto_battle_enabled()
- func is_player_auto_control_locked()
- func force_disable_auto_battle()
- func is_queue_empty()
- func get_turn_queue()
- func get_turn_system()
- func get_current_unit_index()
- func get_current_side()
- func get_round()
- func move_index_to_front()
- func set_current_unit_index()
- func create_memento()
- func restore_from_memento()

### Gameplay/turn/turn_queue_builder.gd

- func _init()
- func build_full_queue()
- func get_active_units_by_side()
- func determine_start_side()
- func build_from_active_units()
- func get_side_rotation()
- func find_next_active_side()
- func classify_unit_side()

### Gameplay/turn/turn_system.gd

- func reset()
- func get_turn_queue()
- func set_turn_queue()
- func is_queue_empty()
- func get_queue_size()
- func peek_next_index()
- func pop_next_index()
- func move_index_to_front()
- func get_current_unit_index()
- func set_current_unit_index()
- func get_current_side()
- func set_current_side()
- func get_current_round()
- func get_round()
- func set_round()
- func increment_round()
- func get_next_starting_side()
- func set_next_starting_side()
- func get_turns_taken_this_round()
- func increment_turns_taken_this_round()
- func reset_turns_taken_this_round()
- func get_turns_taken_map()
- func set_turns_taken_map()
- func has_index_in_queue()
- func create_memento()
- func restore_from_memento()

### Gameplay/turn/unit_action.gd

- func _init()
- static func create()
- func clone()

## Menus

### Menus/controls_menu.gd

- func _ready()
- func _refresh_layouts()
- func reset_and_apply_defaults()
- func _on_back_pressed()
- func _on_reset_pressed()
- func _unhandled_input()
- func _get_event_label()

### Menus/credits.gd

- func _ready()
- func set_return_delay()
- func _start_timer()
- func _on_return_timeout()

### Menus/inventory_management_menu.gd

- func _ready()
- func _refresh_ui()
- func _update_help_text()
- func _on_action_requested()
- func _on_minus_pressed()
- func _on_equip_pressed()
- func _on_hand_pressed()
- func handle_item_drop()
- func handle_swap()
- func _on_auto_equip_pressed()
- func _on_debug_reset_pressed()
- func _on_viewport_size_changed()
- func _update_layout()
- func _on_display_settings_changed()
- func _input()
- func _on_back_pressed()
- func _update_move_mode_visuals()
- func _enter_move_mode()
- func _exit_move_mode()
- func setup()
- func add_item()
- func _can_drop_data()
- func _drop_data()
- func _on_pause_pressed()

### Menus/level_select.gd

- func _ready()
- func _populate_levels()
- func _on_back_pressed()
- func _on_level_pressed()
- func _on_debug_reset_pressed()
- func _on_pause_pressed()
- func _update_layout()
- func _on_display_settings_changed()

### Menus/level_selection.gd

- (No functions defined)

### Menus/pause_handler.gd

- func _unhandled_input()
- func _handle_pause_input()
- func show_pause_menu()
- func _hide_pause_menu()
- func _on_pause_resume()
- func _on_pause_controls()
- func _on_pause_inventory()
- func _on_pause_journal()
- func _on_pause_settings()
- func _on_controls_back()
- func _on_inventory_back()
- func _on_journal_back()
- func _on_settings_back()
- func _on_pause_quit()
- func is_paused()
- func set_journal_manager()
- func set_unit_manager()

### Menus/pause_menu.gd

- func _ready()
- func _on_display_settings_changed()
- func _update_layout()
- func _unhandled_input()
- func show_menu()
- func hide_menu()
- func _on_resume_pressed()
- func _on_controls_pressed()
- func _on_inventory_pressed()
- func _on_journal_pressed()
- func _on_settings_pressed()
- func _on_quit_pressed()

### Menus/recovery_menu.gd

- func _ready()
- func _populate_saves()
- func _is_newer()
- func _on_save_selected()
- func _on_back_pressed()

### Menus/settings_menu.gd

- func _ready()
- func _on_locale_changed()
- func setup()
- func _translate_labels()
- func _setup_audio_settings()
- func _create_audio_row()
- func _setup_display_settings()
- func _setup_animation_settings()
- func _setup_batch_animations_row()
- func _setup_language_row()
- func _on_language_selected()
- func _unhandled_input()
- func _on_back_pressed()
- func _on_volume_changed()
- func _on_mute_toggled()
- func _on_orientation_selected()
- func _on_resolution_selected()
- func _on_animation_speed_selected()
- func _initialize_dialogue_settings()
- func _on_auto_advance_toggled()
- func _on_auto_advance_speed_changed()
- func _on_text_speed_changed()
- func _update_auto_advance_speed_label()
- func _update_text_speed_label()
- func _setup_difficulty_row()
- func _on_difficulty_selected()
- func _save_dialogue_value()

### Menus/title_screen.gd

- func _ready()
- func _setup_additional_buttons()
- func _on_continue_pressed()
- func _on_recovery_pressed()
- func set_quit_callback()
- func _on_start_pressed()
- func _on_quit_pressed()
- func _on_level_select()
- func _unhandled_input()
- func _is_relevant_press()
- func _is_quit_event()
- func _is_start_event()
- func _contains()
- func _mark_input_handled()
- func _start_keys()
- func _quit_keys()
- func _start_buttons()
- func _quit_buttons()
- func _allow_any_non_quit_key()
- func _allow_any_joy_button()
- func _start_via_shortcut()
- func _quit_via_shortcut()
- func _scene_transition()

## Resources

### Resources/achievements/achievement.gd

- (No functions defined)

### Resources/animation_styles/animation_style.gd

- (No functions defined)

### Resources/animation_styles/animation_style_set.gd

- func get_style()

### Resources/file_paths_loader.gd

- static func load_paths()
- func _load_internal()
- func get_path()
- func get_category()
- func get_warnings()
- func get_dynamic_paths()
- func validate_paths()
- func _validate_category_recursive()
- func get_errors()
- func print_summary()
- func _count_paths()
- static func get_scene()
- static func get_autoload()

### Resources/items/item_template.gd

- (No functions defined)

### Resources/Localization/localization_strings.gd

- static func get_command_name()
- static func get_command_description()
- static func get_text()
- static func has_key()
- static func get_supported_languages()

### Resources/weather/WeatherAttribute.gd

- (No functions defined)

## Root

### check_constants.gd

- func _init()

### debug_load.gd

- func _init()

### verify_roster_reset.gd

- func _init()

## level

### level/combat_stats.gd

- func _init()
- func get_attribute()
- func get_attribute_by_name()
- func set_attribute()
- func set_attribute_by_name()

### level/journal_entry.gd

- func _init()

### level/level.gd

- func _init()
- func _ensure_default_terrain_data()
- func _regenerate_location_entries_from_coords()

### level/level_auto_fix_options.gd

- (No functions defined)

### level/level_auto_fix_service.gd

- func apply()
- func _build_context()
- func _validate_coord_in_context()
- func _find_replacement_in_context()
- func _get_reason_label()
- func _repair_locations()
- func _repair_player_starts()
- func _repair_neutral_starts()
- func _repair_tasks()
- func _write_report_file()

### level/level_build_context.gd

- func _init()

### level/level_builder.gd

- func _init()
- func build_environment()
- func spawn_global_content()
- func _apply_level_settings()
- func _is_location_coord_passable()

### level/level_catalog.gd

- func get_default_level()
- func get_levels()
- func get_level_by_id()
- func find_level_by_path()

### level/level_content_spawner.gd

- func _init()
- func spawn_global_content()
- func _spawn_player_units()
- func _handle_empty_player_spawns()
- func _try_spawn_player_entry()
- func _spawn_scripted_player_unit()
- func _spawn_roster_player_unit()
- func _spawn_roster_units_at_coords()
- func _spawn_enemy_units()
- func _spawn_neutral_units()
- func _spawn_unit()
- func _verify_unit_components()
- func _init_unit_faction()
- func _apply_unit_dependencies()
- func _assign_fallback_player_leader()
- func _spawn_level_dialogue_triggers()
- func _apply_trigger_group()
- func _is_location_coord_passable()
- func _is_hometown_context()
- func _is_hometown_level()
- func _get_primary_player_identity()
- func _should_skip_neutral_spawn()
- func _spawn_locations()
- func _spawn_loot()
- func _spawn_hometown_player_leader()
- func _find_hometown_leader_entry()
- func _scene_matches_leader()
- func _ensure_leader_scene_recorded()
- func _ensure_leader_scene_recorded_orig()

### level/level_dialogue_entry.gd

- func get_flag_id()

### level/level_dialogue_journal_entry.gd

- func has_journal()
- func has_dialogue()

### level/level_flow_controller.gd

- func _init()
- func start_level()
- func start_first_level()
- func mark_level_completed()
- func get_available_levels()
- func is_level_unlocked()
- func get_level_info()
- func get_current_level_path()
- func get_current_level_id()
- func handle_level_complete()
- func handle_quit_to_title()
- func handle_quit_to_level_select()
- func _change_scene()
- func _set_next_level_by_path()
- func _load_resource()
- func _has_unlocked_incomplete_levels()
- func _on_scene_changed()
- func _configure_gameplay_scene()
- func _connect_scene_signal()

### level/level_initialization_orchestrator.gd

- static func run_initialization_pipeline()

### level/level_loader.gd

- static func load_level_data()
- static func _validate_data()

### level/level_location_entry.gd

- (No functions defined)

### level/level_log.gd

- static func set_debug()
- static func debug()
- static func info()
- static func warn()
- static func error()

### level/level_loot_entry.gd

- func get_items()
- func get_coord()
- func get_stats()

### level/level_manager_gameplay.gd

- func _init()
- func set_save_manager()
- func set_dialogue_service()
- func set_auto_fix_enabled()
- func set_level_resource()
- func prepare_level_data()
- func clear_world()
- func build_environment()
- func spawn_global_content()
- func finalize_setup()
- func apply_level_if_available()
- func _create_build_context()
- func _handle_build_result()
- func _connect_morale_panel_signals()
- func set_level_and_rebuild()
- func on_task_reached()
- func update_task_progress()
- func on_task_failed()
- func _get_level_id_for_level()
- func _apply_row_resources()
- func _is_hometown_level()
- func _queue_hometown_progression_dialogues()
- func on_unit_moved()
- func _apply_hometown_exploration_rules()
- func _get_primary_player_unit()

### level/level_progress_store.gd

- func _init()
- func get_completed_levels()
- func is_level_completed()
- func mark_level_completed()
- func reset()

### level/level_roster_service.gd

- func _init()
- func setup()
- func refresh_player_roster()
- func determine_leader_name()
- func _resolve_leader_name_from_roster()
- func _unit_name_from_scene()

### level/level_row_loader.gd

- func _init()
- func refresh_for_level()
- func set_auto_fix_options()
- func _load_rows_for_level()
- func apply_rows_to_level()
- func _rows_for_level()
- func _apply_combat_rows()
- func _validate_and_autofix()
- func _apply_start_rows()
- func _apply_dialogue_rows()
- func _build_journal_entries()
- func _load_rows_from_path()
- func _list_resource_files()
- func _sync_roster_definitions()
- func _distribute_rows_to_stages()
- func _inject_collection_to_target()
- func _items_match()

### level/level_row_validator.gd

- func validate()
- func _validate_journal_entry_rows()
- func _validate_roster_rows()
- func _validate_loot_rows()
- func _validate_location_rows()
- func _validate_start_rows()
- func _get_faction_key()
- func _validate_start_slot()
- func _validate_start_coordinate()
- func _validate_start_faction_requirements()
- func _is_in_bounds()
- func _coord_key()

### level/level_state_controller.gd

- func setup()
- func update_grid_dimensions()
- func on_task_reached()
- func get_task_reached_state()
- func set_task_reached_state()
- func update_task_progress()
- func handle_player_defeat()
- func handle_enemy_retreat()
- func handle_neutral_retreat()
- func update_safe_zone_ui()
- func _resolve_scene_tree()

### level/level_task_entry.gd

- func get_location_scene()
- func get_coord()
- func get_stats()

### level/level_terrain_data.gd

- (No functions defined)

### level/level_unit_spawn_entry.gd

- func get_unit_scene()
- func get_coord()
- func get_inventory()
- func get_ai_profile()
- func get_stats()

### level/validation/connectivity_validator.gd

- static func validate()
- static func _collect_pois()
- static func _perform_reachability_scan()
- static func _report_connectivity_errors()

### level/validation/dialogue_validator.gd

- static func validate_rows()
- static func validate_journal_links()
- static func _add_explicit_links()

### level/validation/level_data_validator.gd

- static func validate_data()
- static func filter_coords()

### level/validation/repair/dialogue_repairer.gd

- func repair()
- func _repair_dialogue_metadata()

### level/validation/repair/location_repairer.gd

- func repair()
- func _repair_location_metadata()

### level/validation/repair/task_repairer.gd

- func repair()
- func _repair_task_metadata()

### level/validation/repair/unit_spawn_repairer.gd

- func repair_player_starts()
- func repair_neutral_starts()
- func _repair_unit_spawn_metadata()

### level/validation/spawn_utils.gd

- static func parse_entry()
- static func to_spawn_entry()

### level/validation/task_row_validator.gd

- static func validate()
- static func _collect_global_context()
- static func _collect_stage_context()
- static func _validate_stage_tasks()
- static func _validate_single_task()
- static func _validate_task_target()
- static func _coord_key()

## scripts

### scripts/sprite_sheet_analyzer.gd

- func _init()
- func scan_for_images()
- func analyze_image()
- func suggest_grid()
- func find_bounding_boxes()
- func flood_fill_bounds()
