class_name UnitController
extends Node

var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _combat_system: Node
var _grid: Node2D

func configure_dependencies(loot_manager: LootManager, task_manager: TaskManager, combat_system: Node, grid: Node2D) -> void:
	_loot_manager = loot_manager
	_task_manager = task_manager
	_combat_system = combat_system
	_grid = grid

func on_unit_spawn_requested(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return

	unit.set_unit_manager(_unit_manager)
	if _loot_manager:
		unit.set_loot_manager(_loot_manager)
	if _task_manager:
		unit.set_task_manager(_task_manager)
	if _combat_system:
		unit.set_combat_system(_combat_system)

	if _grid:
		unit.grid_map = _grid
		unit.snap_to_grid()


func setup() -> void:
	_unit_manager = UnitManager.new()

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
