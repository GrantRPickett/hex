# Autoloads/WeatherManager.gd
extends Node

signal pressures_changed(current_pressures)
signal forecast_pressures_changed(forecast_pressures)
signal weather_effect_applied(weather_info)
signal weather_changed(new_weather_attribute: WeatherAttribute)

# Pressures
const SHINE = "shine"
const SHADE = "shade"
const FLOW = "flow"
const GRIT = "grit"
const GUSTO = "gusto"
const FOCUS = "focus"

const OPPOSITES = {
	SHINE: SHADE,
	SHADE: SHINE,
	FLOW: GRIT,
	GRIT: FLOW,
	GUSTO: FOCUS,
	FOCUS: GUSTO
}

var current_pressures: Array[String] = []
var forecast_pressures: Array[String] = []

var _channeling_unit: Unit = null

func _ready() -> void:
	# Start with a random background pressure perhaps?
	# Or just temperate. Notes w1 says "Calm skies mean nothing is pushing the system."
	# Let's start temperate.
	pass

func add_pressure(pressure: String, to_forecast: bool = true) -> void:
	var list = forecast_pressures if to_forecast else current_pressures

	# 1. Opposites cancel out
	if OPPOSITES.has(pressure):
		var opposite = OPPOSITES[pressure]
		if list.has(opposite):
			list.erase(opposite)
			_notify_changed(to_forecast)
			return

	# 2. Reinforce or Add
	if list.has(pressure):
		# Already present, reinforcing doesn't change the list but might be relevant for logic
		return

	# 3. Add and Limit to 2
	list.append(pressure)
	if list.size() > 2:
		list.remove_at(0) # Oldest pressure fades

	_notify_changed(to_forecast)

func remove_pressure(pressure: String, from_forecast: bool = true) -> void:
	var list = forecast_pressures if from_forecast else current_pressures
	if list.has(pressure):
		list.erase(pressure)
		_notify_changed(from_forecast)

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

func create_memento(unit_manager = null) -> Dictionary:
	var channel_index := -1
	if unit_manager and is_instance_valid(_channeling_unit):
		channel_index = unit_manager.get_unit_index(_channeling_unit)
	return {
		"current_pressures": current_pressures.duplicate(),
		"forecast_pressures": forecast_pressures.duplicate(),
		"channeling_unit_index": channel_index
	}

func restore_from_memento(memento: Dictionary, unit_manager = null) -> void:
	var stored_current: Array = memento.get("current_pressures", [])
	var stored_forecast: Array = memento.get("forecast_pressures", [])
	current_pressures = stored_current.duplicate()
	forecast_pressures = stored_forecast.duplicate()
	_channeling_unit = null
	var channel_index: int = memento.get("channeling_unit_index", -1)
	if unit_manager and channel_index >= 0:
		var candidate = unit_manager.get_unit(channel_index)
		if is_instance_valid(candidate):
			_channeling_unit = candidate
	pressures_changed.emit(current_pressures)
	forecast_pressures_changed.emit(forecast_pressures)
	apply_weather_effects()

func get_weather_info(pressures: Array[String] = current_pressures) -> Dictionary:
	var weather_name = "Temperate"
	var effects = "Focus +1"
	var bonuses = {"focus": 1} # Temperate grants a minor focus bonus

	if pressures.size() == 0:
		pass
	elif pressures.size() == 1:
		var p = pressures[0]
		if p == FOCUS:
			weather_name = "Calm"
			effects = "High stability. Focus +2."
			bonuses = {"focus": 2}
		else:
			weather_name = p.capitalize() + " Condition"
			effects = "Background influence. Focus +1."
			bonuses = {p: 1, "focus": 1}
	elif pressures.size() == 2:
		var combo = pressures.duplicate()
		combo.sort()

		# If one is Focus, it stabilizes back to background weather
		if combo.has(FOCUS):
			var other = combo[0] if combo[1] == FOCUS else combo[1]
			weather_name = other.capitalize() + " Condition"
			effects = "Stabilized background influence. Focus +1."
			bonuses = {other: 1, "focus": 1}
		# Map based on w3
		elif combo.has(SHINE) and combo.has(GRIT):
			weather_name = "Parched"
			effects = "Fatigue rises, fire spreads, water use up."
			bonuses = {SHINE: 1, GRIT: 1}
		elif combo.has(SHINE) and combo.has(FLOW):
			weather_name = "Muggy"
			effects = "Stamina recovery reduced, morale pressure."
			bonuses = {SHINE: 1, FLOW: 1}
		elif combo.has(SHADE) and combo.has(GRIT):
			weather_name = "Overcast"
			effects = "Reduced light and visibility, cooler."
			bonuses = {SHADE: 1, GRIT: 1}
		elif combo.has(SHADE) and combo.has(FLOW):
			weather_name = "Drizzle"
			effects = "Slick ground, fire suppressed."
			bonuses = {SHADE: 1, FLOW: 1}
		elif combo.has(SHINE) and combo.has(GUSTO):
			weather_name = "Hot Winds"
			effects = "Rapid fatigue, fire spread, forced move."
			bonuses = {SHINE: 1, GUSTO: 1}
		elif combo.has(SHADE) and combo.has(GUSTO):
			weather_name = "Cold Winds"
			effects = "Morale drain, heat loss, precision penalty."
			bonuses = {SHADE: 1, GUSTO: 1}
		elif combo.has(FLOW) and combo.has(GUSTO):
			weather_name = "Storm Winds"
			effects = "Lightning risk, heavy visibility loss."
			bonuses = {FLOW: 1, GUSTO: 1}
		elif combo.has(GRIT) and combo.has(GUSTO):
			weather_name = "Dust Storm"
			effects = "Severe visibility reduction, move penalty."
			bonuses = {GRIT: 1, GUSTO: 1}

	var wind_dir = Vector2.ZERO
	var wind_intens = 0.0

	if pressures.has(GUSTO):
		wind_dir = Vector2(1, 0) # Default east wind
		wind_intens = 1.0
		# Focus dampens wind if it was somehow present (though rules say it stabilizes)
		if pressures.has(FOCUS):
			wind_intens = 0.5

	return {
		"name": weather_name,
		"effects": effects,
		"bonuses": bonuses,
		"pressures": pressures,
		"wind_direction": wind_dir,
		"wind_intensity": wind_intens
	}

func apply_weather_effects() -> void:
	var info = get_weather_info()
	print("Applying weather: ", info.name, " | Effects: ", info.effects)
	weather_effect_applied.emit(info)
	weather_changed.emit(get_current_weather_attribute())
	# Here you would loop through units and apply modifiers to attributes
	# But typically signals are better for this.

func get_current_weather_attribute() -> WeatherAttribute:
	var info = get_weather_info()
	var attr = WeatherAttribute.new()
	attr.attribute_name = info.name
	attr.axis_effect = info.effects
	attr.wind_direction = info.wind_direction
	attr.wind_intensity = info.wind_intensity

	# Map common weather states to their physical effects for the resource
	match info.name:
		"Parched":
			attr.humidity_effect = -0.8
			attr.temperature_effect = 0.8
			attr.weather_metaphor = "Cracked earth and shimmering heat."
		"Muggy":
			attr.humidity_effect = 0.6
			attr.temperature_effect = 0.5
			attr.weather_metaphor = "Heavy air that clings to the skin."
		"Overcast":
			attr.humidity_effect = 0.2
			attr.temperature_effect = -0.2
			attr.weather_metaphor = "A blanket of grey obscuring the sun."
		"Drizzle":
			attr.humidity_effect = 0.7
			attr.temperature_effect = -0.3
			attr.weather_metaphor = "Soft mist and damp stone."
		"Hot Winds":
			attr.temperature_effect = 0.7
			attr.wind_intensity = 0.8
			attr.weather_metaphor = "A furnace blast of dry air."
		"Cold Winds":
			attr.temperature_effect = -0.7
			attr.wind_intensity = 0.8
			attr.weather_metaphor = "A biting chill that cuts through armor."
		"Storm Winds":
			attr.humidity_effect = 0.8
			attr.wind_intensity = 1.0
			attr.weather_metaphor = "Howling gusts and flashing skies."
		"Dust Storm":
			attr.humidity_effect = -0.9
			attr.wind_intensity = 1.0
			attr.weather_metaphor = "A wall of grit choking the horizon."
		"Shine Condition":
			attr.temperature_effect = 0.3
			attr.weather_metaphor = "A warm glow spreads across the land."
		"Shade Condition":
			attr.temperature_effect = -0.3
			attr.weather_metaphor = "Cool shadows offer a moment of respite."
		"Flow Condition":
			attr.humidity_effect = 0.3
			attr.weather_metaphor = "A humid breeze carries the scent of rain."
		"Grit Condition":
			attr.humidity_effect = -0.3
			attr.weather_metaphor = "The air is dry and dusty."
		"Gusto Condition":
			attr.wind_intensity = 0.4
			attr.weather_metaphor = "A steady wind whips through the trees."
		"Calm":
			attr.weather_metaphor = "Still air and perfect clarity."
		"Temperate":
			attr.weather_metaphor = "Mild skies and gentle breezes."
		_:
			attr.weather_metaphor = "The atmosphere shifts."

	return attr
