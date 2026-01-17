class_name UnitController
extends Node

var _unit_manager: UnitManager

func setup() -> void:
	_unit_manager = UnitManager.new()
	add_child(_unit_manager)

func get_unit_manager() -> UnitManager:
	return _unit_manager

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	_unit_manager.add_unit(unit, coord, is_player)
	set_coord(_unit_manager.get_unit_count() - 1, coord)

func set_coord(index: int, coord: Vector2i) -> void:
	_unit_manager.set_coord(index, coord)

func set_player_controlled(index: int, is_player: bool) -> void:
	_unit_manager.set_player_controlled(index, is_player)
	if index == _unit_manager.get_selected_index() and not is_player:
		_unit_manager.cycle_selection(1)

