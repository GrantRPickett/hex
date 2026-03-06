class_name WeatherPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var _current_name: Label = %CurrentName
@onready var _current_effect: Label = %CurrentEffect
@onready var _next_name: Label = %NextName
@onready var _next_metaphor: Label = %NextMetaphor
@onready var _compass_label: Label = %CompassLabel

func _ready() -> void:
	super._ready()
	if _compass_label:
		_compass_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DIRECTION_N)

	if WeatherManager:
		WeatherManager.pressures_changed.connect(_on_pressures_changed)
		WeatherManager.forecast_pressures_changed.connect(_on_forecast_changed)
		_update_ui(WeatherManager.current_pressures, false)
		_update_ui(WeatherManager.forecast_pressures, true)
	else:
		push_error("WeatherManager not found for WeatherPanel")

func _on_pressures_changed(pressures: Array[String]) -> void:
	_update_ui(pressures, false)
	force_fit_content()

func _on_forecast_changed(pressures: Array[String]) -> void:
	_update_ui(pressures, true)
	force_fit_content()

func _update_ui(pressures: Array[String], is_forecast: bool) -> void:
	var info = WeatherManager.get_weather_info(pressures)

	if is_forecast:
		_next_name.text = LocalizationStrings.get_text(LocalizationStrings.HUD_WEATHER_NEXT_ROUND).format({"name": info.name})
		_next_metaphor.text = info.effects # Or metaphors if I added them to get_weather_info
		# Show pressures in forecast
		if pressures.is_empty():
			_next_metaphor.text = LocalizationStrings.get_text(LocalizationStrings.HUD_WEATHER_NO_PRESSURES)
		else:
			_next_metaphor.text = LocalizationStrings.get_text(LocalizationStrings.HUD_WEATHER_PRESSURES).format({"pressures": ", ".join(pressures).capitalize()})
	else:
		_current_name.text = LocalizationStrings.get_text(LocalizationStrings.HUD_WEATHER_CURRENT).format({"name": info.name})
		_current_effect.text = info.effects


		# Optional: add flavor text or pressures to current display too
		if not pressures.is_empty():
			_current_effect.text += "\n(" + ", ".join(pressures).capitalize() + ")"

func force_fit_content() -> void:
	# Resets size to minimum allowed by content
	size = Vector2.ZERO
	# custom_minimum_size = Vector2(min_width, min_height) # Inherited properly

func update_compass(rotation_rad: float) -> void:
	if not _compass_label:
		return

	# Convert rotation to degrees and normalize to [0, 360)
	var deg = fposmod(rad_to_deg(rotation_rad), 360.0)

	# Hex rotation is in 60 degree steps
	# 0: N, 60: NE, 120: SE, 180: S, 240: SW, 300: NW
	# (Adjusted based on standard hex orientation where 0 rad is often East, but TAU/6 is 60 deg)

	var directions = [
		LocalizationStrings.HUD_DIRECTION_N,
		LocalizationStrings.HUD_DIRECTION_NE,
		LocalizationStrings.HUD_DIRECTION_SE,
		LocalizationStrings.HUD_DIRECTION_S,
		LocalizationStrings.HUD_DIRECTION_SW,
		LocalizationStrings.HUD_DIRECTION_NW
	]
	var index = int(round(deg / 60.0)) % 6
	_compass_label.text = LocalizationStrings.get_text(directions[index])
