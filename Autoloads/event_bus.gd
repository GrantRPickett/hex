extends Node

signal event_emitted(event_name, payload)

func emit_event(event_name: String, payload = null) -> void:
    event_emitted.emit(event_name, payload)
