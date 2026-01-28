class_name WeatherPanel
extends CustomResizablePanel

@onready var _current_name: Label = %CurrentName
@onready var _current_effect: Label = %CurrentEffect
@onready var _next_name: Label = %NextName
@onready var _next_metaphor: Label = %NextMetaphor

func _ready() -> void:
	super._ready()
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
		_next_name.text = "Next Round: " + info.name
		_next_metaphor.text = info.effects # Or metaphors if I added them to get_weather_info
		# Show pressures in forecast
		if pressures.is_empty():
			_next_metaphor.text = "No pressures active."
		else:
			_next_metaphor.text = "Pressures: " + ", ".join(pressures).capitalize()
	else:
		_current_name.text = "Current: " + info.name
		_current_effect.text = info.effects

		# Optional: add flavor text or pressures to current display too
		if not pressures.is_empty():
			_current_effect.text += "\n(" + ", ".join(pressures).capitalize() + ")"

func force_fit_content() -> void:
	# Resets size to minimum allowed by content
	size = Vector2.ZERO
	# custom_minimum_size = Vector2(min_width, min_height) # Inherited properly
