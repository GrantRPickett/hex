class_name TaskController
extends Node
signal task_reached
signal game_over
signal dialogue_requested(dialogue_resource_path: String)

var _task_manager: TaskManager
var _unit_manager: UnitManager
var _unit_controller: UnitController
var _turn_controller: TurnController
var _loot_manager: LootManager
var _combat_system: CombatSystem
var _location_service: LocationService
var _state: GameState
var _task_reached_state: bool = false
var _game_over_state: bool = false
var _task_reached_emitted: bool = false
var _game_over_emitted: bool = false
var _pending_check_on_dialogue_finished: bool = false

var _dialogue_handler: TaskDialogueHandler
var _condition_handler: TaskConditionHandler
var _stage_spawner: TaskStageSpawner
var _current_stage_id: StringName = &""
var level: Level

var _setup_finished: bool = false

func setup(state: GameState) -> void:
	print_debug("[Task] setup() called with state=%s" % ["valid" if state else "null"])
	_state = state
	_task_manager = state.task_manager
	_unit_manager = state.unit_manager
	_unit_controller = state.unit_controller
	_turn_controller = state.turn_controller
	_loot_manager = state.loot_manager
	_combat_system = state.combat_system
	_location_service = state.location_service

	_dialogue_handler = TaskDialogueHandler.new()
	_condition_handler = TaskConditionHandler.new()
	_stage_spawner = TaskStageSpawner.new(state)

	var _err = _dialogue_handler.dialogue_requested.connect(func(path): dialogue_requested.emit(path))
	_dialogue_handler.setup(state)
	_condition_handler.setup(_task_manager, _unit_manager)
	_setup_finished = false

	if _task_manager:
		_connect_task_manager_signals()

	if _turn_controller and not _turn_controller.round_changed.is_connected(on_round_changed):
		var _err2 = _turn_controller.round_changed.connect(on_round_changed)

func _connect_task_manager_signals() -> void:
	if not _task_manager.task_completed.is_connected(on_task_completed):
		var _err1 = _task_manager.task_completed.connect(on_task_completed)
	if not _task_manager.objective_updated.is_connected(_on_objective_updated):
		var _err2 = _task_manager.objective_updated.connect(_on_objective_updated)
	if not _task_manager.objective_completed.is_connected(_on_objective_completed):
		var _err3 = _task_manager.objective_completed.connect(_on_objective_completed)
	if not _task_manager.objective_failed.is_connected(_on_objective_failed):
		var _err4 = _task_manager.objective_failed.connect(_on_objective_failed)

func finish_setup() -> void:
	_setup_finished = true
	check_objective_conditions()
	_update_turn_blocking()

func bootstrap_level(current_level: Level) -> void:
	_setup_finished = false
	self.level = current_level
	if _task_manager:
		_task_manager.prepare_objective(current_level, current_level.objective)

func activate_initial_stage() -> void:
	if _task_manager:
		_task_manager.start_active_objective()

func set_level(current_level: Level) -> void:
	bootstrap_level(current_level)
	activate_initial_stage()

func handle_event(event_type: String, params: Dictionary = {}) -> void:
	if event_type == GameConstants.TaskEvents.DIALOGUE_FINISHED:
		var flag_id = params.get("flag_id", &"")
		_on_dialogue_finished(StringName(flag_id))

	if _task_manager:
		var obj: Objective = _task_manager.get_active_objective()
		if obj: obj.handle_event(event_type, params)

func on_unit_defeated(unit: Unit, attacker: Unit = null) -> void:
	handle_event(GameConstants.TaskEvents.UNIT_DEFEATED, {"unit": unit, "attacker": attacker})
	check_objective_conditions()

# Stage & Task Callbacks

func _on_stage_completed(_next_stage: Stage, completing_stage: Stage) -> void:
	if completing_stage:
		_dialogue_handler.queue_task_dialogues(completing_stage, "on_exit")
		_dialogue_handler.queue_stage_dialogues(completing_stage, "on_exit")
		_current_stage_id = &""
		_pending_check_on_dialogue_finished = true
		_dialogue_handler.process_queue()

func _on_stage_failed(failing_stage: Stage) -> void:
	if failing_stage:
		_dialogue_handler.queue_task_dialogues(failing_stage, "on_exit")
		_dialogue_handler.queue_stage_dialogues(failing_stage, "on_exit")
		_dialogue_handler.process_queue()

func on_task_completed(index: int, faction: int, unit: Unit) -> void:
	if _task_manager:
		var obj: Objective = _task_manager.get_active_objective()
		if obj and obj.current_stage:
			var tasks = obj.current_stage.active_tasks
			if index >= 0 and index < tasks.size():
				var task = tasks[index]
				if task and task.reward_resource:
					_grant_mid_stage_reward(task.reward_resource, unit, faction)
	check_objective_conditions()

func _grant_mid_stage_reward(reward: TaskReward, unit: Unit, faction: int) -> void:
	if not reward: return
	if reward.reward_type == TaskReward.RewardType.ITEM:
		var item_id = reward.reward_value
		var item_path: String = "res://Resources/items/%s.tres" % item_id
		if FileAccess.file_exists(item_path):
			var item_res: Resource = load(item_path)
			if item_res is InventoryItem:
				var item_instance = item_res.duplicate_item(true)
				if unit and is_instance_valid(unit) and unit.inv:
					var _err = unit.inv.add_item_to_inventory(item_instance)
				elif _state and _state.player_roster and faction == GameConstants.Faction.PLAYER:
					_state.player_roster.add_to_stash([item_instance])

func _on_objective_updated(objective: Objective) -> void:
	if objective and objective.is_active and objective.current_stage:
		var stage: Stage = objective.current_stage
		var stage_id: StringName = stage.id
		if not stage_id.is_empty() and stage_id == _current_stage_id:
			return

		_current_stage_id = stage_id
		_dialogue_handler.queue_stage_dialogues(stage, "on_enter")
		_dialogue_handler.queue_task_dialogues(stage, "on_enter")
		_handle_stage_spawns(stage)
		_dialogue_handler.process_queue()
	check_objective_conditions()

func _on_objective_completed(_objective: Objective) -> void:
	check_objective_conditions()

func _on_objective_failed(_objective: Objective) -> void:
	check_objective_conditions()

# Round & Condition Checking

func on_round_changed(current_round: int) -> void:
	if not _task_manager: return
	var obj: Objective = _task_manager.get_active_objective()
	if not obj or not obj.is_active or not obj.current_stage:
		check_objective_conditions()
		return

	var needs_by_faction: Dictionary = _gather_round_requirements(obj.current_stage.active_tasks)
	var faction_data: Dictionary = _collect_faction_data(needs_by_faction)

	# Progress tasks for all factions that have needs or countdowns
	# We iterate through all possible factions to ensure any COUNTDOWN tasks also progress
	for f in [GameConstants.Faction.PLAYER, GameConstants.Faction.ENEMY, GameConstants.Faction.NEUTRAL]:
		handle_event(GameConstants.TaskEvents.ROUND_CHANGED, {
			"round": current_round,
			"factions": faction_data,
			"faction": f
		})

	check_objective_conditions()

func _gather_round_requirements(active_tasks: Array[Task]) -> Dictionary:
	var needs_by_faction := {} # faction -> { "needs_coords": bool, "needed_items": Set/Dict }
	for task: Task in active_tasks:
		if is_instance_valid(task) and task.status != Task.Status.ACTIVE: continue

		# A task is relevant for round processing if it is a countdown or has duration requirements
		if task.event_type == GameConstants.TaskEvents.COUNTDOWN or task.duration_turns > 0:
			var f = task.owning_faction
			if not needs_by_faction.has(f):
				needs_by_faction[f] = {"needs_coords": false, "needed_items": {}}

			var data = needs_by_faction[f]
			if task.event_type == GameConstants.TaskEvents.INTERACT or task.event_type == GameConstants.TaskEvents.EXPLORE_ZONE:
				data["needs_coords"] = true
			elif task.event_type == GameConstants.TaskEvents.LOOT and not task.target_id.is_empty():
				data["needed_items"][task.target_id] = true
	return needs_by_faction

func _collect_faction_data(needs_by_faction: Dictionary) -> Dictionary:
	var faction_data := {}
	for f_key in needs_by_faction:
		var f := f_key as GameConstants.Faction
		var requirements = needs_by_faction[f]
		var coords := []
		var held_items := []
		var units: Array[Unit] = _unit_manager.get_units_by_faction(f)

		for u in units:
			if not is_instance_valid(u): continue
			if requirements["needs_coords"]:
				coords.append(u.get_grid_location())

			for item_id in requirements["needed_items"]:
				if u.inv and u.inv.has_item_by_id(item_id):
					if not held_items.has(item_id):
						held_items.append(item_id)

		faction_data[f] = {"coords": coords, "held_items": held_items}
	return faction_data

func check_objective_conditions() -> void:
	if _task_reached_state or _game_over_state: return

	var player_units: Array[Unit] = _condition_handler.get_player_units()
	check_inventory_objectives(player_units)

	if _task_manager:
		var obj: Objective = _task_manager.get_active_objective()
		if obj and obj.is_active and obj.current_stage:
			_check_defeat_conditions(obj.current_stage)

		if obj:
			if not obj.is_active:
				_task_reached_state = true
				_grant_end_of_level_rewards()
			elif _condition_handler.check_objective_failed(obj):
				_game_over_state = true

	_update_turn_blocking()

func check_inventory_objectives(player_units: Array[Unit]) -> void:
	_condition_handler.handle_inventory_check(_task_manager.get_active_objective(), player_units)


func _check_defeat_conditions(stage: Stage) -> void:
	for task: Task in stage.active_tasks:
		if is_instance_valid(task) and task.status == Task.Status.ACTIVE:
			if task.completion_condition and task.completion_condition.type == "DEFEAT_ALL_UNITS_OF_FACTION":
				if not _setup_finished: continue
				var units_alive: Array[Unit] = _unit_manager.get_units_by_faction(task.completion_condition.faction as GameConstants.Faction)
				if units_alive.is_empty(): task.force_complete()

func _grant_end_of_level_rewards() -> void:
	if not _loot_manager or not _unit_manager or not _state.player_roster: return
	var collected_items: Array[InventoryItem] = []
	if _loot_manager.has_method("collect_routing_pool"):
		collected_items.append_array(_loot_manager.collect_routing_pool())
	collected_items.append_array(_loot_manager.collect_all_loot_items())

	var neutrals: Array[Unit] = _unit_manager.get_neutral_units()
	for unit in neutrals:
		if is_instance_valid(unit) and unit.willpower > 0 and unit.inv:
			var inv_ref = unit.inv.get_inventory()
			if inv_ref is UnitInventory:
				collected_items.append_array(inv_ref.get_items())
				inv_ref.clear()

	_state.player_roster.add_to_stash(collected_items)

# Spawning & Flow Control

func _handle_stage_spawns(stage: Resource) -> void:
	if _stage_spawner.handle_stage_spawns(stage) and _turn_controller:
		_turn_controller.rebuild_turn_roster(true)
	_update_turn_blocking()

func _update_turn_blocking() -> void:
	if not _turn_controller: return
	var blocking = is_narrative_blocking()
	var should_block = blocking or _task_reached_state or _game_over_state

	if should_block != not _turn_controller.is_enabled():
		_turn_controller.set_enabled(bool(should_block) == false)
		if not should_block:
			if _turn_controller.get_turn_queue().is_empty():
				_turn_controller.rebuild_turn_roster(true)
			else:
				_turn_controller.start_next_turn()

	if not blocking:
		if _task_reached_state and not _task_reached_emitted:
			_task_reached_emitted = true
			task_reached.emit()
		elif _game_over_state and not _game_over_emitted:
			_game_over_emitted = true
			game_over.emit()

func is_narrative_blocking() -> bool:
	if not _dialogue_handler: return false
	return not _dialogue_handler.is_queue_empty() or _dialogue_handler.is_processing()

# State & Info

func is_task_reached() -> bool: return _task_reached_state
func is_game_over() -> bool: return _game_over_state
func reset_task_state() -> void:
	_task_reached_state = false
	_game_over_state = false
	_task_reached_emitted = false
	_game_over_emitted = false

func create_memento() -> Dictionary:
	return _task_manager.create_memento() if _task_manager else {}

func restore_from_memento(memento: Dictionary) -> void:
	if _task_manager: _task_manager.restore_from_memento(memento)

func get_task_by_id(task_id: String) -> Task:
	return _task_manager.get_task_by_id(task_id) if _task_manager else null

func get_task_info(task_id: String) -> Dictionary:
	if not _task_manager: return {}
	var task: Task = _task_manager.get_task_by_id(task_id)
	return _transform_task_to_info(task) if task else {}

func get_task_at_coord(coord: Vector2i) -> Dictionary:
	if not _task_manager: return {}
	var location: Node = _task_manager.get_location_at(coord)
	var tasks: Array[Task] = []
	if location: tasks = _task_manager.get_active_tasks_for_target(location as Target)
	if tasks.is_empty():
		var loot: Node = _task_manager.get_loot_at(coord)
		if loot: tasks = _task_manager.get_active_tasks_for_target(loot as Target)
	return _transform_task_to_info(tasks[0]) if not tasks.is_empty() else {}


func _transform_task_to_info(task: Task) -> Dictionary:
	var current = task.current_effort
	var required = task.effort_required

	if task.duration_turns > 0:
		current = task.elapsed_turns
		required = task.duration_turns

	return {
		"id": task.id,
		"title": task.title,
		"description": task.description,
		"status": Task.Status.keys()[task.status] if task.status >= 0 else "UNKNOWN",
		"current": current,
		"required": required,
		"completed": task.status == Task.Status.COMPLETED,
		"is_optional": task.is_optional,
		"icon": task.icon
	}

func handle_dialogue_finished(flag: StringName = &"") -> void:
	_on_dialogue_finished(flag)

func _on_dialogue_finished(_flag: StringName = &"") -> void:
	if _dialogue_handler: _dialogue_handler.on_dialogue_finished()
	if _pending_check_on_dialogue_finished and not is_narrative_blocking():
		_pending_check_on_dialogue_finished = false
		check_objective_conditions()
	_update_turn_blocking()
