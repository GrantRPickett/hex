class_name UnitAttributes
extends Node

const ATTRIBUTE_NAMES := [
	"grit",
	"flow",
	"gusto",
	"focus",
	"shine",
	"shade",
]

@export var base_values: Dictionary = {}

var _modifiers: Dictionary = {}

func _init() -> void:
	if base_values.is_empty():
		for attr_name in ATTRIBUTE_NAMES:
			base_values[attr_name] = 6

func set_base_attribute(attribute: String, value: int) -> void:
	base_values[attribute] = value

func get_base_attribute(attribute: String) -> int:
	return int(base_values.get(attribute, 0))

func get_attribute(attribute: String) -> int:
	var total := get_base_attribute(attribute)

	# Apply normal modifiers
	for mods in _modifiers.values():
		total += int(mods.get(attribute, 0))

	# Apply weather bonuses
	if Engine.has_singleton("WeatherManager") or (get_node_or_null("/root/WeatherManager") != null):
		var weather_info = get_node("/root/WeatherManager").get_weather_info()
		total += int(weather_info.bonuses.get(attribute, 0))

	return total

func apply_modifier(source_id: String, modifiers: Dictionary) -> void:
	if source_id.is_empty():
		return
	_modifiers[source_id] = modifiers.duplicate(true)

func remove_modifier(source_id: String) -> void:
	if _modifiers.has(source_id):
		_modifiers.erase(source_id)

func get_all_attributes() -> Dictionary:
	var result: Dictionary = {}
	for attribute in ATTRIBUTE_NAMES:
		result[attribute] = get_attribute(attribute)
	return result
