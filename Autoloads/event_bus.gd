#class_name EventBus
extends Node

# Typed Combat Signals
signal unit_attacked(attacker: Node, target: Node)
signal unit_damaged(target: Node, amount: int, source: Node)
signal unit_died(unit: Node)
signal unit_healed(target: Node, amount: int, source: Node)
signal unit_moved(unit: Node, coord: Vector2i)
signal combat_action_performed(attacker: Node, defender: Node, attribute_index: int, results: Dictionary)
signal aid_action_performed(helper: Node, ally: Node, attribute_index: int, amount: int)


# Narrative & Dialogue Signals
signal dialogue_requested(resource_path: String, flag_id: StringName)
signal dialogue_started(flag_id: StringName)
signal dialogue_finished(flag_id: StringName)

# Progression Signals
signal objective_started(objective_id: String)
signal objective_completed(objective_id: String)
signal objective_failed(objective_id: String)
signal task_completed(task_id: String)
signal task_failed(task_id: String)
signal stage_completed(stage_id: String)

# UI and Interaction Signals
signal unit_selected(unit: Node)
signal unit_deselected(unit: Node)
signal hover_target_changed(target: Node)
signal locations_updated()
signal turn_changed(turn_number: int, side: int)
signal round_changed(round_number: int)
signal show_feedback_message(message: String)
signal ui_button_pressed()
signal ui_hover_triggered()

# Gameplay System Signals
signal level_started(level_id: String)
signal level_completed(level_id: String)
signal level_failed(level_id: String)
signal loot_collected(loot_node: Node)
signal item_equipped(unit: Node, item: Resource)
signal item_unequipped(unit: Node, item: Resource)
signal item_added(unit: Node, item: Resource)
signal item_removed(unit: Node, item: Resource)
signal checkpoint_created()
signal undo_performed()
signal redo_performed()
signal unit_loyalty_changed(unit: Node, new_loyalty: int)

# Audio Specific Triggers
signal audio_trigger_requested(sound_id: String)

# Weather Hooks
signal weather_changed(new_weather_attribute: WeatherAttribute)
signal weather_effect_applied(weather_info: Dictionary)

# Morale & Juice Hooks
signal unit_willpower_critical(unit: Node)
signal faction_willpower_critical(faction: int)
