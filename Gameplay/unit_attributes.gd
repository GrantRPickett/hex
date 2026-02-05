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
var _initialized: bool = false

func _ready() -> void:
	_ensure_base_values()

func _ensure_base_values() -> void:
	if _initialized:
		return
	if base_values.is_empty():
		base_values = {}
		for attr_name in ATTRIBUTE_NAMES:
			base_values[attr_name] = 6
	else:
		base_values = base_values.duplicate(true)
	_initialized = true

func set_base_attribute(attribute: String, value: int) -> void:
	_ensure_base_values()
	base_values[attribute] = value

func get_base_attribute(attribute: String) -> int:
	_ensure_base_values()
	return int(base_values.get(attribute, 0))

func get_attribute(attribute: String) -> int:
	var total := get_base_attribute(attribute)

	# Apply normal modifiers
	for mods in _modifiers.values():
		total += int(mods.get(attribute, 0))

	var weather_manager := _get_weather_manager()
	if weather_manager:
		var weather_info = weather_manager.get_weather_info()
		total += int(weather_info.bonuses.get(attribute, 0))

	return total

func _get_weather_manager() -> Node:
	if Engine.has_singleton("WeatherManager"):
		return Engine.get_singleton("WeatherManager")
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/WeatherManager")

func apply_modifier(source_id: String, modifiers: Dictionary) -> void:
	if source_id.is_empty():
		return
	_modifiers[source_id] = modifiers.duplicate(true)

func remove_modifier(source_id: String) -> void:
	if _modifiers.has(source_id):
		_modifiers.erase(source_id)

func get_all_attributes() -> Dictionary:
	_ensure_base_values()
	var result: Dictionary = {}
	for attribute in ATTRIBUTE_NAMES:
		result[attribute] = get_attribute(attribute)
	return result
