extends Node

# --- Configuration ---
# Map of locale codes to font resource paths
# Standardize on a main font that supports multiple sets if possible, 
# or swap here for JP/KR/etc.
const FONT_MAP = {
	"en": "res://Resources/Fonts/DefaultFont.ttf",
	"es": "res://Resources/Fonts/DefaultFont.ttf",
}

signal locale_changed()

func _ready() -> void:
	# Initial application
	apply_locale_settings()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		apply_locale_settings()

func apply_locale_settings() -> void:
	var current_locale: String = TranslationServer.get_locale().left(2)
	GameLogger.debug(GameLogger.Category.SYSTEM, "[LocaleService] Applying settings for: ", current_locale)
	
	_apply_font_for_locale(current_locale)
	locale_changed.emit()

func _apply_font_for_locale(locale: String) -> void:
	var font_path = FONT_MAP.get(locale, FONT_MAP["en"])
	if not ResourceLoader.exists(font_path):
		return
		
	var font: Resource = load(font_path)
	if font:
		# Option A: Update the default project theme if you have one
		# var theme = Gui.get_default_theme() 
		
		# Option B: (Naïve but effective) - We could emit a signal 
		# that important UI elements listen to if they need custom font handling
		pass
