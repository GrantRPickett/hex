class_name TaskValidator
extends RefCounted

# Pure validation helpers. No Node/tree access.

func validate_item_target(task: Task, world: Dictionary) -> bool:
	# world expectations:
	#  - items: Dictionary{id -> {holder_kind: StringName, holder_id: StringName, quest: bool, in_stash: bool}}
	if task == null or task.target_id.is_empty():
		return false
	var items: Dictionary = world.get("items", {})
	var it: Dictionary = items.get(String(task.target_id), {})
	if it.is_empty():
		return false
	var holder_kind: StringName = it.get("holder_kind", &"none")
	var quest: bool = bool(it.get("quest", false))
	var in_stash: bool = bool(it.get("in_stash", false))
	if holder_kind == &"location" or holder_kind == &"unit_npc":
		return true
	if quest and in_stash:
		return true
	return false

func validate_location_target(task: Task, world: Dictionary) -> bool:
	if task == null:
		return false
	var locations: Dictionary = world.get("locations", {})
	if not task.target_id.is_empty():
		return locations.has(String(task.target_id))
	if task.target_coord != Vector2i(-999, -999):
		return locations.values().any(func(l): return l.get("coord", Vector2i.ZERO) == task.target_coord)
	return false

func validate_unit_target(task: Task, world: Dictionary) -> bool:
	if task == null or task.target_id.is_empty():
		return false
	var units: Dictionary = world.get("units", {})
	return units.has(String(task.target_id))

