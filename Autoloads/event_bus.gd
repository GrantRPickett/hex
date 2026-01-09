extends Node

signal event_emitted(event_name, payload)

func emit_event(event_name: String, payload = null) -> void:
    # Duplicate complex payloads to avoid accidental shared mutations across listeners
    var p = payload
    if typeof(payload) == TYPE_DICTIONARY or typeof(payload) == TYPE_ARRAY:
        p = payload.duplicate(true)
    emit_signal("event_emitted", event_name, p)
