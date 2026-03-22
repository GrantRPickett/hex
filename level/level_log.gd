extends RefCounted
class_name LevelLog

static var debug_enabled: bool = true

static func set_debug(enabled: bool) -> void:
	debug_enabled = enabled

static func debug(msg: String) -> void:
	if debug_enabled:
		GameLogger.debug(GameLogger.Category.MAP, msg)

static func info(msg: String) -> void:
	GameLogger.info(GameLogger.Category.MAP, msg)

static func warn(msg: String) -> void:
	GameLogger.warning(GameLogger.Category.MAP, msg)

static func error(msg: String) -> void:
	GameLogger.error(GameLogger.Category.MAP, msg)
