class_name AutoBattleDiagnostics
extends RefCounted

const SUPPORTED_ACTION_TYPES: Dictionary = {
	"move": true,
	"wait": true,
	"attack": true,
	"open_attack_menu": true,
	"aid": true,
	"loot": true,
	"gather": true,
	"skill": true,
	"talk": true,
	"move_and_interact": true,
	"explore": true,
	"visit": true,
	"trapped": true,
	"convince": true,
	"move_to_task": true,
	"move_to_enemy": true,
	"move_to_loot": true,
	"move_to_talk": true,
	"move_to_convince": true,
	"move_to_center": true
}

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
		var action_type_str: String = ""
		if action is PlayerAction:
			var ua: PlayerAction = action
			action_type_str = GameConstants.ActionType.keys()[int(ua.type)].to_lower()
		elif action is Dictionary:
			action_type_str = String(action.get("type", "")).to_lower()

		if action_type_str.is_empty():
			continue

		if SUPPORTED_ACTION_TYPES.has(action_type_str):
			summary["has_supported"] = true
			continue

		var message := "Auto battle cannot run '%s' for %s (Supported: %s)" % [action_type_str, unit_name, SUPPORTED_ACTION_TYPES.keys()]
		var warning := {
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
