class_name LevelManagerGameplay
extends RefCounted
const HOMETOWN_EXIT_COORD := Vector2i(0, 0)
signal level_complete(level_path: String)
signal quit_to_title
signal quit_to_level_select

var _game_state: GameState
var _controls: Node
var _level_resource: Level
var _save_manager: Node
var _level_catalog: LevelCatalog
var _dialogue_service: DialogueActionService
var _level_row_loader: LevelRowLoader
var _auto_fix_options: LevelAutoFixOptions
var _auto_fix_enabled: bool = OS.is_debug_build()
var _pending_level_victory: bool = false

var _state_controller = load("res://level/level_state_controller.gd").new() # Type: LevelStateController
var _roster_service = load("res://level/level_roster_service.gd").new() # Type: LevelRosterService

var _enemy_roster_definition: UnitRosterDefinition
var _neutral_roster_definition: UnitRosterDefinition

func _init(game_state: GameState, controls: Node) -> void:
	_game_state = game_state
	_controls = controls
	_level_catalog = LevelCatalog.new()
	_level_row_loader = LevelRowLoader.new()
	_auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_options.enabled = _auto_fix_enabled
	_level_row_loader.set_auto_fix_options(_auto_fix_options)

	_state_controller.setup(_game_state)
	_state_controller.level_complete.connect(func(path: String): level_complete.emit(path))
	_state_controller.quit_to_title.connect(func(): quit_to_title.emit())
	_state_controller.quit_to_level_select.connect(func(): quit_to_level_select.emit())

	if _game_state and _game_state.task_controller:
		_game_state.task_controller.game_over.connect(on_task_failed)
	if _game_state and _game_state.task_manager:
		var tm := _game_state.task_manager
		if not tm.objective_completed.is_connected(_on_objective_completed):
			tm.objective_completed.connect(_on_objective_completed)
			
	if _game_state and _game_state.turn_controller:
		_game_state.turn_controller.player_defeated.connect(_state_controller.handle_player_defeat)

func set_save_manager(save_manager: SaveManager) -> void:
	_save_manager = save_manager
	_roster_service.setup(_save_manager)
	_roster_service.refresh_player_roster(_game_state)

func set_dialogue_service(service: DialogueActionService) -> void:
	_dialogue_service = service
	GameLogger.debug(GameLogger.Category.MAP, "[LevelManager] set_dialogue_service called. Service valid: ", service != null)
	if _dialogue_service and _level_resource:
		_dialogue_service.prepare_for_level(_level_resource)

func set_auto_fix_enabled(enabled: bool) -> void:
	_auto_fix_enabled = enabled
	if _auto_fix_options == null: _auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_options.enabled = enabled
	if _level_row_loader: _level_row_loader.set_auto_fix_options(_auto_fix_options)

# Handle turn-enabling logic was moved to TaskController

func set_level_resource(level: Level) -> void:
	_level_resource = level
	_state_controller.update_safe_zone_ui(_is_hometown_level(level))
	if _dialogue_service:
		_dialogue_service.prepare_for_level(_level_resource)

# --- Orchestrator-Driven Granular Phases ---

## Prepares row data and refreshes rosters without spawning anything.
func prepare_level_data() -> void:
	if not _level_resource or not _game_state: return
	_apply_row_resources(_level_resource)
	_roster_service.refresh_player_roster(_game_state)
	_state_controller.update_safe_zone_ui(_is_hometown_level(_level_resource))
	if _dialogue_service: _dialogue_service.prepare_for_level(_level_resource)
	if _game_state and is_instance_valid(_game_state.journal_manager):
		_game_state.journal_manager.set_level(_level_resource)

## Resets Managers and prepares for a fresh world build.
func clear_world() -> void:
	if _game_state.turn_controller:
		_game_state.turn_controller.set_enabled(false)
	if _game_state.unit_manager:
		_game_state.unit_manager.reset()
	if _game_state.loot_manager:
		_game_state.loot_manager.reset()
	if _game_state.location_service:
		_game_state.location_service.reset()
	TargetDiscoveryService.clear_registry()

## Builds terrain and grid settings.
func build_environment() -> Dictionary:
	var builder: LevelBuilder = LevelBuilder.new(_create_build_context())
	# We pass a modified version of builder.build() that only does technical/terrain setup
	var result: Dictionary = builder.build_environment(_level_resource, _game_state.map_controller.get_terrain_map())
	_handle_build_result(result)
	return result

## Spawns the units and objects defined at the Level level (not stage level).
func spawn_global_content() -> void:
	var builder: LevelBuilder = LevelBuilder.new(_create_build_context())
	builder.spawn_global_content(_level_resource, _game_state.map_controller.get_terrain_map())

	if _game_state.unit_manager:
		_game_state.unit_manager.reset_all_neutral_loyalties()
		if _game_state.player_roster: _game_state.unit_manager.set_roster_for_faction(GameConstants.Faction.PLAYER, _game_state.player_roster)
		if "enemy_roster" in _game_state and _game_state.enemy_roster: _game_state.unit_manager.set_roster_for_faction(GameConstants.Faction.ENEMY, _game_state.enemy_roster)
		if "neutral_roster" in _game_state and _game_state.neutral_roster: _game_state.unit_manager.set_roster_for_faction(GameConstants.Faction.NEUTRAL, _game_state.neutral_roster)

## Performs camera snapping and UI alignment.
func finalize_setup() -> void:
	_connect_morale_panel_signals()
	_queue_hometown_progression_dialogues()

	if _game_state.task_controller:
		_game_state.task_controller.finish_setup()

# --- Orchestrator Integration ---

func apply_level_if_available() -> void:
	if not _level_resource or not _game_state: return
	const Orchestrator = preload("res://level/level_initialization_orchestrator.gd")
	Orchestrator.run_initialization_pipeline(_level_resource, self , _game_state.task_controller)

func _create_build_context() -> LevelBuildContext:
	var enemy_roster: EnemyRoster = EnemyRoster.new()
	if _enemy_roster_definition:
		for entry in _enemy_roster_definition.spawn_entries:
			if entry.unit_scene: enemy_roster.units.append(entry.unit_scene)

	var neutral_roster: NeutralRoster = NeutralRoster.new()
	if _neutral_roster_definition:
		for entry in _neutral_roster_definition.spawn_entries:
			if entry.unit_scene: neutral_roster.units.append(entry.unit_scene)

	var leader_name: String = _roster_service.determine_leader_name(_game_state.player_roster)
	
	return LevelBuildContext.new(
		_game_state, _game_state.grid, _game_state.unit_manager, _game_state.unit_controller,
		_game_state.task_manager, _game_state.loot_manager, _game_state.combat_system,
		_game_state.grid, _game_state.camera_2d, _controls, _game_state.player_roster,
		enemy_roster, neutral_roster, [], _level_resource, true, _dialogue_service,
		_game_state.animation_service, leader_name, _game_state.location_service, _game_state.interaction_sequencer
	)

func _handle_build_result(result: Dictionary) -> void:
	if "grid_width" in result:
		_state_controller.update_grid_dimensions(result.grid_width, result.grid_height)
		_game_state.move_controller.update_grid_dimensions(result.grid_width, result.grid_height)
		if _game_state.map_controller: _game_state.map_controller.build_grid(result.grid_width, result.grid_height)
		if _game_state.hex_navigator and _game_state.grid: _game_state.hex_navigator.cache_analog_vectors(_game_state.grid)
		_apply_hometown_exploration_rules()
		if is_instance_valid(_game_state.grid_visuals) and _game_state.grid:
			_game_state.grid_visuals.update_terrain_overlay(_game_state.grid, _game_state.map_controller.get_terrain_map())

func _connect_morale_panel_signals() -> void:
	if not _game_state.hud: return
	if not _game_state.hud.is_node_ready(): await _game_state.hud.ready
	var morale_panel: MoralePanel = _game_state.hud.get_node_or_null("HUDMarginContainer/BottomCenterContainer/MoralePanel")
	if is_instance_valid(morale_panel):
		if not morale_panel.player_retreat_triggered.is_connected(_state_controller.handle_player_defeat.bind(tr("msg.game_over_morale"))):
			morale_panel.player_retreat_triggered.connect(_state_controller.handle_player_defeat.bind(tr("msg.game_over_morale")))
		if not morale_panel.enemy_retreat_triggered.is_connected(_state_controller.handle_enemy_retreat):
			morale_panel.enemy_retreat_triggered.connect(_state_controller.handle_enemy_retreat)
		if not morale_panel.neutral_retreat_triggered.is_connected(_state_controller.handle_neutral_retreat):
			morale_panel.neutral_retreat_triggered.connect(_state_controller.handle_neutral_retreat)
		morale_panel.reset_state(_game_state.unit_manager)

func set_level_and_rebuild(level: Level) -> void:
	_level_resource = level
	apply_level_if_available()
	if _game_state and _game_state.camera_controller:
		_game_state.camera_controller.initialize_camera()

func on_() -> void:
	_state_controller.on_(_level_resource, _save_manager)

func update_task_progress() -> void:
	_state_controller.update_task_progress()

func on_task_failed() -> void:
	_state_controller.handle_player_defeat(tr("msg.defeat_retreat"))

func _on_objective_completed(_objective: Objective) -> void:
	if _pending_level_victory:
		return
	_pending_level_victory = true
	_complete_level_after_narrative()

func _complete_level_after_narrative() -> void:
	await _wait_for_dialogue_queue_start()
	if _game_state and _game_state.task_controller and _game_state.task_controller.is_narrative_blocking():
		await _wait_for_dialogue_clear()
	_pending_level_victory = false
	on_()

func _wait_for_dialogue_clear() -> void:
	var tree := _resolve_scene_tree()
	while _game_state and _game_state.task_controller and _game_state.task_controller.is_narrative_blocking():
		var loop := tree
		if loop == null and Engine.get_main_loop() is SceneTree:
			loop = Engine.get_main_loop()
		if loop:
			await loop.process_frame
		else:
			break

func _wait_for_dialogue_queue_start(max_frames: int = 60) -> void:
	var tree := _resolve_scene_tree()
	if tree == null and Engine.get_main_loop() is SceneTree:
		tree = Engine.get_main_loop()
	if tree == null:
		return

	var frames := 0
	while frames < max_frames and _game_state and _game_state.task_controller and not _game_state.task_controller.is_narrative_blocking():
		await tree.process_frame
		frames += 1

func _resolve_scene_tree() -> SceneTree:
	if _game_state and _game_state.hud:
		return _game_state.hud.get_tree()
	if Engine.get_main_loop() is SceneTree:
		return Engine.get_main_loop()
	return null

func _get_level_id_for_level(level: Level) -> StringName:
	if level == null or level.resource_path == "": return StringName()
	var info := _level_catalog.find_level_by_path(level.resource_path)
	return StringName(info.get("id", ""))

func _apply_row_resources(level: Level) -> void:
	if level == null: return
	var level_id := _get_level_id_for_level(level)
	if String(level_id).is_empty(): return
	var row_result: Dictionary = _level_row_loader.apply_rows_to_level(level, level_id)
	_enemy_roster_definition = level.enemy_roster_definition
	_neutral_roster_definition = level.neutral_roster_definition
	for err in row_result.get("errors", []): GameLogger.warning(GameLogger.Category.MAP, err)
	if row_result.get("auto_fix"):
		for msg in row_result.auto_fix.get("messages", []): GameLogger.warning(GameLogger.Category.MAP, msg)
		if row_result.auto_fix.get("summary"): GameLogger.warning(GameLogger.Category.MAP, row_result.auto_fix.summary)

func _is_hometown_level(level: Level) -> bool:
	if level == null or level.resource_path == "": return false
	var info := _level_catalog.find_level_by_path(level.resource_path)
	return info.get("is_hometown", false)

func _queue_hometown_progression_dialogues() -> void:
	if not _is_hometown_level(_level_resource) or not _game_state or not _game_state.task_controller: return
	var hometown_svc := HometownProgressionService.new(_level_catalog, _save_manager)
	var skit := hometown_svc.pop_skit()
	if skit != null: hometown_svc.queue_dialogue(skit.dialogue_path)

func on_unit_moved(index: int, coord: Vector2i) -> void:
	if not _game_state.unit_manager or not _game_state.task_manager: return
	if index != _game_state.unit_manager.get_selected_index(): return
	if not _is_hometown_level(_level_resource) or coord != HOMETOWN_EXIT_COORD: return
	quit_to_level_select.emit()

func _apply_hometown_exploration_rules() -> void:
	if _game_state == null or _game_state.unit_manager == null: return
	var explorer := _get_primary_player_unit()
	if explorer == null: return
	explorer.set_free_roam_mode(_is_hometown_level(_level_resource))

func _get_primary_player_unit() -> Unit:
	if _game_state == null or _game_state.unit_manager == null: return null
	var units: Array = _game_state.unit_manager.get_player_units()
	return units[0] if not units.is_empty() else null
