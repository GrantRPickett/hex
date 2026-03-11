class_name WeatherPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var _current_name: RichTextLabel = %CurrentName
@onready var _current_effect: RichTextLabel = %CurrentEffect
@onready var _next_name: RichTextLabel = %NextName
@onready var _next_metaphor: RichTextLabel = %NextMetaphor
@onready var _compass_label: Label = %CompassLabel

var _last_rotation_rad: float = 0.0

func _ready() -> void:
	super._ready()
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _compass_label:
		_compass_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DIRECTION_N)

	if WeatherManager:
		WeatherManager.pressures_changed.connect(_on_pressures_changed)
		WeatherManager.forecast_pressures_changed.connect(_on_forecast_changed)
		_update_ui(WeatherManager.current_pressures, false)
		_update_ui(WeatherManager.forecast_pressures, true)
	else:
		push_error("WeatherManager not found for WeatherPanel")

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
	var info = WeatherManager.get_weather_info(pressures)

	if is_forecast:
		var raw_name = tr("hud.weather_next_round").format({"name": tr("weather." + info.name.to_lower().replace(" ", "_"))})
		_next_name.text = GameConstants.Attributes.colorize_attributes(raw_name)
		# Show pressures in forecast
		if pressures.is_empty():
			_next_metaphor.text = tr("hud.weather_no_pressures")
		else:
			var capitalized_pressures = []
			for p in pressures: capitalized_pressures.append(tr("attr." + p.to_lower()))
			var raw_pressures = tr("hud.weather_pressures").format({"pressures": ", ".join(capitalized_pressures)})
			_next_metaphor.text = GameConstants.Attributes.colorize_attributes(raw_pressures)
	else:
		var raw_name = tr("hud.weather_current").format({"name": tr("weather." + info.name.to_lower().replace(" ", "_"))})
		_current_name.text = GameConstants.Attributes.colorize_attributes(raw_name)
		
		var raw_effect = info.effects

		# Optional: add localized pressures to current display too
		if not pressures.is_empty():
			var capitalized_pressures = []
			for p in pressures: capitalized_pressures.append(tr("attr." + p.to_lower()))
			raw_effect += "\n(" + ", ".join(capitalized_pressures) + ")"
		
		_current_effect.text = GameConstants.Attributes.colorize_attributes(raw_effect)

func force_fit_content() -> void:
	# Resets size to minimum allowed by content
	size = Vector2.ZERO
	# custom_minimum_size = Vector2(min_width, min_height) # Inherited properly

func update_compass(rotation_rad: float) -> void:
	_last_rotation_rad = rotation_rad
	if not _compass_label:
		return

	# Convert rotation to degrees and normalize to [0, 360)
	var deg = fposmod(rad_to_deg(rotation_rad), 360.0)

	var directions = [
		"hud.direction_n",
		"hud.direction_ne",
		"hud.direction_se",
		"hud.direction_s",
		"hud.direction_sw",
		"hud.direction_nw"
	]
	var index = int(round(deg / 60.0)) % 6
	_compass_label.text = tr(directions[index])
