extends Node

signal event_emitted(event_name, payload)

# Typed Combat Signals
signal unit_attacked(attacker: Node, target: Node)
signal unit_damaged(target: Node, amount: int, source: Node)
signal unit_died(unit: Node)
signal unit_healed(target: Node, amount: int, source: Node)

func emit_event(event_name: String, payload = null) -> void:
	# Duplicate complex payloads to avoid accidental shared mutations across listeners
	var p = payload
	if typeof(payload) == TYPE_DICTIONARY or typeof(payload) == TYPE_ARRAY:
		p = payload.duplicate(true)
	emit_signal("event_emitted", event_name, p)
