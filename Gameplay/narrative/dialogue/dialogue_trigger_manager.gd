class_name DialogueTriggerManager
extends Object

const SEEN_DIALOGUES_KEY := "seen_dialogues"

var _dialogue_triggers: Dictionary = {} # dialogue_id -> DialogueTrigger
var _registered_triggers: Array[DialogueTrigger] = []
var _seen_flags: Dictionary = {}
var _save_manager: Node

func setup(save_manager: Node) -> void:
	_save_manager = save_manager
	_load_seen_flags()

func register_triggers(triggers: Array[DialogueTrigger]) -> void:
	_cleanup_registered_triggers()
	_registered_triggers = triggers.duplicate(false)
	_dialogue_triggers.clear()

	for trigger in triggers:
		if trigger == null: continue
		var id := trigger.get_dialogue_id()
		if id.is_empty(): continue

		if _seen_flags.get(id, false):
			trigger.mark_seen(true)
		else:
			trigger.reset_seen()
		_dialogue_triggers[id] = trigger

func get_trigger(dialogue_id: StringName) -> DialogueTrigger:
	return _dialogue_triggers.get(dialogue_id)

func get_all_triggers() -> Array:
	return _dialogue_triggers.values()

func get_trigger_at(coord: Vector2i) -> DialogueTrigger:
	for trigger in _dialogue_triggers.values():
		if is_instance_valid(trigger) and trigger.get_grid_location() == coord:
			return trigger
	return null

func mark_seen(trigger: DialogueTrigger) -> void:
	if trigger == null: return
	trigger.mark_seen()
	_seen_flags[trigger.get_dialogue_id()] = true
	_save_seen_flags()

func _cleanup_registered_triggers() -> void:
	for trigger in _registered_triggers:
		if is_instance_valid(trigger):
			trigger.queue_free()
	_registered_triggers.clear()

func _load_seen_flags() -> void:
	if _save_manager == null: return
	var loaded_flags = _save_manager.get_value(SEEN_DIALOGUES_KEY, {})
	if loaded_flags is Dictionary:
		_seen_flags = loaded_flags

func _save_seen_flags() -> void:
	if _save_manager == null: return
	_save_manager.set_value(SEEN_DIALOGUES_KEY, _seen_flags)

func clear_triggers() -> void:
	_cleanup_registered_triggers()
	_dialogue_triggers.clear()
