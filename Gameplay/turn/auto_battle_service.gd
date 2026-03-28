class_name AutoBattleService
extends RefCounted

var _controller: TurnController
var _unit_manager: UnitManager
var _ai_controller: AIController

var _enabled := false
var _in_progress := false
var _attempted_indices: Array[int] = []

func _init(controller: TurnController) -> void:
	_controller = controller

func setup(unit_manager: UnitManager, ai_controller: AIController) -> void:
	_unit_manager = unit_manager
	_ai_controller = ai_controller

func reset() -> void:
	_attempted_indices.clear()

func is_enabled() -> bool:
	return _enabled

func is_in_progress() -> bool:
	return _in_progress

func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: auto battle unchanged ->", enabled)
		return
	_enabled = enabled
	_reset_attempts()

	var pending_unit: Unit = null
	if _enabled and _unit_manager:
		var candidate_index := _find_player_unit_candidate()
		if candidate_index != GameConstants.INVALID_INDEX:
			pending_unit = _activate_candidate_unit(candidate_index)

	GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: auto battle set ->", enabled)
	_controller.player_auto_battle_changed.emit(_enabled)

	if _enabled:
		var tree = _controller.get_tree()
		if tree:
			await tree.process_frame
		maybe_run_turn(pending_unit)

func force_disable(reason: String = "") -> void:
	if not _enabled:
		return
	if not reason.is_empty():
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: force disabling ->", reason)
		_controller.player_auto_battle_failed.emit(reason)
	set_enabled(false)

func maybe_run_turn(unit: Unit = null) -> void:
	if not _can_run_auto_turn():
		return

	var resolved_unit = unit if unit != null else _resolve_current_player_unit()
	if not _is_valid_auto_unit(resolved_unit):
		return

	GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: starting auto battle for unit=", resolved_unit.unit_name)
	_process_auto_turn(resolved_unit)

func _can_run_auto_turn() -> bool:
	if not _enabled:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: disabled; skipping auto run request")
		return false
	if _in_progress:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: already processing; ignoring new request")
		return false
	if _controller and not _controller.is_enabled():
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: turn controller disabled; skipping auto run")
		return false
	return true

func _resolve_current_player_unit() -> Unit:
	var current_index := _controller.get_current_unit_index()
	if current_index == GameConstants.INVALID_INDEX or _unit_manager == null:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: no current player unit to auto-activate")
		return null
		
	if not _unit_manager.is_player_controlled(current_index):
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: current turn unit is not player-controlled; skipping auto run")
		return null
		
	return _unit_manager.get_unit(current_index)

func _is_valid_auto_unit(unit: Unit) -> bool:
	if not is_instance_valid(unit) or unit.willpower <= 0:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: active unit invalid or exhausted; cannot auto run")
		return false
	return true


func _process_auto_turn(unit: Unit) -> void:
	_in_progress = true
	var ai_performed_action = await _execute_ai_turn_logic(unit)
	_in_progress = false

	if not is_instance_valid(unit):
		_handle_unit_invalidated_after_action()
		return

	_handle_ai_result(unit, ai_performed_action)

func _handle_ai_result(unit: Unit, success: bool) -> void:
	if success:
		_handle_ai_success(unit)
	else:
		_handle_ai_failure(unit)

func _execute_ai_turn_logic(unit: Unit) -> bool:
	var tree = _controller.get_tree()
	if tree and not _controller._animation_service.should_skip_delays():
		await tree.create_timer(GameConstants.UI.AI_THINK_DELAY).timeout

	var ai_performed_action := false
	if _ai_controller and is_instance_valid(unit) and unit.willpower > 0:
		var result = await _ai_controller.execute_turn(unit)
		ai_performed_action = result if result != null else false

	if ai_performed_action and tree and not _controller._animation_service.should_skip_delays():
		await tree.create_timer(GameConstants.UI.AI_ACTION_DELAY).timeout
	
	return ai_performed_action

func _handle_unit_invalidated_after_action() -> void:
	GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: unit became invalid after action; completing turn to unblock queue")
	_in_progress = false
	if _controller:
		_controller.complete_turn()

func _handle_ai_success(unit: Unit) -> void:
	_reset_attempts()
	_in_progress = false
	
	var preserve_player_turn := _should_preserve_turn(unit)
	if not preserve_player_turn:
		_controller.complete_turn()
	else:
		if _unit_manager:
			_unit_manager.select_index(_controller.get_current_unit_index())
		_controller.turn_ready.emit(unit)
		if _enabled and is_instance_valid(unit) and unit.willpower > 0:
			maybe_run_turn(unit)

func _handle_ai_failure(unit: Unit) -> void:
	_in_progress = false
	_record_attempt(_controller.get_current_unit_index())
	
	if not _attempts_exhausted() and _try_select_alternate_unit(unit):
		return
		
	force_disable("Auto battle disabled: AI had no actions for %s" % (unit.unit_name if unit else "unit"))
	if _unit_manager:
		_unit_manager.select_index(_controller.get_current_unit_index())
	_controller.turn_ready.emit(unit)

func _find_player_unit_candidate() -> int:
	if _controller.get_current_side() != GameConstants.Side.PLAYER:
		return GameConstants.INVALID_INDEX

	var candidate_index := _controller.get_current_unit_index()
	if candidate_index == GameConstants.INVALID_INDEX:
		candidate_index = _get_fallback_candidate()

	if candidate_index >= 0 and _unit_manager.is_player_controlled(candidate_index):
		var unit: Unit = _unit_manager.get_unit(candidate_index)
		if is_instance_valid(unit) and unit.willpower > 0:
			return candidate_index
		else:
			GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: candidate unit invalid or 0 willpower: index=", candidate_index)
	else:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: could not find valid player unit candidate")
	
	return GameConstants.INVALID_INDEX

func _get_fallback_candidate() -> int:
	var selected_index := _unit_manager.get_selected_index() if _unit_manager.has_method("get_selected_index") else GameConstants.INVALID_INDEX
	if selected_index >= 0 and _unit_manager.is_player_controlled(selected_index):
		return selected_index
	
	var queue = _controller.get_turn_queue()
	if not queue.is_empty():
		var front_index: int = queue[0]
		if _unit_manager.is_player_controlled(front_index):
			return front_index
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: front of queue is not player controlled: index=", front_index)
	else:
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleService: turn queue is empty")
	
	return GameConstants.INVALID_INDEX

func _activate_candidate_unit(index: int) -> Unit:
	var unit: Unit = _unit_manager.get_unit(index)
	_controller.set_current_unit_index(index)
	# Lock player turn properly if we found a unit
	if _controller is TurnController:
		_controller.set_player_turn_locked(true)
	return unit

func _try_select_alternate_unit(_current_unit: Unit) -> bool:
	if _unit_manager == null or _controller.is_queue_empty():
		return false

	var current_is_player := true
	var queue = _controller.get_turn_queue()
	var _front_index: int = queue[0]

	for i in range(1, queue.size()):
		var candidate_index: int = queue[i]
		if _unit_manager.is_player_controlled(candidate_index) != current_is_player:
			continue
		if _attempted_indices.has(candidate_index):
			continue

		_controller.move_index_to_front(candidate_index, i)
		_controller.set_current_unit_index(candidate_index)

		var new_unit: Unit = _unit_manager.get_unit(candidate_index)
		_unit_manager.select_index(candidate_index)
		_controller.turn_ready.emit(new_unit)

		if _enabled:
			maybe_run_turn(new_unit)
		return true

	return false

func _reset_attempts() -> void:
	_attempted_indices.clear()

func _record_attempt(index: int) -> void:
	if index >= 0 and not _attempted_indices.has(index):
		_attempted_indices.append(index)

func _attempts_exhausted() -> bool:
	if _unit_manager == null:
		return false
	var total_available := 0
	var count: int = _unit_manager.get_unit_count()
	for i in range(count):
		if not _unit_manager.is_player_controlled(i):
			continue
		var candidate: Unit = _unit_manager.get_unit(i)
		if is_instance_valid(candidate) and candidate.willpower > 0:
			total_available += 1
	return total_available > 0 and _attempted_indices.size() >= total_available

func _should_preserve_turn(unit: Object) -> bool:
	if not is_instance_valid(unit) or _controller.get_current_side() != GameConstants.Side.PLAYER:
		return false
	return unit.has_method("is_in_free_roam_mode") and unit.is_in_free_roam_mode()

func create_memento() -> Dictionary:
	return {
		"enabled": _enabled,
		"in_progress": _in_progress,
		"attempted_indices": _attempted_indices.duplicate()
	}

func restore_from_memento(memento: Dictionary) -> void:
	var previous_enabled = _enabled
	_enabled = memento.get("enabled", false)
	_in_progress = false
	_attempted_indices = memento.get("attempted_indices", [])

	if previous_enabled != _enabled:
		_controller.player_auto_battle_changed.emit(_enabled)
