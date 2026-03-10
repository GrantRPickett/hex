#class_name EventBus
extends Node

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
signal show_feedback_message(message: String)

# Weather Hooks
signal weather_changed(new_weather_attribute: WeatherAttribute)
signal weather_effect_applied(weather_info: Dictionary)

# Morale & Juice Hooks
signal unit_willpower_critical(unit: Node)
signal faction_willpower_critical(faction: int)
