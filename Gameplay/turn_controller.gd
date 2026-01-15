class_name TurnController
extends Node

var _turn_system: TurnSystem
var _unit_manager: UnitManager
var _use_turn_system := true

func setup(unit_manager: UnitManager) -> void:
	_turn_system = TurnSystem.new()
	add_child(_turn_system)
	_turn_system.set_initial_side(TurnSystem.Side.PLAYER)
	_unit_manager = unit_manager

func set_enabled(enabled: bool) -> void:
	_use_turn_system = enabled
	if _use_turn_system:
		rebuild_turn_roster()

func is_enabled() -> bool:
	return _use_turn_system

func complete_player_activation(unit_index: int) -> void:
	if not _use_turn_system or not is_instance_valid(_turn_system):
		return
	_turn_system.mark_unit_acted(unit_index)
	_consume_other_faction_turns()
	_select_next_available_player()

func can_act_on_index(index: int) -> bool:
	if not _use_turn_system or not is_instance_valid(_turn_system):
		return true
	if _turn_system.get_active_side() != TurnSystem.Side.PLAYER:
		return false
	return _turn_system.can_unit_act(index)

func rebuild_turn_roster() -> void:
	if not _use_turn_system or not is_instance_valid(_turn_system):
		return
	var player_indexes: Array[int] = []
	var other_indexes: Array[int] = []
	for i in range(_unit_manager.get_unit_count()):
		if _unit_manager.is_player_controlled(i):
			player_indexes.append(i)
		else:
			other_indexes.append(i)
	_turn_system.configure(player_indexes, other_indexes)
	_select_next_available_player()

func _consume_other_faction_turns() -> void:
	if not _use_turn_system or not is_instance_valid(_turn_system):
		return
	while _turn_system.get_active_side() == TurnSystem.Side.OTHER:
		var other_available: Array = _turn_system.get_available_indexes(TurnSystem.Side.OTHER)
		if other_available.is_empty():
			break
		_turn_system.mark_unit_acted(other_available[0])

func _select_next_available_player() -> void:
	if not _use_turn_system or not is_instance_valid(_turn_system):
		return
	var available: Array = _turn_system.get_available_indexes(TurnSystem.Side.PLAYER)
	if available.is_empty():
		return
	var current_selection := _unit_manager.get_selected_index()
	if available.has(current_selection):
		return
	_unit_manager.select_index(available[0])

func get_turn_system() -> TurnSystem:
	return _turn_system