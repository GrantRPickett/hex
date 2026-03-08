class_name UnitAttributes
extends Node

# Modifiers only - base values now live on Target/Unit
var _modifiers: Dictionary = {}
var _base_values_standalone: Dictionary = {}

func get_base_attribute(attribute: String) -> int:
	var unit = get_parent()
	if not unit:
		return _base_values_standalone.get(attribute, 0)

	if attribute == GameConstants.Attributes.WILLPOWER and not (GameConstants.Attributes.WILLPOWER in unit):
		if "base_willpower" in unit:
			return int(unit.get("base_willpower"))

	if attribute in unit:
		var val = unit.get(attribute)
		if val != null:
			return int(val)
	
	return _base_values_standalone.get(attribute, 0)

func get_attribute(attribute: String) -> int:
	# Willpower currently dynamic property on Unit, we don't apply modifiers to it here
	if attribute == GameConstants.Attributes.WILLPOWER:
		return get_base_attribute(GameConstants.Attributes.WILLPOWER)

	var total := get_base_attribute(attribute)

	# Apply normal modifiers
	for mods in _modifiers.values():
		total += int(mods.get(attribute, 0))

	var weather_manager := _get_weather_manager()
	if weather_manager:
		var weather_info = weather_manager.get_weather_info()
		total += int(weather_info.bonuses.get(attribute, 0))

	# Apply Aid buffs
	var unit = get_parent()
	if unit and attribute in GameConstants.Attributes.COMBAT_ATTRIBUTES and "aid_buffs" in unit:
		var idx = Target.COMBAT_ATTRIBUTE_NAMES.find(attribute)
		if idx != -1:
			var pair_idx = idx / 2
			var aid_buffs = unit.get("aid_buffs")
			if aid_buffs is Array and pair_idx < aid_buffs.size():
				total += int(aid_buffs[pair_idx])

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
	for attribute in Target.ATTRIBUTE_NAMES:
		result[attribute] = get_attribute(attribute)
	return result

func set_base_attribute(attribute: String, value: int) -> void:
	var unit = get_parent()
	if not unit:
		_base_values_standalone[attribute] = value
		return

	if attribute == GameConstants.Attributes.WILLPOWER and not (GameConstants.Attributes.WILLPOWER in unit):
		if "base_willpower" in unit:
			unit.set("base_willpower", value)
			return

	if attribute in unit:
		unit.set(attribute, value)
