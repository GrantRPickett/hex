class_name RosterPersistence
extends RefCounted

static func unit_to_entry(unit: Unit) -> Dictionary:
	if unit == null:
		return {}

	unit.prepare_for_save()
	return {
		"scene_path": unit.scene_file_path,
		"unit_name": unit.unit_name,
		"data": UnitSerializer.create_memento(unit)
	}

static func entry_to_scene(entry: Dictionary) -> PackedScene:
	if entry.is_empty():
		return null

	var scene_path: String = entry.get("scene_path", "")
	var fallback_scene: PackedScene = entry.get("fallback_scene", null)
	var base_scene: PackedScene = null

	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		base_scene = load(scene_path)
	if base_scene == null:
		return fallback_scene

	var instance = base_scene.instantiate()
	var unit := instance as Unit
	if unit == null:
		instance.queue_free()
		return null

	UnitSerializer.restore_from_memento(unit, entry.get("data", {}))
	var unit_name: String = entry.get("unit_name", "")
	if not unit_name.is_empty():
		unit.unit_name = unit_name

	var packed = PackedScene.new()
	packed.pack(unit)
	unit.queue_free()
	return packed

static func scene_to_entry(scene: PackedScene) -> Dictionary:
	if scene == null:
		return {}

	var entry: Dictionary = {
		"scene_path": scene.resource_path,
		"unit_name": "",
		"data": {},
		"fallback_scene": scene
	}

	var instance = scene.instantiate()
	var unit := instance as Unit
	if unit:
		if String(entry["scene_path"]).is_empty():
			entry["scene_path"] = unit.scene_file_path
		entry["unit_name"] = unit.unit_name
	instance.queue_free()
	return entry
