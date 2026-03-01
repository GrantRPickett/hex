extends RefCounted
class_name LevelAutoFixOptions

var enabled: bool = false
# Use user:// for writeable path across OS/exported builds
var report_path: String = "user://reports/level_autofix.json"
var write_report: bool = true

# Per-section toggles (default on when enabled)
var fix_locations: bool = true
var fix_player_starts: bool = true
var fix_neutral_starts: bool = true
var fix_dialogues: bool = true
