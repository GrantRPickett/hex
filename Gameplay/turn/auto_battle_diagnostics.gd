class_name AutoBattleDiagnostics
extends RefCounted

static var _unsupported_history: Array[Dictionary] = []

static func report_unsupported_actions(unit: Unit, actions: Array, hud: Node = null) -> Dictionary:
	var summary: Dictionary = {
		"warnings": [],
		"has_supported": false
	}
	if actions == null or actions.is_empty():
		return summary
	var unit_name : String = "Unknown"
	if unit and unit.unit_name != null:
		unit_name = String(unit.unit_name)
	var warnings := summary["warnings"] as Array

	for action in actions:
		var action_type : int = -1
		var action_type_str: String = ""
		
		if action is PlayerAction:
			var ua: PlayerAction = action
			action_type = int(ua.type)
			action_type_str = GameConstants.ActionType.keys()[action_type].to_lower()
		elif action is Dictionary:
			action_type = int(action.get("type", -1))
			action_type_str = String(action.get("type_str", "")).to_lower()
			if action_type_str.is_empty() and action_type >= 0:
				action_type_str = GameConstants.ActionType.keys()[action_type].to_lower()

		if action_type_str.is_empty() or action_type == -1:
			continue

		# Define AI-compatible actions
		var is_supported := false
		match action_type:
			GameConstants.ActionType.WAIT, \
			GameConstants.ActionType.FIGHT, \
			GameConstants.ActionType.CONVINCE, \
			GameConstants.ActionType.GATHER, \
			GameConstants.ActionType.TRAPPED, \
			GameConstants.ActionType.EXPLORE, \
			GameConstants.ActionType.VISIT, \
			GameConstants.ActionType.AID, \
			GameConstants.ActionType.SKILL, \
			GameConstants.ActionType.INTERACT, \
			GameConstants.ActionType.MOVE_AND_INTERACT, \
			GameConstants.ActionType.OPEN_ATTACK_MENU:
				is_supported = true
		
		if is_supported:
			summary["has_supported"] = true
			continue

		var message : String = "Auto battle cannot run '%s' for: %s" % [action_type_str, unit_name]
		var warning : Dictionary = {
			"unit_name": unit_name,
			"action_type": action_type_str,
			"message": message
		}
		warnings.append(warning)
		_unsupported_history.append(warning)
		GameLogger.debug(GameLogger.Category.SYSTEM, "AutoBattleDiagnostics: ", message)
		if hud and hud.has_method("show_warning_message"):
			hud.show_warning_message(message)
	return summary

static func get_unsupported_history() -> Array[Dictionary]:
	return _unsupported_history.duplicate(true)
