class_name UnitStatusComponent
extends RefCounted

var unit: Unit
var status_effects: Dictionary = {}

func _init(p_unit: Unit) -> void:
	unit = p_unit

func apply_status_effect(effect: StringName) -> void:
	if effect.is_empty():
		return
	status_effects[effect] = true

func has_status_effect(effect: StringName) -> bool:
	return status_effects.get(effect, false)

func clear_status_effect(effect: StringName) -> void:
	status_effects.erase(effect)

func get_status_effects() -> Array:
	return status_effects.keys()
