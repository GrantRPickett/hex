class_name TurnController
extends Node

# AIController class is auto-global in Godot 4

signal turn_changed(unit: Unit)
signal round_changed(round_number: int)
signal turn_ready(unit: Unit)
signal ai_turn_started(unit: Unit)
signal player_auto_battle_changed(enabled: bool)
signal player_auto_battle_failed(reason: String)
signal turn_queue_updated()
signal enabled_changed(enabled: bool)

var _unit_manager: UnitManager
var _ai_controller: AIController
var _turn_queue: Array[int]:
	get: return _turn_system.get_turn_queue() if _turn_system else []
	set(value): if _turn_system: _turn_system.set_turn_queue(value)

var _current_unit_index: int:
	get: return _turn_system.get_current_unit_index() if _turn_system else GameConstants.INVALID_INDEX
	set(value): if _turn_system: _turn_system.set_current_unit_index(value)

var _current_turn_side: int:
	get: return _turn_system.get_current_side() if _turn_system else TurnSystem.Side.NEUTRAL
	set(value): if _turn_system: _turn_system.set_current_side(value)

var _round: int:
	get: return _turn_system.get_round() if _turn_system else 1
	set(value): if _turn_system: _turn_system._round = value

var _turn_system: TurnSystem
var _enabled: bool = false

var _next_starting_side: int:
	get: return _turn_system.get_next_starting_side() if _turn_system else TurnSystem.Side.PLAYER
	set(value): if _turn_system: _turn_system.set_next_starting_side(value)

var _turns_taken_this_round: Dictionary:
	get: return _turn_system._turns_taken_this_round if _turn_system else {}
	set(value): if _turn_system: _turn_system._turns_taken_this_round = value

const _SIDE_ORDER := [
	TurnSystem.Side.PLAYER,
	TurnSystem.Side.ENEMY,
	TurnSystem.Side.NEUTRAL,
]
var _auto_battle_service: AutoBattleService
var _player_turn_locked := false
var _player_auto_turn_in_progress: bool:
	get: return _auto_battle_service.is_in_progress() if _auto_battle_service else false
	set(value): pass # In-progress is managed by the service
var _checkpoint_manager: CheckpointManager
var _hud: Node
var _terrain_map

func configure_dependencies(checkpoint_manager: CheckpointManager, hud: Node, terrain_map) -> void:
	_checkpoint_manager = checkpoint_manager
	_hud = hud
	_terrain_map = terrain_map

func on_turn_changed(unit: Unit) -> void:
	# Create checkpoint
	if _checkpoint_manager and _checkpoint_manager.has_method("on_checkpoint_requested"):
		_checkpoint_manager.on_checkpoint_requested()

	# Auto-battle validation
	if is_player_auto_battle_enabled() and _unit_manager and unit:
		var idx := _unit_manager.get_unit_index(unit)
		if idx != GameConstants.INVALID_INDEX and _unit_manager.is_player_controlled(idx):
			var actions = UnitActionManager.get_available_actions(unit, _terrain_map, _unit_manager)
			var report: Dictionary = AutoBattleDiagnostics.report_unsupported_actions(unit, actions, _hud)
			var has_supported := bool(report.get("has_supported", false))
			if (actions.is_empty() or not has_supported):
				force_disable_auto_battle("Auto battle disabled: no AI-compatible actions for %s" % unit.unit_name)

func _init() -> void:
	_turn_system = TurnSystem.new()
	_auto_battle_service = AutoBattleService.new(self )
	reset()

func reset() -> void:
	_player_turn_locked = false
	_enabled = true
	_auto_battle_service.reset()


func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	_ai_controller = state.ai_controller
	if _ai_controller:
		_ai_controller.set_turn_controller(self )
	_auto_battle_service.setup(_unit_manager, _ai_controller)

func get_turn_system() -> TurnSystem:
	return _turn_system

func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		return
	_enabled = enabled
	enabled_changed.emit(enabled)

func is_enabled() -> bool:
	return _enabled

func set_player_auto_battle_enabled(enabled: bool) -> void:
	_auto_battle_service.set_enabled(enabled)

func is_player_auto_battle_enabled() -> bool:
	return _auto_battle_service.is_enabled()

func is_player_auto_control_locked() -> bool:
	return _auto_battle_service.is_in_progress()

func is_queue_empty() -> bool:
	return _turn_system.is_queue_empty()

func get_turn_queue() -> Array[int]:
	return _turn_system.get_turn_queue()

func move_index_to_front(target_index: int, list_position: int) -> void:
	_turn_system.move_index_to_front(target_index, list_position)

func set_current_unit_index(index: int) -> void:
	_turn_system.set_current_unit_index(index)

func force_disable_auto_battle(reason: String = "") -> void:
	_auto_battle_service.force_disable(reason)

func _consume_current_turn_entry() -> void:
	if _turn_queue.is_empty():
		return
	_turn_queue.pop_front()

func rebuild_turn_roster(preserve_state: bool = false) -> void:
	print_debug("TurnController: rebuilding turn roster (round=", _round, ", preserve=", preserve_state, ")")
	
	var old_queue := _turn_queue.duplicate()
	_turn_queue.clear()

	var units_by_side = _get_active_units_by_side()
	var total_active := 0
	for side in units_by_side:
		total_active += units_by_side[side].size()

	if total_active == 0:
		print_debug("TurnController: no active units found, skipping roster build.")
		_turn_queue.clear()
		return

	if preserve_state:
		var queue_was_empty = old_queue.is_empty()
		# Filter existing queue for units that are still active
		var new_queue: Array[int] = []
		for unit_idx in old_queue:
			if _is_unit_active(unit_idx):
				new_queue.append(unit_idx)
		
		# Add any new units that aren't in the queue yet
		for side in units_by_side:
			for unit_idx in units_by_side[side]:
				if not new_queue.has(unit_idx):
					new_queue.append(unit_idx)
		
		_turn_queue = new_queue
		# Don't change _current_unit_index or _current_turn_side
		print_debug("TurnController: queue preserved/updated: %s" % str(_turn_queue))
		
		# If the queue WAS empty and now isn't, we need to start the next turn
		if queue_was_empty and not _turn_queue.is_empty():
			print_debug("TurnController: queue was empty, starting next turn after preservation")
			start_next_turn()
	else:
		var start_side = _determine_start_side(units_by_side)
		_current_turn_side = start_side
		_turn_queue = _build_turn_queue(units_by_side, start_side)
		if not _turn_queue.is_empty():
			_current_unit_index = _turn_queue[0]
		else:
			_current_unit_index = GameConstants.INVALID_INDEX
		
		print_debug("TurnController: queue built: %s" % str(_turn_queue))
		_update_next_starting_side(units_by_side, start_side)

	print_debug("TurnController: roster update complete. Size=", _turn_queue.size())
	
	if not preserve_state and not _turn_queue.is_empty():
		start_next_turn()
	
	turn_queue_updated.emit()

func _is_unit_active(index: int) -> bool:
	if not _unit_manager: return false
	var unit = _unit_manager.get_unit(index)
	return is_instance_valid(unit) and unit.willpower > 0

func start_next_turn() -> void:
	print_debug("TurnController: start_next_turn() invoked. Enabled=", _enabled, " QueueSize=", _turn_queue.size())
	if not _enabled:
		print_debug("TurnController: start_next_turn skipped (disabled)")
		return

	if _turn_queue.is_empty():
		_current_turn_side = TurnSystem.Side.PLAYER
		_current_unit_index = GameConstants.INVALID_INDEX
		_player_turn_locked = false
		_start_new_round()
		return

	var next_index: int = _turn_queue[0]
	_start_unit_turn(next_index)

func _start_new_round() -> void:
	_round += 1

	# Advance weather at the start of every round
	if WeatherManager:
		WeatherManager.advance_weather()

	round_changed.emit(_round)
	print_debug("TurnController: queue empty -> next round=", _round)

	_refresh_all_units()
	_current_turn_side = TurnSystem.Side.PLAYER

	_turn_system.reset_turns_taken_this_round()

	rebuild_turn_roster()

func _start_unit_turn(index: int) -> void:
	if _unit_manager == null:
		_consume_current_turn_entry()
		return

	var unit = _unit_manager.get_unit(index)

	if not is_instance_valid(unit) or unit.willpower <= 0:
		print_debug("TurnController: skipped unit index=", index, " (invalid or 0 WP)")
		_consume_current_turn_entry()
		start_next_turn()
		return

	var side = _classify_unit_side(unit, index)
	_current_turn_side = side
	var is_player = side == TurnSystem.Side.PLAYER

	if is_player and not _auto_battle_service.is_enabled():
		_current_unit_index = GameConstants.INVALID_INDEX
		_player_turn_locked = false
	else:
		_current_unit_index = index
		_player_turn_locked = is_player

	print_debug("TurnController: turn changed -> index=", index, " player=", is_player)

	turn_changed.emit(unit)
	var selection_target = index
	if selection_target != _unit_manager.get_selected_index():
		print_debug("TurnController: forcing selection to match turn index=", selection_target)
		if _unit_manager.has_method("force_select_index"):
			_unit_manager.force_select_index(selection_target)
		else:
			_unit_manager.select_index(selection_target)
	else:
		_unit_manager.select_index(selection_target)

	if is_player:
		_auto_battle_service.reset()
		turn_ready.emit(unit)
		_auto_battle_service.maybe_run_turn(unit)
	else:
		ai_turn_started.emit(unit)
		_process_ai_turn(unit)

func _get_active_units_by_side() -> Dictionary:
	var results := {}
	for side in _SIDE_ORDER:
		results[side] = []

	var count = _unit_manager.get_unit_count()
	for i in range(count):
		var unit = _unit_manager.get_unit(i)
		if not is_instance_valid(unit) or unit.willpower <= 0:
			continue
		var side = _classify_unit_side(unit, i)
		if not results.has(side):
			results[side] = []
		results[side].append(i)

	return results

func _determine_start_side(units_by_side: Dictionary) -> int:
	var active_sides: Array[int] = []
	for side in _SIDE_ORDER:
		var entries: Array = units_by_side.get(side, [])
		if entries.size() > 0:
			active_sides.append(side)
	if active_sides.is_empty():
		return TurnSystem.Side.PLAYER
	if _round == 1:
		# Explicitly prioritize PLAYER in the first round if they have active units
		if units_by_side.get(TurnSystem.Side.PLAYER, []).size() > 0:
			return TurnSystem.Side.PLAYER
		return active_sides[0]

	var min_turns := INF
	var candidate_sides: Array[int] = []
	for side in active_sides:
		var turns = _turns_taken_this_round.get(side, 0)
		if turns < min_turns:
			min_turns = turns
			candidate_sides = [side]
		elif turns == min_turns:
			candidate_sides.append(side)

	if candidate_sides.size() == 1:
		return candidate_sides[0]
	if candidate_sides.has(_next_starting_side):
		return _next_starting_side
	return candidate_sides[0]

func _build_turn_queue(units_by_side: Dictionary, start_side: int) -> Array[int]:
	var total_units := 0
	var active_sides := []
	for side in _SIDE_ORDER:
		var side_units = units_by_side.get(side, [])
		total_units += side_units.size()
		if not side_units.is_empty():
			active_sides.append(side)
	
	var queue: Array[int] = []
	if total_units == 0:
		return queue

	var rotation = _get_side_rotation(start_side)
	# Filter rotation to only include sides that actually have units
	var active_rotation = rotation.filter(func(s): return not units_by_side.get(s, []).is_empty())
	
	if active_rotation.is_empty():
		return queue

	var consumed := {}
	for side in active_sides:
		consumed[side] = 0
		
	while queue.size() < total_units:
		var added := false
		for side in active_rotation:
			var entries: Array = units_by_side.get(side, [])
			var index: int = consumed.get(side, 0)
			if index < entries.size():
				queue.append(entries[index])
				consumed[side] = index + 1
				added = true
		if not added:
			break
	return queue

func _get_side_rotation(start_side: int) -> Array[int]:
	var rotation: Array[int] = []
	var start_index = _SIDE_ORDER.find(start_side)
	if start_index == GameConstants.INVALID_INDEX:
		start_index = 0
	for i in range(_SIDE_ORDER.size()):
		rotation.append(_SIDE_ORDER[(start_index + i) % _SIDE_ORDER.size()])
	return rotation

func _update_next_starting_side(units_by_side: Dictionary, start_side: int) -> void:
	_next_starting_side = _find_next_active_side(start_side, units_by_side)

func _find_next_active_side(current_side: int, units_by_side: Dictionary) -> int:
	var rotation = _get_side_rotation(current_side)
	for i in range(1, rotation.size()):
		var side = rotation[i]
		if units_by_side.get(side, []).size() > 0:
			return side
	return current_side

func _classify_unit_side(unit: Unit, index: int) -> int:
	if unit.faction == Unit.Faction.NEUTRAL:
		return TurnSystem.Side.NEUTRAL
	return TurnSystem.Side.PLAYER if _unit_manager.is_player_controlled(index) else TurnSystem.Side.ENEMY

func _refresh_all_units() -> void:
	if not _unit_manager:
		return
	for i in range(_unit_manager.get_unit_count()):
		var unit = _unit_manager.get_unit(i)
		if is_instance_valid(unit):
			unit.refresh_for_new_round()

func _process_ai_turn(unit: Unit) -> void:
	print_debug("TurnController: _process_ai_turn executing for ai unit=", unit.unit_name if unit else "null")
	if _ai_controller:
		# Small delay for visual clarity before AI acts
		if get_tree():
			await get_tree().create_timer(GameConstants.UI.AI_THINK_DELAY).timeout

		if is_instance_valid(unit) and unit.willpower > 0:
			print_debug("TurnController: calling AIController.execute_turn for ", unit.unit_name)
			var result = await _ai_controller.execute_turn(unit)
			if not is_instance_valid(unit):
				print_debug("TurnController: unit became invalid during AI execution")
				complete_turn()
				return
			print_debug("TurnController: AIController.execute_turn returned ", result)
			var ai_performed_action: bool = result if result != null else false
			if ai_performed_action and get_tree():
				# Delay after action before ending turn
				await get_tree().create_timer(GameConstants.UI.AI_ACTION_DELAY).timeout
	else:
		print_debug("TurnController: AI controller missing, completing turn immediately")

	# Always complete the turn — if AI had no actions, the unit simply passes
	print_debug("TurnController: AI logic done, completing turn")
	complete_turn()

func lock_active_player_unit(index: int) -> void:
	if _unit_manager == null or index < 0:
		return
	if _current_turn_side != TurnSystem.Side.PLAYER or _auto_battle_service.is_enabled():
		return
	if _turn_queue.is_empty():
		return
	var selection_pos := _turn_queue.find(index)
	if selection_pos == GameConstants.INVALID_INDEX:
		return
	var front_index: int = _turn_queue[0]
	if selection_pos != 0:
		_turn_queue[selection_pos] = front_index
		_turn_queue[0] = index
	_current_unit_index = index
	_player_turn_locked = true

func complete_player_activation(index: int) -> void:
	if index != _current_unit_index:
		return

	var unit = _unit_manager.get_unit(index)
	if unit and not unit.movement.has_move_available() and not unit.res.has_action_available():
		complete_turn()

func complete_turn() -> void:
	var side = _current_turn_side
	_consume_current_turn_entry()
	_player_turn_locked = false
	_current_unit_index = GameConstants.INVALID_INDEX
	_current_turn_side = TurnSystem.Side.PLAYER
	if _turns_taken_this_round.has(side):
		_turns_taken_this_round[side] += 1

	turn_queue_updated.emit()
	start_next_turn()

func can_act_on_index(index: int) -> bool:
	if not _enabled or _unit_manager == null or index < 0:
		print_debug("TurnController: can_act_on_index false (enabled=", _enabled, ", index=", index, ", current=", _current_unit_index, ")")
		return false
	var unit = _unit_manager.get_unit(index)
	if not is_instance_valid(unit) or unit.willpower <= 0:
		print_debug("TurnController: can_act_on_index false (unit invalid) index=", index)
		return false
	var is_player_unit := _unit_manager.is_player_controlled(index)
	if is_player_unit:
		if _current_turn_side != TurnSystem.Side.PLAYER:
			print_debug("TurnController: can_act_on_index false (not player turn side: ", _current_turn_side, ") index=", index)
			return false
		var has_entry := _turn_queue.find(index) != GameConstants.INVALID_INDEX
		if not has_entry:
			print_debug("TurnController: can_act_on_index false (unit not in queue) index=", index, " queue=", str(_turn_queue))
			return false
		if _player_turn_locked and index != _current_unit_index:
			print_debug("TurnController: can_act_on_index false (turn locked to index=", _current_unit_index, ") current index=", index)
			return false
		return true
	var ok = index == _current_unit_index
	if not ok:
		print_debug("TurnController: can_act_on_index false (enabled=", _enabled, ", index=", index, ", current=", _current_unit_index, ")")
	return ok

func get_current_unit_index() -> int:
	return _current_unit_index

func get_current_side() -> int:
	return _current_turn_side

func get_round() -> int:
	return _round

func create_memento() -> Dictionary:
	return {
		"turn_queue": _turn_queue.duplicate(),
		"current_unit_index": _current_unit_index,
		"current_turn_side": _current_turn_side,
		"round": _round,
		"next_starting_side": _next_starting_side,
		"turns_taken_this_round": _turns_taken_this_round.duplicate(),
		"enabled": _enabled,
		"player_auto_battle_enabled": _auto_battle_service.is_enabled(),
		"player_auto_turn_in_progress": _auto_battle_service.is_in_progress(),
		"player_turn_locked": _player_turn_locked
	}

func restore_from_memento(memento: Dictionary) -> void:
	_turn_queue = memento.get("turn_queue", [])
	_current_unit_index = memento.get("current_unit_index", GameConstants.INVALID_INDEX)
	_current_turn_side = memento.get("current_turn_side", TurnSystem.Side.NEUTRAL)
	_round = memento.get("round", 1)
	_next_starting_side = memento.get("next_starting_side", TurnSystem.Side.PLAYER)
	var turns_memento: Dictionary = memento.get("turns_taken_this_round", {})
	if turns_memento.is_empty():
		_turns_taken_this_round = {
			TurnSystem.Side.PLAYER: 0,
			TurnSystem.Side.ENEMY: 0,
			TurnSystem.Side.NEUTRAL: 0
		}
	else:
		_turns_taken_this_round = turns_memento.duplicate()
		if not _turns_taken_this_round.has(TurnSystem.Side.NEUTRAL):
			_turns_taken_this_round[TurnSystem.Side.NEUTRAL] = 0
	_enabled = memento.get("enabled", true)

	var auto_enabled: bool = memento.get("player_auto_battle_enabled", false)
	_auto_battle_service.set_enabled(auto_enabled)

	_player_turn_locked = memento.get("player_turn_locked", false)

	var unit: Unit = null
	if _unit_manager:
		if _current_unit_index >= 0:
			_unit_manager.select_index(_current_unit_index)
			unit = _unit_manager.get_unit(_current_unit_index)
		else:
			_unit_manager.select_index(GameConstants.INVALID_INDEX)
	turn_changed.emit(unit)
