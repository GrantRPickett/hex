# Gameplay/WeatherChangeSkill.gd
class_name WeatherChangeSkill extends Skill

@export var target_weather_attribute: WeatherAttribute

func activate(user: Unit, target: Variant) -> bool:
	if target_weather_attribute != null:
		# Assuming WeatherManager is an autoload and globally accessible
		WeatherManager.set_current_weather(target_weather_attribute)
		return true
	return false

func get_tooltip_text() -> String:
	var base_tooltip = super.get_tooltip_text()
	if target_weather_attribute:
		return base_tooltip + "\n\nChanges weather to: " + target_weather_attribute.attribute_name + "\n" + target_weather_attribute.weather_metaphor
	return base_tooltip
