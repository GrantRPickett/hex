extends RefCounted
class_name LevelLog

static var debug_enabled: bool = true

static func set_debug(enabled: bool) -> void:
	debug_enabled = enabled

static func debug(msg: String) -> void:
	if debug_enabled:
		print_debug(msg)

static func info(msg: String) -> void:
	print(msg)

static func warn(msg: String) -> void:
	push_warning(msg)

static func error(msg: String) -> void:
	push_error(msg)
