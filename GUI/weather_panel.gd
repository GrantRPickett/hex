class_name WeatherPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var _current_name: RichTextLabel = %CurrentName
@onready var _current_effect: RichTextLabel = %CurrentEffect
@onready var _next_name: RichTextLabel = %NextName
@onready var _next_metaphor: RichTextLabel = %NextMetaphor
@onready var _compass_label: Label = %CompassLabel

var is_compact: bool = false
var _last_rotation_rad: float = 0.0

func _ready() -> void:
	super._ready()
	LocaleService.locale_changed.connect(_on_locale_changed)
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()
	
	if _compass_label:
		_compass_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DIRECTION_N)

	if WeatherManager:
		WeatherManager.pressures_changed.connect(_on_pressures_changed)
		WeatherManager.forecast_pressures_changed.connect(_on_forecast_changed)
		_update_ui(WeatherManager.current_pressures, false)
		_update_ui(WeatherManager.forecast_pressures, true)
	else:
		GameLogger.error(GameLogger.Category.UI, "WeatherManager not found for WeatherPanel")

func _on_locale_changed() -> void:
	if WeatherManager:
		_update_ui(WeatherManager.current_pressures, false)
		_update_ui(WeatherManager.forecast_pressures, true)
	update_compass(_last_rotation_rad)
	force_fit_content()

func _on_pressures_changed(pressures: Array[String]) -> void:
	_update_ui(pressures, false)
	force_fit_content()

func _on_forecast_changed(pressures: Array[String]) -> void:
	_update_ui(pressures, true)
	force_fit_content()

func _update_ui(pressures: Array[String], is_forecast: bool) -> void:
	var info: = WeatherManager.get_weather_info(pressures)

	if is_forecast:
		var raw_name: String = tr("hud.weather_next_round").format({"name": tr("weather." + info.name.to_lower().replace(" ", "_"))})
		_next_name.text = GameConstants.colorize_attributes(raw_name)
		# Show pressures in forecast
		if pressures.is_empty():
			_next_metaphor.text = tr("hud.weather_no_pressures")
		else:
			var capitalized_pressures: Array = []
			for p in pressures: capitalized_pressures.append(tr("attr." + p.to_lower()))
			var raw_pressures: String = tr("hud.weather_pressures").format({"pressures": ", ".join(capitalized_pressures)})
			_next_metaphor.text = GameConstants.colorize_attributes(raw_pressures)
	else:
		var raw_name: String = tr("hud.weather_current").format({"name": tr("weather." + info.name.to_lower().replace(" ", "_"))})
		_current_name.text = GameConstants.colorize_attributes(raw_name)
		
		var raw_effect = info.effects

		# Optional: add localized pressures to current display too
		if not pressures.is_empty():
			var capitalized_pressures: Array = []
			for p in pressures: capitalized_pressures.append(tr("attr." + p.to_lower()))
			raw_effect += "\n(" + ", ".join(capitalized_pressures) + ")"
		
		_current_effect.text = GameConstants.colorize_attributes(raw_effect)

func force_fit_content() -> void:
	# Resets size to minimum allowed by content
	size = Vector2.ZERO
	# custom_minimum_size = Vector2(min_width, min_height) # Inherited properly

func update_compass(rotation_rad: float) -> void:
	_last_rotation_rad = rotation_rad
	if not _compass_label:
		return

	# Convert rotation to degrees and normalize to [0, 360)
	var deg: float = fposmod(rad_to_deg(rotation_rad), 360.0)

	var directions = [
		"hud.direction_n",
		"hud.direction_ne",
		"hud.direction_se",
		"hud.direction_s",
		"hud.direction_sw",
		"hud.direction_nw"
	]
	var index: int = int(round(deg / 60.0)) % 6
	_compass_label.text = tr(directions[index])
func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	_update_font_sizes(is_portrait, viewport_size)
	_update_visibility(is_portrait, viewport_size)

func _update_font_sizes(is_portrait: bool, viewport_size: Vector2) -> void:
	var font_size = 14 if is_portrait and viewport_size.x < 500 else 18
	var small_font_size = 12 if is_portrait and viewport_size.x < 500 else 14
	
	if _current_name: _current_name.add_theme_font_size_override("normal_font_size", font_size)
	if _current_effect: _current_effect.add_theme_font_size_override("normal_font_size", small_font_size)
	if _next_name: _next_name.add_theme_font_size_override("normal_font_size", small_font_size)
	if _next_metaphor: _next_metaphor.add_theme_font_size_override("normal_font_size", small_font_size)
	if _compass_label: _compass_label.add_theme_font_size_override("font_size", font_size)

func _update_visibility(is_portrait: bool, viewport_size: Vector2) -> void:
	var sep = get_node_or_null("VBoxContainer/HSeparator")
	
	if is_compact:
		if _current_effect: _current_effect.hide()
		if _next_name: _next_name.hide()
		if _next_metaphor: _next_metaphor.hide()
		if sep: sep.hide()
	else:
		if _current_effect: _current_effect.show()
		if _next_name: _next_name.show()
		# In very tight portrait, hide forecast metaphor to save vertical space
		if _next_metaphor:
			_next_metaphor.visible = not (is_portrait and viewport_size.y < 800)
		if sep: sep.show()
