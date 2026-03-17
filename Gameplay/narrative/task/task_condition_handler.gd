class_name TaskConditionHandler
extends Object

var _task_manager: TaskManager
var _unit_manager: UnitManager

func setup(task_manager: TaskManager, unit_manager: UnitManager) -> void:
	_task_manager = task_manager
	_unit_manager = unit_manager

func check_objective_failed(objective: Resource) -> bool:
	if not objective or not _unit_manager:
		return false

	var total_units: int = _unit_manager.get_unit_count()
	if total_units == 0:
		return false

	var player_units: Array = _unit_manager.get_player_units()
	if player_units.is_empty():
		return true

	var alive_player_units: int = 0
	for u in player_units:
		if is_instance_valid(u) and u.willpower > 0:
			alive_player_units += 1

	return alive_player_units == 0

func get_player_units() -> Array[Unit]:
	var player_units: Array[Unit] = []
	if _unit_manager:
		for i in range(_unit_manager.get_unit_count()):
			var u: Unit = _unit_manager.get_unit(i)
			if u and u.faction == GameConstants.Faction.PLAYER and u.willpower > 0:
				player_units.append(u)
	return player_units

func handle_inventory_check(objective: Resource, player_units: Array[Unit]) -> void:
	if objective and objective.has_method("handle_event"):
		objective.handle_event("inventory_check", {"units": player_units})
