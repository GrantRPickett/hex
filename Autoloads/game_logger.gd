extends Node

enum Category {
	SYSTEM,
	AI,
	COMBAT,
	MAP,
	UI,
	INIT,
	TASK,
	AUDIO,
	SAVE,
	INPUT,
	NARRATIVE,
	RESOURCES,
	ACHIEVEMENTS,
	SFX,
	UNSPECIFIED
}

var category_names: Dictionary = {
	Category.SYSTEM: "SYSTEM",
	Category.AI: "AI",
	Category.COMBAT: "COMBAT",
	Category.MAP: "MAP",
	Category.UI: "UI",
	Category.INIT: "INIT",
	Category.TASK: "TASK",
	Category.AUDIO: "AUDIO",
	Category.SAVE: "SAVE",
	Category.INPUT: "INPUT",
	Category.NARRATIVE: "NARRATIVE",
	Category.RESOURCES: "RESOURCES",
	Category.ACHIEVEMENTS: "ACHIEVEMENTS",
	Category.SFX: "SFX",
	Category.UNSPECIFIED: "UNSPECIFIED"
}

var logs_enabled: bool = true

# Toggles for each category. Set to false to silence those logs.
var enabled_categories: Dictionary = {
	Category.SYSTEM: true,
	Category.AI: true,
	Category.COMBAT: true,
	Category.MAP: true,
	Category.UI: true,
	Category.INIT: true,
	Category.TASK: true,
	Category.AUDIO: true,
	Category.SAVE: true,
	Category.INPUT: true,
	Category.NARRATIVE: true,
	Category.RESOURCES: true,
	Category.ACHIEVEMENTS: true,
	Category.SFX: false,
	Category.UNSPECIFIED: true
}

const _DEF_ARG: String = "<__LOGGER_DEF__>"

func _format_msg(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) -> String:
	var arr = []
	for v in [v1, v2, v3, v4, v5, v6, v7, v8, v9, v10]:
		if typeof(v) == TYPE_STRING and v == _DEF_ARG:
			break
		arr.append(str(v))
	return "".join(arr)

func info(category: Category, v1=_DEF_ARG, v2=_DEF_ARG, v3=_DEF_ARG, v4=_DEF_ARG, v5=_DEF_ARG, v6=_DEF_ARG, v7=_DEF_ARG, v8=_DEF_ARG, v9=_DEF_ARG, v10=_DEF_ARG) -> void:
	if logs_enabled and enabled_categories.get(category, true):
		print("[%s] %s" % [category_names.get(category, "UNKNOWN"), _format_msg(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)])

func debug(category: Category, v1=_DEF_ARG, v2=_DEF_ARG, v3=_DEF_ARG, v4=_DEF_ARG, v5=_DEF_ARG, v6=_DEF_ARG, v7=_DEF_ARG, v8=_DEF_ARG, v9=_DEF_ARG, v10=_DEF_ARG) -> void:
	if logs_enabled and OS.is_debug_build() and enabled_categories.get(category, true):
		print_debug("[%s] %s" % [category_names.get(category, "UNKNOWN"), _format_msg(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)])

func warning(category: Category, v1=_DEF_ARG, v2=_DEF_ARG, v3=_DEF_ARG, v4=_DEF_ARG, v5=_DEF_ARG, v6=_DEF_ARG, v7=_DEF_ARG, v8=_DEF_ARG, v9=_DEF_ARG, v10=_DEF_ARG) -> void:
	push_warning("[%s] %s" % [category_names.get(category, "UNKNOWN"), _format_msg(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)])

func error(category: Category, v1=_DEF_ARG, v2=_DEF_ARG, v3=_DEF_ARG, v4=_DEF_ARG, v5=_DEF_ARG, v6=_DEF_ARG, v7=_DEF_ARG, v8=_DEF_ARG, v9=_DEF_ARG, v10=_DEF_ARG) -> void:
	push_error("[%s] %s" % [category_names.get(category, "UNKNOWN"), _format_msg(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)])

# Centralize Godot 4.5 Logger interception
class CustomEngineLogger extends Logger:
	func _log_message(message: String, is_error: bool) -> void:
		# Custom logic for Godot engine logs can be placed here (e.g. file writing).
		pass

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		# Custom logic for engine-level errors can be placed here.
		pass

func _init() -> void:
	if ClassDB.class_exists("Logger"):
		OS.add_logger(CustomEngineLogger.new())
