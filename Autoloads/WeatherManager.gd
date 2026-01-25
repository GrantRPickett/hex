# Autoloads/WeatherManager.gd
extends Node

signal weather_changed(new_weather_attribute)
signal weather_effect_applied(weather_attribute: WeatherAttribute)

@export var current_weather_attribute: WeatherAttribute

func _ready():
	if current_weather_attribute == null:
		set_current_weather(get_random_weather_attribute())
	else:
		# If a weather attribute is already set in the editor, apply its effects
		apply_weather_effects()

func set_current_weather(new_attribute: WeatherAttribute):
	if current_weather_attribute != new_attribute:
		current_weather_attribute = new_attribute
		weather_changed.emit(current_weather_attribute)
		print("Weather changed to: ", current_weather_attribute.attribute_name)
		apply_weather_effects() # Apply effects immediately when weather changes

func get_current_weather_attribute() -> WeatherAttribute:
	return current_weather_attribute

func get_random_weather_attribute() -> WeatherAttribute:
	var weather_attributes = [
		preload("res://Resources/weather/GritWeatherAttribute.tres"),
		preload("res://Resources/weather/FlowWeatherAttribute.tres"),
		preload("res://Resources/weather/GustoWeatherAttribute.tres"),
		preload("res://Resources/weather/ClarityWeatherAttribute.tres"),
		preload("res://Resources/weather/TemperWeatherAttribute.tres"),
		preload("res://Resources/weather/ShineWeatherAttribute.tres")
	]
	if weather_attributes.is_empty():
		push_warning("No weather attributes found to pick from!")
		return null
	return weather_attributes[randi() % weather_attributes.size()]

# Placeholder method for applying weather effects
func apply_weather_effects():
	if current_weather_attribute:
		print("Applying effects for weather: ", current_weather_attribute.attribute_name)
		print("Description: ", current_weather_attribute.axis_effect)
		weather_effect_applied.emit(current_weather_attribute) # Emit the new signal
		# TODO: Implement actual game world effect application here
		# This will involve interacting with other game systems like:
		# - Terrain (e.g., GridController, TerrainMap)
		# - Unit movement (e.g., MoveController, MovementRangeCalculator)
		# - Combat (e.g., CombatSystem)
		# - AI (e.g., AIController)
	else:
		print("No current weather attribute to apply effects for.")
