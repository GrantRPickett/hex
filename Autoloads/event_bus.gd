#class_name EventBus
extends Node

signal event_emitted(event_name, payload)

# Typed Combat Signals
signal unit_attacked(attacker: Node, target: Node)
signal unit_damaged(target: Node, amount: int, source: Node)
signal unit_died(unit: Node)
signal unit_healed(target: Node, amount: int, source: Node)

# UI and Interaction Signals
signal unit_selected(unit: Node)
signal unit_deselected(unit: Node)
signal hover_target_changed(target: Node)
signal locations_updated()
signal turn_changed(turn_number: int, side: int)

# Weather Hooks
signal weather_changed(new_weather_attribute: WeatherAttribute)
signal weather_effect_applied(weather_info: Dictionary)

# Morale & Juice Hooks
signal unit_willpower_critical(unit: Node)
signal faction_willpower_critical(faction: int)

func emit_event(event_name: String, payload = null) -> void:
	# Duplicate complex payloads to avoid accidental shared mutations across listeners
	var p = payload
	if typeof(payload) == TYPE_DICTIONARY or typeof(payload) == TYPE_ARRAY:
		p = payload.duplicate(true)
	emit_signal("event_emitted", event_name, p)
