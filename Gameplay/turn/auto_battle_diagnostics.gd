class_name AutoBattleDiagnostics
extends RefCounted

const SUPPORTED_ACTION_TYPES: Dictionary = {
	"move": true,
	"wait": true,
	"attack": true,
	"open_attack_menu": true,
	"aid": true,
	"loot": true,
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

static func report_unsupported_actions(unit: Unit, actions: Array[Dictionary], hud: Node = null) -> Dictionary:
	var summary: Dictionary = {
		"warnings": [],
		"has_supported": false
	}
	if actions == null:
		return summary
	var unit_name := "Unknown"
	if unit and unit.unit_name != null:
		unit_name = String(unit.unit_name)
	var warnings := summary["warnings"] as Array
	for action in actions:
		var action_type := String(action.get("type", ""))
		if action_type.is_empty():
			continue
		
		# Clean up any potential whitespace/formatting issues
		action_type = action_type.strip_edges()
		
		if SUPPORTED_ACTION_TYPES.has(action_type):
			summary["has_supported"] = true
			continue
		
		var message := "Auto battle cannot run '%s' for %s (Supported: %s)" % [action_type, unit_name, SUPPORTED_ACTION_TYPES.keys()]
		var warning := {
			"unit_name": unit_name,
			"action_type": action_type,
			"message": message
		}
		warnings.append(warning)
		_unsupported_history.append(warning)
		print_debug("AutoBattleDiagnostics: ", message)
		if hud and hud.has_method("show_warning_message"):
			hud.show_warning_message(message)
	return summary

static func get_unsupported_history() -> Array[Dictionary]:
	return _unsupported_history.duplicate(true)
