# Gameplay/weather_display_ui.gd
extends Control

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var weather_name_label: Label = %WeatherNameLabel

@onready var weather_metaphor_label: Label = %WeatherMetaphorLabel
@onready var weather_effect_label: Label = %WeatherEffectLabel

func _ready():
	if WeatherManager:
		WeatherManager.weather_changed.connect(_on_weather_changed)
		_on_weather_changed(WeatherManager.get_current_weather_attribute())
	else:
		GameLogger.error(GameLogger.Category.UI, "WeatherManager is not available!")

func _on_weather_changed(new_weather_attribute: WeatherAttribute):
	if new_weather_attribute:
		var key := new_weather_attribute.loc_key
		if not key.is_empty():
			weather_name_label.text = tr("weather.name." + key)
			weather_metaphor_label.text = tr("weather.metaphor." + key)
			weather_effect_label.text = tr("weather.effect." + key)
		else:
			# Fallback for resources that haven't had loc_key set yet
			weather_name_label.text = new_weather_attribute.attribute_name
			weather_metaphor_label.text = new_weather_attribute.weather_metaphor
			weather_effect_label.text = new_weather_attribute.axis_effect
	else:
		weather_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA)
		weather_metaphor_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA)
		weather_effect_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_WEATHER_NO_ACTIVE)
