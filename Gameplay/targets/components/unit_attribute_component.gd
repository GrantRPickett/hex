class_name UnitAttributeComponent
extends RefCounted

var _unit: Unit
var _modifiers: Dictionary = {} # source_id -> attribute deltas
var _cache: Dictionary = {}
var _cache_complete: bool = false

func _init(unit: Unit) -> void:
	_unit = unit


func apply_modifier(source_id: String, modifiers: Dictionary) -> void:
	if source_id.is_empty():
		return
	_modifiers[source_id] = modifiers.duplicate(true)
	_unit.attribute_modifiers_changed.emit()
	invalidate_cache()


func remove_modifier(source_id: String) -> void:
	if not _modifiers.has(source_id):
		return
	_modifiers.erase(source_id)
	_unit.attribute_modifiers_changed.emit()
	invalidate_cache()


func invalidate_cache() -> void:
	_cache.clear()
	_cache_complete = false


func get_modifiers() -> Dictionary:
	return _modifiers


func get_attribute(idx: GameConstants.AttributeIndex) -> int:
	var cache_key := int(idx)
	if _cache_complete and _cache.has(cache_key):
		return _cache[cache_key]

	var base := _unit.get_base_attribute_from_target(idx)
	var bonus := _unit.query.get_attribute_bonus(idx) if _unit.query else 0
	var total := base + bonus

	_cache[cache_key] = total
	if _cache.size() >= 6:
		_cache_complete = true

	if _unit.is_in_group("player"):
		var unit_name := _unit.unit_name if "unit_name" in _unit else "Unknown"
		GameLogger.debug(
			GameLogger.Category.COMBAT,
			"[UnitAttr] Unit: %s, Attr: %s, Base: %d, Bonus: %d, Total: %d (Cached)" % [
				unit_name,
				GameConstants.get_attribute_name(idx),
				base,
				bonus,
				total
			]
		)
	return total


func get_attribute_by_name(attr_name: String) -> int:
	var idx := GameConstants.get_attribute_index(attr_name)
	return get_attribute(idx)


func get_attribute_by_index(idx: GameConstants.AttributeIndex) -> int:
	if idx < 0 or idx > 6:
		return 0
	return get_attribute(idx as GameConstants.AttributeIndex)
