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
		print_debug("AutoBattleService: auto battle unchanged ->", enabled)
		return
	_enabled = enabled
	_reset_attempts()

	var pending_unit: Unit = null
	if _enabled and _unit_manager and _controller.get_current_side() == TurnSystem.Side.PLAYER:
		var candidate_index := _controller.get_current_unit_index()
		if candidate_index == GameConstants.INVALID_INDEX:
			var selected_index := _unit_manager.get_selected_index() if _unit_manager.has_method("get_selected_index") else GameConstants.INVALID_INDEX
			if selected_index >= 0 and _unit_manager.is_player_controlled(selected_index):
				candidate_index = selected_index
			elif not _controller._turn_queue.is_empty():
				var front_index: int = _controller._turn_queue[0]
				if _unit_manager.is_player_controlled(front_index):
					candidate_index = front_index
				else:
					print_debug("AutoBattleService: front of queue is not player controlled: index=", front_index)
			else:
				print_debug("AutoBattleService: turn queue is empty")

		if candidate_index >= 0 and _unit_manager.is_player_controlled(candidate_index):
			var unit = _unit_manager.get_unit(candidate_index)
			if is_instance_valid(unit) and unit.willpower > 0:
				_controller._current_unit_index = candidate_index
				_controller._player_turn_locked = true
				pending_unit = unit
			else:
				print_debug("AutoBattleService: candidate unit invalid or 0 willpower: index=", candidate_index)
		else:
			print_debug("AutoBattleService: could not find valid player unit candidate")

	print_debug("AutoBattleService: auto battle set ->", enabled)
	_controller.player_auto_battle_changed.emit(_enabled)

	if _enabled:
		maybe_run_turn(pending_unit)

func force_disable(reason: String = "") -> void:
	if not _enabled:
		return
	if not reason.is_empty():
		print_debug("AutoBattleService: force disabling ->", reason)
		_controller.player_auto_battle_failed.emit(reason)
	set_enabled(false)

func maybe_run_turn(unit: Unit = null) -> void:
	print_debug("AutoBattleService: maybe_run_turn requested for unit=", unit.unit_name if unit else "null")
	if not _enabled:
		print_debug("AutoBattleService: disabled; skipping auto run request")
		return
	if _in_progress:
		print_debug("AutoBattleService: already processing; ignoring new request")
		return

	var current_index := _controller.get_current_unit_index()
	if unit == null:
		if current_index == GameConstants.INVALID_INDEX or _unit_manager == null:
			print_debug("AutoBattleService: no current player unit to auto-activate")
			return
		if not _unit_manager.is_player_controlled(current_index):
			print_debug("AutoBattleService: current turn unit is not player-controlled; skipping auto run")
			return
		unit = _unit_manager.get_unit(current_index)

	if not is_instance_valid(unit) or unit.willpower <= 0:
		print_debug("AutoBattleService: active unit invalid or exhausted; cannot auto run")
		return

	print_debug("AutoBattleService: starting auto battle for current unit index=", current_index)
	_process_auto_turn(unit)

func _process_auto_turn(unit: Unit) -> void:
	_in_progress = true
	var tree = _controller.get_tree()
	if tree:
		await tree.create_timer(GameConstants.UI.AI_THINK_DELAY).timeout

	var ai_performed_action := false
	if _ai_controller and is_instance_valid(unit) and unit.willpower > 0:
		var result = await _ai_controller.execute_turn(unit)
		ai_performed_action = result if result != null else false

	if ai_performed_action and tree:
		await tree.create_timer(GameConstants.UI.AI_ACTION_DELAY).timeout

	if not is_instance_valid(unit):
		print_debug("AutoBattleService: unit became invalid after action; aborting turn processing")
		_in_progress = false
		return

	var preserve_player_turn := _should_preserve_turn(unit) if ai_performed_action else false

	if ai_performed_action or not preserve_player_turn:
		if ai_performed_action:
			_reset_attempts()
		_in_progress = false

		if not ai_performed_action:
			_record_attempt(_controller.get_current_unit_index())
			if not _attempts_exhausted() and _try_select_alternate_unit(unit):
				return
			force_disable("Auto battle disabled: AI had no actions for %s" % (unit.unit_name if unit else "unit"))
			if _unit_manager:
				_unit_manager.select_index(_controller.get_current_unit_index())
			_controller.turn_ready.emit(unit)
		elif not preserve_player_turn:
			_controller.complete_turn()
		else:
			if _unit_manager:
				_unit_manager.select_index(_controller.get_current_unit_index())
			_controller.turn_ready.emit(unit)
			if _enabled and is_instance_valid(unit) and unit.willpower > 0:
				maybe_run_turn(unit)

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

		var new_unit = _unit_manager.get_unit(candidate_index)
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
	var count = _unit_manager.get_unit_count()
	for i in range(count):
		if not _unit_manager.is_player_controlled(i):
			continue
		var candidate = _unit_manager.get_unit(i)
		if is_instance_valid(candidate) and candidate.willpower > 0:
			total_available += 1
	return total_available > 0 and _attempted_indices.size() >= total_available

func _should_preserve_turn(unit: Object) -> bool:
	if not is_instance_valid(unit) or _controller.get_current_side() != TurnSystem.Side.PLAYER:
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
