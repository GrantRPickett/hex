class_name TurnController
extends Node

# AIController class is auto-global in Godot 4

const AutoBattleDiagnostics := preload("res://Gameplay/auto_battle_diagnostics.gd")

signal turn_changed(unit: Unit)
signal round_changed(round_number: int)
signal turn_ready(unit: Unit)
signal ai_turn_started(unit: Unit)
signal player_auto_battle_changed(enabled: bool)
signal player_auto_battle_failed(reason: String)

var _unit_manager: UnitManager
var _ai_controller: AIController
var _turn_queue: Array[int]
var _current_unit_index: int
var _current_turn_side: int = TurnSystem.Side.NEUTRAL
var _round: int
var _turn_system: TurnSystem
var _enabled: bool
var _next_starting_side: int
var _consecutive_turn_counter: int
const _SIDE_ORDER := [
	TurnSystem.Side.PLAYER,
	TurnSystem.Side.ENEMY,
	TurnSystem.Side.NEUTRAL,
]

var _turns_taken_this_round: Dictionary = {
	TurnSystem.Side.PLAYER: 0,
	TurnSystem.Side.ENEMY: 0,
	TurnSystem.Side.NEUTRAL: 0
}
var _player_auto_battle_enabled := false
var _player_auto_turn_in_progress := false
var _auto_battle_attempted_indices: Array[int] = []
var _player_turn_locked := false
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
		if idx != -1 and _unit_manager.is_player_controlled(idx):
			var actions = UnitActionManager.get_available_actions(unit, _terrain_map, _unit_manager)
			var report: Dictionary = AutoBattleDiagnostics.report_unsupported_actions(unit, actions, _hud)
			var has_supported := bool(report.get("has_supported", false))
			if (actions.is_empty() or not has_supported):
				force_disable_auto_battle("Auto battle disabled: no AI-compatible actions for %s" % unit.unit_name)

func _init() -> void:
	_turn_system = TurnSystem.new(self)
	reset()

func reset() -> void:
	_turn_queue = []
	_current_unit_index = -1
	_current_turn_side = TurnSystem.Side.NEUTRAL
	_player_turn_locked = false
	_round = 1
	_enabled = true
	_next_starting_side = TurnSystem.Side.PLAYER
	_consecutive_turn_counter = 0
	_turns_taken_this_round = {
		TurnSystem.Side.PLAYER: 0,
		TurnSystem.Side.ENEMY: 0,
		TurnSystem.Side.NEUTRAL: 0
	}
	_auto_battle_attempted_indices.clear()


func setup(services: GameSessionServices, config: GameSessionBuilder.Config) -> void:
	_unit_manager = services.unit_manager
	_ai_controller = services.ai_controller
	if _ai_controller:
		_ai_controller.set_turn_controller(self)

func get_turn_system() -> TurnSystem:
	return _turn_system

func set_enabled(enabled: bool) -> void:
	_enabled = enabled

func is_enabled() -> bool:
	return _enabled

func set_player_auto_battle_enabled(enabled: bool) -> void:
	if _player_auto_battle_enabled == enabled:
		print_debug("TurnController: auto battle unchanged ->", enabled)
		return
	_player_auto_battle_enabled = enabled
	_reset_auto_battle_attempts()
	var pending_unit: Unit = null
	if _player_auto_battle_enabled and _unit_manager and _current_turn_side == TurnSystem.Side.PLAYER:
		var candidate_index := _current_unit_index
		if candidate_index == -1:
			var selected_index := _unit_manager.get_selected_index() if _unit_manager.has_method("get_selected_index") else -1
			if selected_index >= 0 and _unit_manager.is_player_controlled(selected_index):
				candidate_index = selected_index
			elif not _turn_queue.is_empty():
				var front_index: int = _turn_queue[0]
				if _unit_manager.is_player_controlled(front_index):
					candidate_index = front_index
		if candidate_index >= 0 and _unit_manager.is_player_controlled(candidate_index):
			var unit := _unit_manager.get_unit(candidate_index)
			if is_instance_valid(unit) and unit.willpower > 0:
				_current_unit_index = candidate_index
				_player_turn_locked = true
				pending_unit = unit
	print_debug("TurnController: auto battle set ->", enabled)
	player_auto_battle_changed.emit(_player_auto_battle_enabled)
	if _player_auto_battle_enabled:
		_maybe_run_player_auto_turn(pending_unit)

func is_player_auto_battle_enabled() -> bool:
	return _player_auto_battle_enabled

func is_player_auto_control_locked() -> bool:
	return _player_auto_turn_in_progress

func force_disable_auto_battle(reason: String = "") -> void:
	if not _player_auto_battle_enabled:
		return
	if not reason.is_empty():
		print_debug("TurnController: force disabling auto battle ->", reason)
		player_auto_battle_failed.emit(reason)
	set_player_auto_battle_enabled(false)

func _reset_auto_battle_attempts() -> void:
	_auto_battle_attempted_indices.clear()

func _record_auto_battle_attempt(index: int) -> void:
	if index >= 0 and not _auto_battle_attempted_indices.has(index):
		_auto_battle_attempted_indices.append(index)

func _auto_battle_attempts_exhausted() -> bool:
	if _unit_manager == null:
		return false
	var total_available := 0
	var count = _unit_manager.get_unit_count()
	for i in range(count):
		if not _unit_manager.is_player_controlled(i):
			continue
		var candidate = _unit_manager.get_unit(i)
		if not is_instance_valid(candidate):
			continue
		if candidate.willpower <= 0:
			continue
		total_available += 1
	return total_available > 0 and _auto_battle_attempted_indices.size() >= total_available

func _consume_current_turn_entry() -> void:
	if _turn_queue.is_empty():
		return
	_turn_queue.pop_front()

func rebuild_turn_roster() -> void:
	print_debug("TurnController: rebuilding turn roster (round=", _round, ")")
	_turn_queue.clear()

	var units_by_side = _get_active_units_by_side()
	var start_side = _determine_start_side(units_by_side)
	_turn_queue = _build_turn_queue(units_by_side, start_side)
	_update_next_starting_side(units_by_side, start_side)

	print_debug("TurnController: queue built size=", _turn_queue.size(), " start_side=", start_side, " next_starting_side=", _next_starting_side, " consec=", _consecutive_turn_counter)

	if not _turn_queue.is_empty():
		start_next_turn()

func start_next_turn() -> void:
	if not _enabled:
		print_debug("TurnController: start_next_turn skipped (disabled)")
		return

	if _turn_queue.is_empty():
		_current_turn_side = TurnSystem.Side.NEUTRAL
		_current_unit_index = -1
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
	_current_turn_side = TurnSystem.Side.NEUTRAL

	# Reset turn counters for the new round
	_turns_taken_this_round[TurnSystem.Side.PLAYER] = 0
	_turns_taken_this_round[TurnSystem.Side.ENEMY] = 0
	_turns_taken_this_round[TurnSystem.Side.NEUTRAL] = 0

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

	if is_player and not _player_auto_battle_enabled:
		_current_unit_index = -1
		_player_turn_locked = false
	else:
		_current_unit_index = index
		_player_turn_locked = is_player

	print_debug("TurnController: turn changed -> index=", index, " player=", is_player)

	turn_changed.emit(unit)
	if _unit_manager:
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
		_reset_auto_battle_attempts()
		turn_ready.emit(unit)
		_maybe_run_player_auto_turn(unit)
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
	for side in _SIDE_ORDER:
		total_units += units_by_side.get(side, []).size()
	var queue: Array[int] = []
	if total_units == 0:
		return queue

	var rotation = _get_side_rotation(start_side)
	var consumed := {}
	for side in _SIDE_ORDER:
		consumed[side] = 0
	while queue.size() < total_units:
		var added := false
		for side in rotation:
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
	if start_index == -1:
		start_index = 0
	for i in range(_SIDE_ORDER.size()):
		rotation.append(_SIDE_ORDER[(start_index + i) % _SIDE_ORDER.size()])
	return rotation

func _update_next_starting_side(units_by_side: Dictionary, start_side: int) -> void:
	var start_count = units_by_side.get(start_side, []).size()
	var largest_other := 0
	for side in _SIDE_ORDER:
		if side == start_side:
			continue
		largest_other = max(largest_other, units_by_side.get(side, []).size())
	var diff = start_count - largest_other
	if diff != 0:
		_consecutive_turn_counter += abs(diff)
	var next_side = _find_next_active_side(start_side, units_by_side)
	_next_starting_side = next_side

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

func _process_ai_turn(unit: Unit, is_player_auto: bool = false) -> void:
	print_debug("TurnController: _process_ai_turn begin auto=%s unit=%s" % [str(is_player_auto), unit and unit.unit_name])
	if is_player_auto:
		_player_auto_turn_in_progress = true
		print_debug("TurnController: auto battle executing unit=", unit.unit_name if unit else "null")
	var ai_performed_action: bool = false
	var should_complete_turn := true
	var preserve_player_turn := false
	if _ai_controller:
		# Small delay for visual clarity before AI acts
		await get_tree().create_timer(0.5).timeout

		if is_instance_valid(unit) and unit.willpower > 0:
			var result = await _ai_controller.execute_turn(unit)
			ai_performed_action = result if result != null else false

		if ai_performed_action:
			# Delay after action before ending turn
			await get_tree().create_timer(0.2).timeout
		else:
			should_complete_turn = false
	else:
		print_debug("TurnController: AI controller missing, completing turn immediately")
	if is_player_auto and ai_performed_action:
		preserve_player_turn = _should_preserve_player_auto_turn(unit)
	if should_complete_turn and not preserve_player_turn:
		complete_turn()
	elif preserve_player_turn:
		print_debug("TurnController: preserving player auto turn for free roam unit")
	if ai_performed_action:
		_reset_auto_battle_attempts()
	if is_player_auto:
		print_debug("TurnController: auto battle turn finished for unit=", unit.unit_name if unit else "null")
		_player_auto_turn_in_progress = false
		if not ai_performed_action:
			_record_auto_battle_attempt(_current_unit_index)
			var attempts_exhausted := _auto_battle_attempts_exhausted()
			if not attempts_exhausted and _try_auto_select_alternate_unit(unit):
				return
			force_disable_auto_battle("Auto battle disabled: AI had no actions for %s" % (unit.unit_name if unit else "unit"))
			if _unit_manager:
				_unit_manager.select_index(_current_unit_index)
			turn_ready.emit(unit)
	print_debug("TurnController: _process_ai_turn complete auto=%s performed=%s" % [str(is_player_auto), str(ai_performed_action)])

func _should_preserve_player_auto_turn(unit: Unit) -> bool:
	if unit == null:
		return false
	if _current_turn_side != TurnSystem.Side.PLAYER:
		return false
	if not unit.has_method("is_in_free_roam_mode"):
		return false
	return unit.is_in_free_roam_mode()

func lock_active_player_unit(index: int) -> void:
	if _unit_manager == null or index < 0:
		return
	if _current_turn_side != TurnSystem.Side.PLAYER or _player_auto_battle_enabled:
		return
	if _turn_queue.is_empty():
		return
	var selection_pos := _turn_queue.find(index)
	if selection_pos == -1:
		return
	var front_index: int = _turn_queue[0]
	if selection_pos != 0:
		_turn_queue[selection_pos] = front_index
		_turn_queue[0] = index
	_current_unit_index = index
	_player_turn_locked = true

func _maybe_run_player_auto_turn(unit: Unit = null) -> void:
	if not _player_auto_battle_enabled:
		print_debug("TurnController: auto battle disabled; skipping auto run request")
		return
	if _player_auto_turn_in_progress:
		print_debug("TurnController: auto battle already processing; ignoring new request")
		return
	if unit == null:
		if _current_unit_index == -1 or _unit_manager == null:
			print_debug("TurnController: no current player unit to auto-activate")
			return
		if not _unit_manager.is_player_controlled(_current_unit_index):
			print_debug("TurnController: current turn unit is not player-controlled; skipping auto run")
			return
		unit = _unit_manager.get_unit(_current_unit_index)
	if not is_instance_valid(unit) or unit.willpower <= 0:
		print_debug("TurnController: active unit invalid or exhausted; cannot auto run")
		return
	print_debug("TurnController: starting auto battle for current unit index=", _current_unit_index)
	_process_ai_turn(unit, true)

func _try_auto_select_alternate_unit(current_unit: Unit) -> bool:
	if _unit_manager == null or _turn_queue.is_empty():
		return false
	var current_is_player := _current_unit_index != -1 and _unit_manager.is_player_controlled(_current_unit_index)
	var front_index: int = _turn_queue[0]
	for i in range(1, _turn_queue.size()):
		var candidate_index: int = _turn_queue[i]
		if _unit_manager.is_player_controlled(candidate_index) != current_is_player:
			continue
		if _auto_battle_attempted_indices.has(candidate_index):
			continue
		_turn_queue[i] = front_index
		_turn_queue[0] = candidate_index
		_current_unit_index = candidate_index
		var new_unit = _unit_manager.get_unit(candidate_index)
		_unit_manager.select_index(candidate_index)
		print_debug("TurnController: switching auto battle to alternate unit index=", candidate_index)
		turn_ready.emit(new_unit)
		if _player_auto_battle_enabled:
			_maybe_run_player_auto_turn(new_unit)
		return true
	return false

func complete_player_activation(index: int) -> void:
	if index != _current_unit_index:
		return

	var unit = _unit_manager.get_unit(index)
	if unit and not unit.has_move_available() and not unit.has_action_available():
		complete_turn()

func complete_turn() -> void:
	var side = _current_turn_side
	_consume_current_turn_entry()
	_player_turn_locked = false
	_current_unit_index = -1
	_current_turn_side = TurnSystem.Side.NEUTRAL
	if _turns_taken_this_round.has(side):
		_turns_taken_this_round[side] += 1

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
			print_debug("TurnController: can_act_on_index false (not player turn) index=", index)
			return false
		var has_entry := _turn_queue.find(index) != -1
		if not has_entry:
			print_debug("TurnController: can_act_on_index false (unit already acted) index=", index)
			return false
		if _player_turn_locked and index != _current_unit_index:
			print_debug("TurnController: can_act_on_index false (turn locked to index=", _current_unit_index, ")")
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
		"consecutive_turn_counter": _consecutive_turn_counter,
		"turns_taken_this_round": _turns_taken_this_round.duplicate(),
		"enabled": _enabled,
		"player_auto_battle_enabled": _player_auto_battle_enabled,
		"player_auto_turn_in_progress": _player_auto_turn_in_progress,
		"player_turn_locked": _player_turn_locked
	}

func restore_from_memento(memento: Dictionary) -> void:
	_turn_queue = memento.get("turn_queue", [])
	_current_unit_index = memento.get("current_unit_index", -1)
	_current_turn_side = memento.get("current_turn_side", TurnSystem.Side.NEUTRAL)
	_round = memento.get("round", 1)
	_next_starting_side = memento.get("next_starting_side", TurnSystem.Side.PLAYER)
	_consecutive_turn_counter = memento.get("consecutive_turn_counter", 0)
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
	var previous_auto_state := _player_auto_battle_enabled
	_player_auto_battle_enabled = auto_enabled
	_player_auto_turn_in_progress = false
	_player_turn_locked = memento.get("player_turn_locked", false)
	if previous_auto_state != _player_auto_battle_enabled:
		player_auto_battle_changed.emit(_player_auto_battle_enabled)
	var unit: Unit = null
	if _unit_manager:
		if _current_unit_index >= 0:
			_unit_manager.select_index(_current_unit_index)
			unit = _unit_manager.get_unit(_current_unit_index)
		else:
			_unit_manager.select_index(-1)
	turn_changed.emit(unit)
