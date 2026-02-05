class_name CommandHistory
extends RefCounted

static var _history: Array[Dictionary] = []
const MAX_HISTORY := 20

static func push_snapshot(context: GameCommandContext) -> void:
	if context == null:
		return

	var snapshot := {}

	var um: UnitManager = context.unit_manager
	if is_instance_valid(um):
		snapshot["unit_manager"] = um.create_memento()

		var unit = um.get_selected_unit()
		if is_instance_valid(unit) and unit._loot_manager:
			snapshot["loot_manager"] = unit._loot_manager.create_memento()
			snapshot["loot_manager_ref"] = unit._loot_manager

	var gc: GoalController = context.goal_controller
	if is_instance_valid(gc):
		snapshot["goal_controller"] = gc.create_memento()

	_history.append(snapshot)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()

static func pop_snapshot() -> void:
	if not _history.is_empty():
		_history.pop_back()

static func undo(context: GameCommandContext) -> bool:
	if _history.is_empty():
		return false

	var snapshot = _history.pop_back()

	if snapshot.has("unit_manager") and is_instance_valid(context.unit_manager):
		context.unit_manager.restore_from_memento(snapshot["unit_manager"])

	if snapshot.has("loot_manager") and snapshot.has("loot_manager_ref"):
		var lm_ref = snapshot["loot_manager_ref"]
		if is_instance_valid(lm_ref):
			lm_ref.restore_from_memento(snapshot["loot_manager"])

	if snapshot.has("goal_controller") and is_instance_valid(context.goal_controller):
		context.goal_controller.restore_from_memento(snapshot["goal_controller"])

	return true
