class_name UnitController
extends Node

var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _combat_system: Node
var _grid: Node2D

func configure_dependencies(services: GameSessionServices, config: GameSessionBuilder.Config) -> void:
	_loot_manager = services.loot_manager
	_task_manager = services.task_manager
	_combat_system = services.combat_system
	_grid = config.grid




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
