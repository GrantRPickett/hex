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
var _last_blocking_state := false
var _last_queue_contents := ""

var _dialogue_handler # Type: TaskDialogueHandler
var _condition_handler # Type: TaskConditionHandler
var _current_stage_id: StringName = &""
var level: Level

var _setup_finished: bool = false

func setup(state: GameState) -> void:
	print_debug("[Task] setup() called with state=%s" % ["valid" if state else "null"])
	_task_manager = state.task_manager
	_unit_manager = state.unit_manager
	_unit_controller = state.unit_controller
	_turn_controller = state.turn_controller
	_loot_manager = state.loot_manager
	_combat_system = state.combat_system
	_location_service = state.location_service
	_state = state
	_dialogue_handler = load("res://Gameplay/narrative/task/task_dialogue_handler.gd").new()
	_condition_handler = load("res://Gameplay/narrative/task/task_condition_handler.gd").new()
	_dialogue_handler.dialogue_requested.connect(func(path): dialogue_requested.emit(path))
	_dialogue_handler.setup(state)
	_condition_handler.setup(_task_manager, _unit_manager)
	_setup_finished = false

	if _task_manager:
		print_debug("[Task] Connecting to task_manager signals")
		if not _task_manager.task_completed.is_connected(on_task_completed):
			_task_manager.task_completed.connect(on_task_completed)
		if not _task_manager.objective_updated.is_connected(_on_objective_updated):
			_task_manager.objective_updated.connect(_on_objective_updated)

		var active_obj = _task_manager.get_active_objective()
		if active_obj and active_obj.is_active and active_obj.current_stage:
			print_debug("[Task] Objective already active during setup")

	if _turn_controller and not _turn_controller.round_changed.is_connected(on_round_changed):
		_turn_controller.round_changed.connect(on_round_changed)

func finish_setup() -> void:
	_setup_finished = true
	check_objective_conditions()
	_update_turn_blocking()

func bootstrap_level(current_level: Level) -> void:
	print_debug("[Task] bootstrap_level called with ", current_level.resource_path if current_level else "null")
	_setup_finished = false
	self.level = current_level
	if _task_manager:
		_task_manager.prepare_objective(current_level, current_level.objective)

func activate_initial_stage() -> void:
	print_debug("[Task] activate_initial_stage called")
	if _task_manager:
		_task_manager.start_active_objective()

# --- Legacy Helper ---

func set_level(current_level: Level) -> void:
	bootstrap_level(current_level)
	activate_initial_stage()

func handle_event(event_type: String, params: Dictionary = {}) -> void:
	if event_type == GameConstants.TaskEvents.DIALOGUE_FINISHED:
		_on_dialogue_finished(params.get("flag_id", &""))

	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			obj.handle_event(event_type, params)

func on_unit_defeated(unit: Unit, attacker: Unit = null) -> void:
	handle_event(GameConstants.TaskEvents.UNIT_DEFEATED, {"unit": unit, "attacker": attacker})
	check_objective_conditions()

func _on_stage_completed(_next_stage: Stage, completing_stage: Stage) -> void:
	if completing_stage:
		print_debug("[Task] Stage '%s' completed, queuing exit dialogues..." % completing_stage.id)
		_dialogue_handler.queue_task_dialogues(completing_stage, "on_exit")
		_dialogue_handler.queue_stage_dialogues(completing_stage, "on_exit")
		_current_stage_id = &""
		_dialogue_handler.process_queue()

func _on_stage_failed(failing_stage: Stage) -> void:
	if failing_stage:
		print_debug("[Task] Stage '%s' failed, queuing exit dialogues..." % failing_stage.id)
		_dialogue_handler.queue_task_dialogues(failing_stage, "on_exit")
		_dialogue_handler.queue_stage_dialogues(failing_stage, "on_exit")
		_dialogue_handler.process_queue()

func on_task_completed(index: int, faction: int, unit: Unit) -> void:
	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj and obj.current_stage:
			var tasks = obj.current_stage.active_tasks
			if index >= 0 and index < tasks.size():
				var task = tasks[index]
				if task and task.reward_resource:
					_grant_mid_stage_reward(task.reward_resource, unit, faction)
				elif task and not task.reward_id.is_empty():
					# Fallback for string-based reward_id if needed
					pass
	check_objective_conditions()

func _grant_mid_stage_reward(reward: TaskReward, unit: Unit, faction: int) -> void:
	if not reward: return

	match reward.reward_type:
		TaskReward.RewardType.ITEM:
			var item_id = reward.reward_value
			# We assume target_id or reward_value is the item's resource name or ID.
			# For now, we'll try to find or create an InventoryItem.
			# If we have a dedicated ItemService, we'd use it.
			# As a fallback, we'll look in res://Resources/items/ or similar.
			var item_path = "res://Resources/items/%s.tres" % item_id
			if FileAccess.file_exists(item_path):
				var item_res = load(item_path)
				if item_res is InventoryItem:
					var item_instance = item_res.duplicate_instance(true)
					if unit and is_instance_valid(unit) and unit.inv:
						unit.inv.add_item_to_inventory(item_instance)
						print_debug("[Task] Mid-stage reward: Added item '%s' to unit '%s'" % [item_id, unit.unit_name])
					else:
						# Fallback to stash
						if _state and _state.player_roster and faction == Unit.Faction.PLAYER:
							_state.player_roster.add_to_stash([item_instance])
							print_debug("[Task] Mid-stage reward: Added item '%s' to player stash (no unit)" % item_id)
			else:
				push_error("[Task] Failed to grant reward: Item resource not found at %s" % item_path)

		TaskReward.RewardType.HINT:
			# Handle hints/journal entries if needed
			pass
		TaskReward.RewardType.UNIT_ADDITION:
			# Handle unit spawning if needed
			pass

func _on_objective_updated(objective: Resource) -> void:
	if objective and objective.is_active and objective.current_stage:
		var stage = objective.current_stage
		var stage_id = stage.get("id") if stage.has_method("get") else &""

		if stage_id == _current_stage_id:
			return

		_current_stage_id = stage_id
		_log_stage_transition(objective)

		if not stage.stage_completed.is_connected(_on_stage_completed):
			stage.stage_completed.connect(_on_stage_completed.bind(stage))
		if not stage.stage_failed.is_connected(_on_stage_failed):
			stage.stage_failed.connect(_on_stage_failed.bind(stage))

		_dialogue_handler.queue_stage_dialogues(stage, "on_enter")
		_dialogue_handler.queue_task_dialogues(stage, "on_enter")
		_handle_stage_spawns(stage)
		_dialogue_handler.process_queue()
	check_objective_conditions()

func on_round_changed(current_round: int) -> void:
	handle_event(GameConstants.TaskEvents.ROUND_CHANGED, {"round": current_round})
	check_objective_conditions()

func check_objective_conditions() -> void:
	if _task_reached_state or _game_over_state:
		return

	var player_units = _condition_handler.get_player_units()
	check_inventory_objectives(player_units)

	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj and obj.is_active and obj.current_stage:
			# Check special completion conditions for active tasks
			for task in obj.current_stage.active_tasks:
				if not is_instance_valid(task) or task.status != Task.Status.ACTIVE:
					continue

				if task.completion_condition and task.completion_condition.type == "DEFEAT_ALL_UNITS_OF_FACTION":
					if not _setup_finished:
						continue
					var target_faction = task.completion_condition.faction
					var units_alive = _unit_manager.get_units_by_faction(target_faction) if _unit_manager.has_method("get_units_by_faction") else []
					if units_alive.is_empty():
						task.force_complete()


		if obj:
			if not obj.is_active:
				_log_objective_completed(obj)
				_task_reached_state = true
				_grant_end_of_level_rewards()
			elif _condition_handler.check_objective_failed(obj):
				_log_objective_failed(obj)
				_game_over_state = true
	
	_update_turn_blocking()

func _grant_end_of_level_rewards() -> void:
	if not _loot_manager or not _unit_manager or not _state.player_roster:
		return

	var collected_items: Array[InventoryItem] = []

	# 1. Collect from routing pool (difficulty-based missed loot)
	if _loot_manager.has_method("collect_routing_pool"):
		collected_items.append_array(_loot_manager.collect_routing_pool())

	# 2. Collect from ground loot (Standard behavior for "map routing")
	collected_items.append_array(_loot_manager.collect_all_loot_items())

	# 3. Collect from surviving neutrals (Spec requirement)
	var neutrals = _unit_manager.get_neutral_units()
	for unit in neutrals:
		if is_instance_valid(unit) and unit.willpower > 0:
			var inv_comp = unit.inv
			if inv_comp:
				var inv_ref = inv_comp.get_inventory()
				if inv_ref:
					collected_items.append_array(inv_ref.get_items())
					inv_ref.clear()

	# 4. Add to player stash
	_state.player_roster.add_to_stash(collected_items)
	print_debug("[Task] End of level rewards granted: %d items added to stash" % collected_items.size())

func check_inventory_objectives(player_units: Array[Unit]) -> void:
	if _task_manager:
		_condition_handler.handle_inventory_check(_task_manager.get_active_objective(), player_units)

func _handle_stage_spawns(stage: Resource) -> void:
	if not _unit_manager or not _state.map_controller:
		return

	var grid = _state.map_controller.get_grid()
	var spawn_occurred := false

	spawn_occurred = _spawn_stage_units(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_loot(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_locations(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_dialogue_triggers(stage, grid) or spawn_occurred

	if spawn_occurred and _turn_controller:
		_turn_controller.rebuild_turn_roster(true)

	_update_turn_blocking()

func _spawn_stage_units(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	for field in ["enemy_spawns", "neutral_spawns", "spawns"]:
		var spawns = stage.get(field) if stage.has_method("get") else []
		if spawns.is_empty(): continue

		var faction_override = -1
		if field == "enemy_spawns":
			faction_override = Unit.Faction.ENEMY
		elif field == "neutral_spawns":
			faction_override = Unit.Faction.NEUTRAL

		for spawn in spawns:
			if not spawn or not (spawn is LevelUnitSpawnEntry): continue

			if spawn.unit_scene == null:
				print_debug("[Task] Skipping unit spawn at %s: unit_scene is null" % spawn.coord)
				continue
			if _unit_manager.get_unit_at_coord(spawn.coord) != null:
				print_debug("[Task] Skipping unit spawn at %s: already occupied" % spawn.coord)
				continue

			var unit = TargetSpawner.spawn_unit(spawn, _unit_manager, _loot_manager, _task_manager, _location_service, _combat_system, grid, faction_override)
			if unit:
				spawned = true
				print_debug("[Task] Spawned stage-specific unit: ", unit.unit_name, " at ", spawn.coord)
	return spawned

func _spawn_stage_loot(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var loot_spawns = stage.get("loot_spawns") if stage.has_method("get") else []
	for loot_entry in loot_spawns:
		if not loot_entry: continue
		if _loot_manager and _loot_manager.has_loot_at(loot_entry.get_coord()):
			print_debug("[Task] Skipping loot spawn at %s: already exists" % loot_entry.get_coord())
			continue
		var loot_instance = TargetSpawner.spawn_loot(loot_entry, _loot_manager, _state.grid, grid)
		if loot_instance and _task_manager:
			_task_manager.register_loot(loot_instance)
			spawned = true
			print_debug("[Task] Spawned stage-specific loot at ", loot_entry.get_coord())
	return spawned

func _spawn_stage_locations(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var location_spawns = stage.get("location_spawns") if stage.has_method("get") else []
	for location_entry in location_spawns:
		if not location_entry: continue
		var existing_loc = _task_manager.get_location_at(location_entry.get_coord()) if _task_manager else null
		if existing_loc:
			print_debug("[Task] Skipping location spawn at %s: already exists" % location_entry.get_coord())
			continue
		var location_instance = TargetSpawner.spawn_location(location_entry, _state.grid, grid)
		if location_instance and _task_manager:
			_task_manager.register_location(location_instance)
			spawned = true
			print_debug("[Task] Spawned stage-specific location: ", location_instance.loc_name, " at ", location_entry.get_coord())
	return spawned

func _spawn_stage_dialogue_triggers(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var dialogue_entries = stage.get("dialogue_entries") if stage.has_method("get") else []
	for entry in dialogue_entries:
		if not entry: continue
		var trigger = TargetSpawner.spawn_dialogue_trigger(entry, _state.grid, grid)
		if trigger:
			spawned = true
			print_debug("[Task] Spawned stage-specific dialogue trigger at ", entry.coord)
	return spawned

func _update_turn_blocking() -> void:
	if not _turn_controller: return

	var blocking = is_narrative_blocking()
	var should_block = blocking or _task_reached_state or _game_over_state
	
	if should_block != not _turn_controller.is_enabled():
		print_debug("[TaskController] Narrative/End state changed. Setting turns-enabled to ", not should_block)
		_turn_controller.set_enabled(not should_block)

		if not should_block:
			if _turn_controller.get_turn_queue().is_empty():
				_turn_controller.rebuild_turn_roster(true)
			else:
				_turn_controller.start_next_turn()

	# If we are no longer narrative-blocking, check if we need to emit deferred signals
	if not blocking:
		if _task_reached_state and not _task_reached_emitted:
			print_debug("[TaskController] Narrative block cleared, emitting deferred task_reached signal")
			_task_reached_emitted = true
			task_reached.emit()
		elif _game_over_state and not _game_over_emitted:
			print_debug("[TaskController] Narrative block cleared, emitting deferred game_over signal")
			_game_over_emitted = true
			game_over.emit()

func is_task_reached() -> bool: return _task_reached_state

func is_game_over() -> bool: return _game_over_state

func is_narrative_blocking() -> bool:
	if not _dialogue_handler: return false
	var queue_contents = _dialogue_handler.get_queue_contents()
	var currently_processing = _dialogue_handler.is_processing()
	var queue_empty = _dialogue_handler.is_queue_empty()
	var blocking = not queue_empty or currently_processing

	if blocking != _last_blocking_state or queue_contents != _last_queue_contents:
		print_debug("[TaskController] Narrative blocking state change: ", blocking, " (Queue empty: ", queue_empty, ", Processing: ", currently_processing, ")")
		if not queue_empty:
			print_debug("[TaskController] Dialogue queue contents: ", queue_contents)
		_last_blocking_state = blocking
		_last_queue_contents = queue_contents

	return blocking

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
	if not _task_manager: return null
	return _task_manager.get_task_by_id(task_id)

func get_task_info(task_id: String) -> Dictionary:
	if not _task_manager: return {}
	var task = _task_manager.get_task_by_id(task_id)
	return _transform_task_to_info(task) if task else {}

func get_task_at_coord(coord: Vector2i) -> Dictionary:
	if not _task_manager: return {}
	var location = _task_manager.get_location_at(coord)
	var tasks: Array[Task] = []
	if location: tasks = _task_manager.get_active_tasks_for_target(location)
	if tasks.is_empty():
		var loot = _task_manager.get_loot_at(coord)
		if loot: tasks = _task_manager.get_active_tasks_for_target(loot)
	return _transform_task_to_info(tasks[0]) if not tasks.is_empty() else {}

func _transform_task_to_info(task: Task) -> Dictionary:
	return {
		"id": task.id,
		"title": task.title,
		"description": task.description,
		"status": Task.Status.keys()[task.status] if task.status >= 0 else "UNKNOWN",
		"current": task.current_effort,
		"required": task.effort_required,
		"completed": task.status == Task.Status.COMPLETED,
		"is_optional": task.is_optional,
		"icon": task.icon
	}

func _log_stage_transition(objective: Resource) -> void:
	if not objective or not objective.current_stage: return
	var stage = objective.current_stage
	var completed_count = stage.active_tasks.filter(func(t): return t.status == Task.Status.COMPLETED).size()
	print_debug("[Task] Stage transitioned: '%s' | Tasks: %d/%d completed" % [stage.id, completed_count, stage.active_tasks.size()])

func _log_objective_completed(objective: Resource) -> void:
	if objective: print_debug("[Task] OBJECTIVE COMPLETED: '%s'" % objective.title)

func _log_objective_failed(objective: Resource) -> void:
	if objective: print_debug("[Task] OBJECTIVE FAILED: '%s'" % objective.title)

func _on_dialogue_finished(_flag: StringName = &"") -> void:
	print_debug("[TaskController] _on_dialogue_finished called (flag=", _flag, ")")
	if _dialogue_handler:
		_dialogue_handler.on_dialogue_finished()

	_update_turn_blocking()
