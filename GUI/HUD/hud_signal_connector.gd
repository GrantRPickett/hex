class_name HUDSignalConnector
extends Object

var _hud_controller # HUDController (type hint removed to avoid circular dependency)
var _components: HUDComponentFactory.Components
var _task_manager: TaskManager
var _turn_controller: TurnController
var _unit_manager: UnitManager
var _hud: Hud

func setup(hud_controller, state: GameState, components: HUDComponentFactory.Components) -> void:
	_hud_controller = hud_controller
	_components = components
	_task_manager = state.task_manager
	_turn_controller = state.turn_controller
	_unit_manager = state.unit_manager
	_hud = state.hud

func connect_all() -> void:
	_connect_task_manager_signals()
	_connect_turn_system_signals()
	_connect_components()
	_connect_system_controls()

func _connect_task_manager_signals() -> void:
	if not is_instance_valid(_task_manager): return
	if not _task_manager.objective_updated.is_connected(_hud_controller._on_objective_updated):
		_task_manager.objective_updated.connect(_hud_controller._on_objective_updated)
	if not _task_manager.objective_completed.is_connected(_hud_controller._on_objective_completed):
		_task_manager.objective_completed.connect(_hud_controller._on_objective_completed)
	if not _task_manager.task_updated.is_connected(_hud_controller._on_task_updated):
		_task_manager.task_updated.connect(_hud_controller._on_task_updated)
	if not _task_manager.task_completed.is_connected(_hud_controller._on_task_completed):
		_task_manager.task_completed.connect(_hud_controller._on_task_completed)
	if not _task_manager.task_failed.is_connected(_hud_controller._on_task_failed):
		_task_manager.task_failed.connect(_hud_controller._on_task_failed)

func _connect_turn_system_signals() -> void:
	if not is_instance_valid(_turn_controller): return
	if not _turn_controller.round_changed.is_connected(_hud_controller._on_round_changed):
		_turn_controller.round_changed.connect(_hud_controller._on_round_changed)
	if not _turn_controller.turn_changed.is_connected(_hud_controller._on_turn_changed):
		_turn_controller.turn_changed.connect(_hud_controller._on_turn_changed)
	if not _turn_controller.turn_queue_updated.is_connected(_hud_controller._on_turn_queue_updated):
		_turn_controller.turn_queue_updated.connect(_hud_controller._on_turn_queue_updated)
	if not _turn_controller.enabled_changed.is_connected(_hud_controller._on_turn_system_enabled_changed):
		_turn_controller.enabled_changed.connect(_hud_controller._on_turn_system_enabled_changed)

func _connect_components() -> void:
	if not _components: return

	if is_instance_valid(_components.round_info):
		_hud_controller.round_updated.connect(_components.round_info.update_round)
		_hud_controller.turn_updated.connect(_components.round_info.update_turn)
		_hud_controller.turn_status_updated.connect(_components.round_info.update_turn_status)
		_hud_controller.turn_system_enabled_updated.connect(_components.round_info.update_enabled)


	if is_instance_valid(_components.locations_list):
		_hud_controller.locations_updated.connect(_components.locations_list.update_locations)

	if is_instance_valid(_components.terrain_details):
		_hud_controller.terrain_details_updated.connect(_components.terrain_details.update_details)

	if is_instance_valid(_components.tasks_list):
		_hud_controller.tasks_updated.connect(_components.tasks_list.update_tasks)
		_components.tasks_list.task_hovered.connect(func(data): _hud_controller.emit_task_details_updated(data))
		_components.tasks_list.task_unhovered.connect(func(): _hud_controller.emit_task_details_updated(null))
		if _components.tasks_list.has_signal("task_completion_requested"):
			_components.tasks_list.task_completion_requested.connect(_hud_controller._on_task_completion_requested)

	if is_instance_valid(_components.unit_details):
		_hud_controller.unit_details_updated.connect(_components.unit_details.update_details)
		_hud_controller.unit_details_visibility_changed.connect(_components.unit_details.set_visible)

	if is_instance_valid(_components.combat_preview):
		_hud_controller.combat_preview_shown.connect(_components.combat_preview.show_preview)
		_hud_controller.combat_preview_hidden.connect(_components.combat_preview.hide_preview)

	if is_instance_valid(_components.location_details):
		_hud_controller.location_details_updated.connect(_components.location_details.update_details)

	if is_instance_valid(_components.task_details):
		_hud_controller.task_details_updated.connect(_components.task_details.update_details)

	if is_instance_valid(_components.loot_details):
		_hud_controller.loot_details_updated.connect(_components.loot_details.update_details)

	if is_instance_valid(_components.actions_panel):
		_hud_controller.actions_updated.connect(_components.actions_panel.update_actions)
		_components.actions_panel.action_selected.connect(_hud.on_action_selected)
		_components.actions_panel.attribute_hovered.connect(_hud_controller._on_attribute_hovered)

func _connect_system_controls() -> void:
	if is_instance_valid(_components.auto_battle_button):
		_components.auto_battle_button.toggled.connect(func(pressed: bool):
			if not _hud_controller._auto_battle_button_sync:
				_hud_controller.emit_auto_battle_toggle_requested(pressed)
		)

	if is_instance_valid(_components.pause_button):
		_components.pause_button.pressed.connect(func():
			_hud.menu_requested.emit("pause", UnitAction.new())
		)

	if is_instance_valid(_components.debug_clear_journal_button):
		_components.debug_clear_journal_button.pressed.connect(func():
			var journal_manager = _hud.get_node_or_null("/root/JournalManager")
			if journal_manager:
				journal_manager.clear_journal()
		)

	if is_instance_valid(_components.debug_player_stats_button):
		_components.debug_player_stats_button.toggled.connect(func(pressed: bool):
			if _unit_manager:
				var amount = GameConstants.Difficulty.DEBUG_STAT_BOOST if pressed else -GameConstants.Difficulty.DEBUG_STAT_BOOST
				_unit_manager.apply_faction_stat_boost(Unit.Faction.PLAYER, amount)
		)

	if is_instance_valid(_components.debug_enemy_stats_button):
		_components.debug_enemy_stats_button.toggled.connect(func(pressed: bool):
			if _unit_manager:
				var amount = GameConstants.Difficulty.DEBUG_STAT_BOOST if pressed else -GameConstants.Difficulty.DEBUG_STAT_BOOST
				_unit_manager.apply_faction_stat_boost(Unit.Faction.ENEMY, amount)
		)

	if is_instance_valid(_components.debug_neutral_stats_button):
		_components.debug_neutral_stats_button.toggled.connect(func(pressed: bool):
			if _unit_manager:
				var amount = GameConstants.Difficulty.DEBUG_STAT_BOOST if pressed else -GameConstants.Difficulty.DEBUG_STAT_BOOST
				_unit_manager.apply_faction_stat_boost(Unit.Faction.NEUTRAL, amount)
		)

	if is_instance_valid(_hud):
		_hud.menu_requested.connect(_hud_controller._on_menu_requested)
		if not _hud.action_executed.is_connected(_hud_controller._on_hud_action_executed):
			_hud.action_executed.connect(_hud_controller._on_hud_action_executed)

	if is_instance_valid(_unit_manager):
		_unit_manager.selection_changed.connect(_hud_controller._on_unit_manager_selection_changed)
		if not _unit_manager.unit_removed.is_connected(_hud_controller._on_unit_removed):
			_unit_manager.unit_removed.connect(_hud_controller._on_unit_removed)
