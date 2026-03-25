class_name HUDSignalConnector
extends Object

var _hud_controller # HUDController (type hint removed to avoid circular dependency)
var _components: HUDComponentFactory.Components
var _task_manager: TaskManager
var _turn_controller: TurnController
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _hud: Hud

func setup(hud_controller, state: GameState, components: HUDComponentFactory.Components) -> void:
	_hud_controller = hud_controller
	_components = components
	_task_manager = state.task_manager
	_turn_controller = state.turn_controller
	_unit_manager = state.unit_manager
	_loot_manager = state.loot_manager
	_hud = state.hud

func connect_all() -> void:
	_connect_task_manager_signals()
	_connect_turn_system_signals()
	_connect_loot_manager_signals()
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

func _connect_loot_manager_signals() -> void:
	if not is_instance_valid(_loot_manager): return
	# We use the existing task updated signals to trigger HUD refreshes
	# but we use lambdas to ignore the signal arguments (loot, coord) which don't match _on_task_updated(int, int)
	var refresh_callable := func(_a=null, _b=null): _hud_controller._on_task_updated(-1, -1)
	
	if not _loot_manager.loot_added.is_connected(refresh_callable):
		_loot_manager.loot_added.connect(refresh_callable)
	if not _loot_manager.loot_removed.is_connected(refresh_callable):
		_loot_manager.loot_removed.connect(refresh_callable)

func _connect_components() -> void:
	if not _components: return

	_connect_round_info()
	_connect_locations_list()
	_connect_terrain_details()
	_connect_tasks_list()
	_connect_unit_details()
	_connect_combat_preview()
	_connect_location_details()
	_connect_task_details()
	_connect_loot_details()
	_connect_actions_panel()

func _connect_round_info() -> void:
	var comp = _components.round_info
	if not is_instance_valid(comp): return

	if not _hud_controller.round_updated.is_connected(comp.update_round):
		_hud_controller.round_updated.connect(comp.update_round)
	if not _hud_controller.turn_updated.is_connected(comp.update_turn):
		_hud_controller.turn_updated.connect(comp.update_turn)
	if not _hud_controller.turn_status_updated.is_connected(comp.update_turn_status):
		_hud_controller.turn_status_updated.connect(comp.update_turn_status)
	if not _hud_controller.turn_system_enabled_updated.is_connected(comp.update_enabled):
		_hud_controller.turn_system_enabled_updated.connect(comp.update_enabled)

func _connect_locations_list() -> void:
	var comp = _components.locations_list
	if not is_instance_valid(comp): return

	if not _hud_controller.locations_updated.is_connected(comp.update_locations):
		_hud_controller.locations_updated.connect(comp.update_locations)
	if not comp.location_selected.is_connected(_hud_controller._on_location_selected):
		comp.location_selected.connect(_hud_controller._on_location_selected)

func _connect_terrain_details() -> void:
	var comp = _components.terrain_details
	if not is_instance_valid(comp): return

	if not _hud_controller.terrain_details_updated.is_connected(comp.update_details):
		_hud_controller.terrain_details_updated.connect(comp.update_details)

func _connect_tasks_list() -> void:
	var comp = _components.tasks_list
	if not is_instance_valid(comp): return

	if not _hud_controller.tasks_updated.is_connected(comp.update_tasks):
		_hud_controller.tasks_updated.connect(comp.update_tasks)

	var task_hovered_callable: Callable = func(data): _hud_controller.emit_task_details_updated(data)
	if not comp.task_hovered.is_connected(task_hovered_callable):
		comp.task_hovered.connect(task_hovered_callable)

	var task_unhovered_callable: Callable = func(): _hud_controller.emit_task_details_updated(null)
	if not comp.task_unhovered.is_connected(task_unhovered_callable):
		comp.task_unhovered.connect(task_unhovered_callable)

	if not comp.task_selected.is_connected(_hud_controller._on_task_selected):
		comp.task_selected.connect(_hud_controller._on_task_selected)

	if comp.has_signal("task_completion_requested"):
		if not comp.task_completion_requested.is_connected(_hud_controller._on_task_completion_requested):
			comp.task_completion_requested.connect(_hud_controller._on_task_completion_requested)

func _connect_unit_details() -> void:
	var comp = _components.unit_details
	if not is_instance_valid(comp): return

	if not _hud_controller.unit_details_updated.is_connected(comp.update_details):
		_hud_controller.unit_details_updated.connect(comp.update_details)
	if not _hud_controller.unit_details_visibility_changed.is_connected(comp.set_visible):
		_hud_controller.unit_details_visibility_changed.connect(comp.set_visible)

func _connect_combat_preview() -> void:
	var comp = _components.combat_preview
	if not is_instance_valid(comp): return

	if not _hud_controller.combat_preview_shown.is_connected(comp.show_preview):
		_hud_controller.combat_preview_shown.connect(comp.show_preview)
	if not _hud_controller.combat_preview_hidden.is_connected(comp.hide_preview):
		_hud_controller.combat_preview_hidden.connect(comp.hide_preview)

func _connect_location_details() -> void:
	var comp = _components.location_details
	if not is_instance_valid(comp): return

	if not _hud_controller.location_details_updated.is_connected(comp.update_details):
		_hud_controller.location_details_updated.connect(comp.update_details)
	if not _hud_controller.location_details_visibility_changed.is_connected(comp.set_visible):
		_hud_controller.location_details_visibility_changed.connect(comp.set_visible)

func _connect_task_details() -> void:
	var comp = _components.task_details
	if not is_instance_valid(comp): return

	if not _hud_controller.task_details_updated.is_connected(comp.update_details):
		_hud_controller.task_details_updated.connect(comp.update_details)
	if not _hud_controller.task_details_visibility_changed.is_connected(comp.set_visible):
		_hud_controller.task_details_visibility_changed.connect(comp.set_visible)

func _connect_loot_details() -> void:
	var comp = _components.loot_details
	if not is_instance_valid(comp): return

	if not _hud_controller.loot_details_updated.is_connected(comp.update_details):
		_hud_controller.loot_details_updated.connect(comp.update_details)

func _connect_actions_panel() -> void:
	var comp = _components.actions_panel
	if not is_instance_valid(comp): return

	if not _hud_controller.actions_updated.is_connected(comp.update_actions):
		_hud_controller.actions_updated.connect(comp.update_actions)
	if not comp.action_selected.is_connected(_hud.on_action_selected):
		comp.action_selected.connect(_hud.on_action_selected)
	if not comp.attribute_hovered.is_connected(_hud_controller._on_attribute_hovered):
		comp.attribute_hovered.connect(_hud_controller._on_attribute_hovered)

func _connect_system_controls() -> void:
	_connect_auto_battle_controls()
	_connect_pause_controls()
	_connect_debug_controls()
	_connect_hud_signals()
	_connect_unit_manager_signals()

func _connect_auto_battle_controls() -> void:
	if is_instance_valid(_components.auto_battle_button):
		_components.auto_battle_button.toggled.connect(func(pressed: bool):
			if not _hud_controller._auto_battle_button_sync:
				_hud_controller.emit_auto_battle_toggle_requested(pressed)
		)

func _connect_pause_controls() -> void:
	if is_instance_valid(_components.pause_button):
		_components.pause_button.pressed.connect(func():
			_hud.menu_requested.emit(GameConstants.MenuType.PAUSE, PlayerAction.new())
		)

func _connect_debug_controls() -> void:
	if is_instance_valid(_components.debug_clear_journal_button):
		_components.debug_clear_journal_button.pressed.connect(func():
			var journal_manager = _hud.get_node_or_null("/root/JournalManager")
			if journal_manager:
				journal_manager.clear_journal()
		)
	
	if is_instance_valid(_components.debug_disable_logs_button):
		_components.debug_disable_logs_button.toggled.connect(func(pressed: bool):
			GameLogger.logs_enabled = not pressed
		)

	_connect_debug_stat_buttons()

func _connect_debug_stat_buttons() -> void:
	if is_instance_valid(_components.debug_player_stats_button):
		_components.debug_player_stats_button.toggled.connect(func(pressed: bool):
			_apply_debug_stat_boost(GameConstants.Faction.PLAYER, pressed)
		)

	if is_instance_valid(_components.debug_enemy_stats_button):
		_components.debug_enemy_stats_button.toggled.connect(func(pressed: bool):
			_apply_debug_stat_boost(GameConstants.Faction.ENEMY, pressed)
		)

	if is_instance_valid(_components.debug_neutral_stats_button):
		_components.debug_neutral_stats_button.toggled.connect(func(pressed: bool):
			_apply_debug_stat_boost(GameConstants.Faction.NEUTRAL, pressed)
		)

func _apply_debug_stat_boost(faction: int, enabled: bool) -> void:
	if _unit_manager:
		var amount = GameConstants.Difficulty.DEBUG_STAT_BOOST if enabled else -GameConstants.Difficulty.DEBUG_STAT_BOOST
		_unit_manager.apply_faction_stat_boost(faction, amount)

func _connect_hud_signals() -> void:
	if is_instance_valid(_hud):
		if not _hud.menu_requested.is_connected(_hud_controller._on_menu_requested):
			_hud.menu_requested.connect(_hud_controller._on_menu_requested)
		if not _hud.action_executed.is_connected(_hud_controller._on_hud_action_executed):
			_hud.action_executed.connect(_hud_controller._on_hud_action_executed)

func _connect_unit_manager_signals() -> void:
	if is_instance_valid(_unit_manager):
		if not _unit_manager.selection_changed.is_connected(_hud_controller._on_unit_manager_selection_changed):
			_unit_manager.selection_changed.connect(_hud_controller._on_unit_manager_selection_changed)
		if not _unit_manager.unit_moved.is_connected(_hud_controller._on_unit_manager_unit_moved):
			_unit_manager.unit_moved.connect(_hud_controller._on_unit_manager_unit_moved)
		if not _unit_manager.unit_removed.is_connected(_hud_controller._on_unit_removed):
			_unit_manager.unit_removed.connect(_hud_controller._on_unit_removed)
