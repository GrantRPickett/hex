class_name DialogueTriggerGroup
extends RefCounted

var group_id: StringName = StringName("")
var seen := false
var _members: Array = []

func _init(id: StringName = StringName("")) -> void:
	group_id = id

func register_trigger(trigger) -> void:
	if trigger == null:
		return
	if _members.has(trigger):
		return
	_members.append(trigger)
	if seen and trigger.has_method("mark_seen"):
		trigger.mark_seen(true)

func mark_seen() -> void:
	if seen:
		return
	seen = true
	for member in _members:
		if member and member.has_method("mark_seen"):
			member.mark_seen(true)

func reset() -> void:
	seen = false
	for member in _members:
		if member and member.has_method("reset_seen"):
			member.reset_seen()
