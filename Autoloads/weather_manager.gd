# Autoloads/WeatherManager.gd
#class_name WeatherManager
extends Node

signal pressures_changed(current_pressures)
signal forecast_pressures_changed(forecast_pressures)
signal weather_effect_applied(weather_info)
signal weather_changed(new_weather_attribute: WeatherAttribute)

const Attributes = GameConstants.Attributes

# OPPOSITES moved to GameConstants static logic

var current_pressures: Array[String] = []
var forecast_pressures: Array[String] = []

var _channeling_unit: Unit = null

func is_hard_mode() -> bool:
	var config = get_node_or_null("/root/GameConfig")
	if not is_instance_valid(config):
		return false
	var diff = config.get_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, GameConstants.Settings.DIFFICULTY_NORMAL)
	return diff == GameConstants.Settings.DIFFICULTY_HARD

func _ready() -> void:
	# Start with a random background pressure perhaps?
	# Or just temperate. Notes w1 says "Calm skies mean nothing is pushing the system."
	# Let's start temperate.
	pass

func add_pressure(pressure: String, to_forecast: bool = true) -> void:
	var list = forecast_pressures if to_forecast else current_pressures

	# 1. Opposites cancel out
	var opposite = GameConstants.get_opposite_name(pressure)
	if opposite != pressure and list.has(opposite):
		list.erase(opposite)
		_notify_changed(to_forecast)
		return

	# 2. Reinforce or Add
	if list.has(pressure):
		# Already present, reinforcing doesn't change the list but might be relevant for logic
		return

	# 3. Add and Limit based on difficulty
	if not is_hard_mode():
		# Basic mode: only one pressure at a time
		list.clear()
		list.append(pressure)
	else:
		# Hard mode: original combo logic (up to 2)
		list.append(pressure)
		if list.size() > 2:
			list.remove_at(0) # Oldest pressure fades

	_notify_changed(to_forecast)

func remove_pressure(pressure: String, from_forecast: bool = true) -> void:
	var list = forecast_pressures if from_forecast else current_pressures
	if list.has(pressure):
		list.erase(pressure)
		_notify_changed(from_forecast)

## Sets the current pressures directly, clearing existing ones first.
func set_current_pressures(pressures: Array[String]) -> void:
	current_pressures.clear()
	for p in pressures:
		current_pressures.append(p.to_lower())
	_notify_changed(false)

func clear_pressures(forecast_only: bool = true) -> void:
	if forecast_only:
		forecast_pressures.clear()
		_notify_changed(true)
	else:
		current_pressures.clear()
		_notify_changed(false)

func _notify_changed(forecast: bool) -> void:
	if forecast:
		forecast_pressures_changed.emit(forecast_pressures)
	else:
		pressures_changed.emit(current_pressures)
		apply_weather_effects()

func advance_weather() -> void:
	# Round persistence rule: "Weather persists until changed."
	# "Channeling sets the next round's weather."
	# This implies if a unit channeled, we update.
	# If no one channeled, current stays same?
	# w2 says: "If no one interferes, tomorrow’s weather will be the same as today’s."
	if _channeling_unit != null:
		# If channeler is still valid/alive, apply the forecast
		if _channeling_unit.willpower > 0:
			current_pressures = forecast_pressures.duplicate()
			pressures_changed.emit(current_pressures)
			apply_weather_effects()

		# Clear channeling status
		_channeling_unit = null
	# Note: If no one channeled, we don't clear forecast_pressures
	# but we also don't randomise it according to "weather persists".
	# Wait, w2 says "Persistence: Weather persists until changed... tomorrow's weather will be same as today's."
	# So advance_weather only updates current if something was channeled.

func start_channeling(unit: Unit) -> bool:
	# w2: "Only one unit may channel weather at a time... cross all factions."
	if _channeling_unit != null:
		return false

	_channeling_unit = unit
	# Initialize forecast with current if it's the first channel of the round?
	# Or just let them modify the existing forecast.
	if forecast_pressures.is_empty() and not current_pressures.is_empty():
		forecast_pressures = current_pressures.duplicate()
		forecast_pressures_changed.emit(forecast_pressures)

	return true

func get_channeling_unit() -> Unit:
	return _channeling_unit

func create_memento(unit_manager: Node = null) -> Dictionary:
	var channel_index := -1
	var um: UnitManager = unit_manager if is_instance_valid(unit_manager) else get_node_or_null("/root/UnitManager")
	if is_instance_valid(_channeling_unit) and is_instance_valid(um):
		channel_index = um.get_unit_index(_channeling_unit)

	return {
		"current_pressures": current_pressures.duplicate(),
		"forecast_pressures": forecast_pressures.duplicate(),
		"channeling_unit_index": channel_index
	}

func restore_from_memento(memento: Dictionary, unit_manager: Node = null) -> void:
	var stored_current: Array[String] = memento.get("current_pressures", [])
	var stored_forecast: Array[String] = memento.get("forecast_pressures", [])
	current_pressures = stored_current.duplicate()
	forecast_pressures = stored_forecast.duplicate()

	_channeling_unit = null
	var channel_index: int = memento.get("channeling_unit_index", -1)
	var um: UnitManager = unit_manager if is_instance_valid(unit_manager) else get_node_or_null("/root/UnitManager")
	if is_instance_valid(um) and channel_index >= 0:
		var candidate: Unit = um.get_unit(channel_index)
		if is_instance_valid(candidate):
			_channeling_unit = candidate

	pressures_changed.emit(current_pressures)
	forecast_pressures_changed.emit(forecast_pressures)
	apply_weather_effects()

const WEATHER_COMBOS := {
	[Attributes.GRIT, Attributes.SHINE]: {"name": GameConstants.Weather.PARCHED, "effects": "Fatigue rises, fire spreads, water use up."},
	[Attributes.FLOW, Attributes.SHINE]: {"name": GameConstants.Weather.MUGGY, "effects": "Stamina recovery reduced, morale pressure."},
	[Attributes.GRIT, Attributes.SHADE]: {"name": GameConstants.Weather.OVERCAST, "effects": "Reduced light and visibility, cooler."},
	[Attributes.FLOW, Attributes.SHADE]: {"name": GameConstants.Weather.DRIZZLE, "effects": "Slick ground, fire suppressed."},
	[Attributes.GUSTO, Attributes.SHINE]: {"name": GameConstants.Weather.HOT_WINDS, "effects": "Rapid fatigue, fire spread, forced move."},
	[Attributes.GUSTO, Attributes.SHADE]: {"name": GameConstants.Weather.COLD_WINDS, "effects": "Morale drain, heat loss, precision penalty."},
	[Attributes.FLOW, Attributes.GUSTO]: {"name": GameConstants.Weather.STORM_WINDS, "effects": "Lightning risk, heavy visibility loss."},
	[Attributes.GRIT, Attributes.GUSTO]: {"name": GameConstants.Weather.DUST_STORM, "effects": "Severe visibility reduction, move penalty."}
}

const WEATHER_METADATA := {
	GameConstants.Weather.PARCHED: {"humidity": - 0.8, "temp": 0.8, "metaphor": "weather.parched.metaphor"},
	GameConstants.Weather.MUGGY: {"humidity": 0.6, "temp": 0.5, "metaphor": "weather.muggy.metaphor"},
	GameConstants.Weather.OVERCAST: {"humidity": 0.2, "temp": - 0.2, "metaphor": "weather.overcast.metaphor"},
	GameConstants.Weather.DRIZZLE: {"humidity": 0.7, "temp": - 0.3, "metaphor": "weather.drizzle.metaphor"},
	GameConstants.Weather.HOT_WINDS: {"temp": 0.7, "wind": 0.8, "metaphor": "weather.hot_winds.metaphor"},
	GameConstants.Weather.COLD_WINDS: {"temp": - 0.7, "wind": 0.8, "metaphor": "weather.cold_winds.metaphor"},
	GameConstants.Weather.STORM_WINDS: {"humidity": 0.8, "wind": 1.0, "metaphor": "weather.storm_winds.metaphor"},
	GameConstants.Weather.DUST_STORM: {"humidity": - 0.9, "wind": 1.0, "metaphor": "weather.dust_storm.metaphor"},

	# Basic conditions
	GameConstants.Weather.SUNNY: {"temp": 0.5, "metaphor": "weather.sunny.metaphor"},
	GameConstants.Weather.CLOUDY: {"temp": - 0.2, "metaphor": "weather.cloudy.metaphor"},
	GameConstants.Weather.RAINY: {"humidity": 0.6, "metaphor": "weather.rainy.metaphor"},
	GameConstants.Weather.ARID: {"humidity": - 0.5, "metaphor": "weather.arid.metaphor"},
	GameConstants.Weather.WINDY: {"wind": 0.6, "metaphor": "weather.windy.metaphor"},

	"Shine Condition": {"temp": 0.3, "metaphor": "weather.shine.metaphor"},
	"Shade Condition": {"temp": - 0.3, "metaphor": "weather.shade.metaphor"},
	"Flow Condition": {"humidity": 0.3, "metaphor": "weather.flow.metaphor"},
	"Grit Condition": {"humidity": - 0.3, "metaphor": "weather.grit.metaphor"},
	"Gusto Condition": {"wind": 0.4, "metaphor": "weather.gusto.metaphor"},
	GameConstants.Weather.CALM: {Attributes.FOCUS: 2, "metaphor": "weather.calm.metaphor"},
	GameConstants.Weather.TEMPERATE: {Attributes.FOCUS: 1, "metaphor": "weather.temperate.metaphor"}
}

func get_weather_info(pressures: Array[String] = current_pressures) -> Dictionary:
	var weather_info: Dictionary

	if not is_hard_mode():
		weather_info = _get_basic_weather_info(pressures)
	else:
		weather_info = _get_hard_mode_weather_info(pressures)

	# Common wind calculation
	weather_info["wind_direction"] = Vector2(1, 0) if pressures.has(Attributes.GUSTO) else Vector2.ZERO
	weather_info["wind_intensity"] = 1.0 if pressures.has(Attributes.GUSTO) else 0.0
	if pressures.has(Attributes.FOCUS) and weather_info["wind_intensity"] > 0:
		weather_info["wind_intensity"] = 0.5

	return weather_info

func _get_basic_weather_info(pressures: Array[String]) -> Dictionary:
	var weather_name = GameConstants.Weather.TEMPERATE
	var p = Attributes.FOCUS

	if not pressures.is_empty():
		# In basic mode, we only care about the last pressure if multiple exist
		p = pressures[-1]
		match p:
			Attributes.SHINE: weather_name = GameConstants.Weather.SUNNY
			Attributes.SHADE: weather_name = GameConstants.Weather.CLOUDY
			Attributes.FLOW: weather_name = GameConstants.Weather.RAINY
			Attributes.GRIT: weather_name = GameConstants.Weather.ARID
			Attributes.GUSTO: weather_name = GameConstants.Weather.WINDY
			Attributes.FOCUS: weather_name = GameConstants.Weather.CALM

	return {
		"name": weather_name,
		"effects": tr("weather." + weather_name.to_lower() + ".effects"),
		"bonuses": {p: 1},
		"pressures": pressures
	}

func _get_hard_mode_weather_info(pressures: Array[String]) -> Dictionary:
	var weather_name = GameConstants.Weather.TEMPERATE
	var effects: String = tr("weather.temperate.effects")
	var bonuses = {Attributes.FOCUS: 1}

	if pressures.size() == 1:
		var p = pressures[0]
		if p == Attributes.FOCUS:
			weather_name = GameConstants.Weather.CALM
			effects = tr("weather.calm.effects")
			bonuses = {Attributes.FOCUS: 2}
		else:
			weather_name = tr("weather.condition.name").format({"name": p.capitalize()})
			effects = tr("weather.condition.effects")
			bonuses = {p: 1, Attributes.FOCUS: 1}
	elif pressures.size() == 2:
		var combo: Array[String] = pressures.duplicate()
		combo.sort()

		if combo.has(Attributes.FOCUS):
			var other = combo[0] if combo[1] == Attributes.FOCUS else combo[1]
			weather_name = tr("weather.condition.name").format({"name": other.capitalize()})
			effects = tr("weather.condition.effects")
			bonuses = {other: 1, Attributes.FOCUS: 1}
		else:
			for key in WEATHER_COMBOS:
				if combo[0] == key[0] and combo[1] == key[1]:
					var data = WEATHER_COMBOS[key]
					weather_name = data.name
					effects = tr("weather." + weather_name.to_lower().replace(" ", "_") + ".effects")
					bonuses = {combo[0]: 1, combo[1]: 1}
					break

	return {
		"name": weather_name,
		"effects": effects,
		"bonuses": bonuses,
		"pressures": pressures
	}

func apply_weather_effects() -> void:
	var info: Dictionary = get_weather_info()
	GameLogger.info(GameLogger.Category.SYSTEM, "Applying weather: ", info.name, " | Effects: ", info.effects)
	weather_effect_applied.emit(info)
	var attr: WeatherAttribute = get_current_weather_attribute()
	attr.attribute_name = info.name # Make sure the name is set
	weather_changed.emit(attr)

	if get_node_or_null("/root/EventBus"):
		EventBus.weather_effect_applied.emit(info)
		EventBus.weather_changed.emit(attr)

func get_current_weather_attribute() -> WeatherAttribute:
	var info: Dictionary = get_weather_info()
	var attr: WeatherAttribute = WeatherAttribute.new()
	attr.attribute_name = info.name
	attr.axis_effect = info.effects
	attr.wind_direction = info.wind_direction
	attr.wind_intensity = info.wind_intensity

	# Metadata localization
	var meta_key: String = info.name.to_lower().replace(" ", "_")
	var meta = WEATHER_METADATA.get(info.name, {})

	attr.humidity_effect = meta.get("humidity", 0.0)
	attr.temperature_effect = meta.get("temp", 0.0)

	if info.name.ends_with(" Condition"):
		var p_name: String = info.name.replace(" Condition", "").to_lower()
		attr.weather_metaphor = tr("weather.condition." + p_name + ".metaphor")
	else:
		attr.weather_metaphor = tr("weather." + meta_key + ".metaphor")

	if attr.weather_metaphor.begins_with("weather."): # tr failed
		attr.weather_metaphor = tr("weather.generic.metaphor")

	if meta.has("wind"):
		attr.wind_intensity = meta.wind

	return attr
