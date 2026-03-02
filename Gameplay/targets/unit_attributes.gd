class_name UnitAttributes
extends Node

const ATTRIBUTE_NAMES := [
	"grit",
	"flow",
	"gusto",
	"focus",
	"shine",
	"shade",
	"willpower",
]

# Modifiers only - base values now live on Target/Unit
var _modifiers: Dictionary = {}

func get_base_attribute(attribute: String) -> int:
	var unit = get_parent()
	if unit:
		return int(unit.get(attribute))
	return 0

func get_attribute(attribute: String) -> int:
	# Willpower currently dynamic property on Unit, we don't apply modifiers to it here
	if attribute == "willpower":
		return get_base_attribute("willpower")
		
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
	var result: Dictionary = {}
	for attribute in ATTRIBUTE_NAMES:
		result[attribute] = get_attribute(attribute)
	return result

func set_base_attribute(attribute: String, value: int) -> void:
	var unit = get_parent()
	if unit and attribute in unit:
		unit.set(attribute, value)
