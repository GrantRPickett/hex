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
		snapshot[GameConstants.ContextKeys.UNIT_MANAGER] = um.create_memento()

		var unit: Unit = um.get_selected_unit()
		if is_instance_valid(unit) and unit._loot_manager:
			snapshot[GameConstants.ContextKeys.LOOT_MANAGER] = unit._loot_manager.create_memento()
			snapshot["loot_manager_ref"] = unit._loot_manager # Keep ref for restoration call

	var gc: TaskController = context.task_controller
	if is_instance_valid(gc):
		snapshot[GameConstants.ContextKeys.TASK_CONTROLLER] = gc.create_memento()

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

	if snapshot.has(GameConstants.ContextKeys.UNIT_MANAGER) and is_instance_valid(context.unit_manager):
		context.unit_manager.restore_from_memento(snapshot[GameConstants.ContextKeys.UNIT_MANAGER])

	if snapshot.has(GameConstants.ContextKeys.LOOT_MANAGER) and snapshot.has("loot_manager_ref"):
		var lm_ref = snapshot["loot_manager_ref"]
		if is_instance_valid(lm_ref):
			lm_ref.restore_from_memento(snapshot[GameConstants.ContextKeys.LOOT_MANAGER])

	if snapshot.has(GameConstants.ContextKeys.TASK_CONTROLLER) and is_instance_valid(context.task_controller):
		context.task_controller.restore_from_memento(snapshot[GameConstants.ContextKeys.TASK_CONTROLLER])

	return true
