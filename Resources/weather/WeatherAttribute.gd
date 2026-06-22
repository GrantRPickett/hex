# Resources/weather/WeatherAttribute.gd
class_name WeatherAttribute extends Resource

@export var attribute_name: String = ""
## Localization key suffix, e.g. "shine", "shade". Used to build weather.name.X, weather.metaphor.X, weather.effect.X keys.
@export var loc_key: String = ""
@export var weather_metaphor: String = ""
@export var personality_flavor: String = ""
@export var axis_effect: String = ""
@export var color_name: String = ""
@export var notes: String = ""

# New properties for weather effects
@export_range(-1.0, 1.0, 0.1) var humidity_effect: float = 0.0 # -1.0 dry, 0.0 neutral, 1.0 wet
@export_range(-1.0, 1.0, 0.1) var temperature_effect: float = 0.0 # -1.0 cold, 0.0 neutral, 1.0 hot
@export var wind_direction: Vector2 = Vector2.ZERO # Normalized vector for wind direction
@export_range(0.0, 1.0, 0.1) var wind_intensity: float = 0.0 # 0.0 no wind, 1.0 strong wind

@export var movement_cost_modifier: float = 0.0 # Modifier to unit movement costs
@export var combat_modifier: float = 0.0 # Modifier to combat stats
@export var ai_modifier: float = 0.0 # Modifier for AI decision-making
