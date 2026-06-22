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

	var instance: Node = base_scene.instantiate()
	var unit := instance as Unit
	if unit == null:
		instance.queue_free()
		return null

	UnitSerializer.restore_from_memento(unit, entry.get("data", {}))
	var unit_name: String = entry.get("unit_name", "")
	if not unit_name.is_empty():
		unit.unit_name = unit_name

	# Recursively set owner for all children so they are included in the PackedScene
	_set_owner_recursive(unit, unit)

	var packed: PackedScene = PackedScene.new()
	var err: int = packed.pack(unit)
	if err != OK:
		GameLogger.error(GameLogger.Category.SYSTEM, "RosterPersistence: Failed to pack unit %s. Error: %d" % [unit.unit_name, err])
		unit.queue_free()
		return null
		
	unit.queue_free()
	return packed

static func entry_to_unit(entry: Dictionary) -> Unit:
	if entry.is_empty():
		return null

	var scene_path: String = entry.get("scene_path", "")
	var base_scene: PackedScene = null

	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		base_scene = load(scene_path)
	
	if base_scene == null:
		return null

	var unit: Unit = base_scene.instantiate() as Unit
	if unit:
		UnitSerializer.restore_from_memento(unit, entry.get("data", {}))
		var unit_name: String = entry.get("unit_name", "")
		if not unit_name.is_empty():
			unit.unit_name = unit_name
	return unit

static func _set_owner_recursive(node: Node, p_owner: Node) -> void:
	for child in node.get_children():
		child.owner = p_owner
		_set_owner_recursive(child, p_owner)

static func scene_to_entry(scene: PackedScene) -> Dictionary:
	if scene == null:
		return {}

	var entry: Dictionary = {
		"scene_path": scene.resource_path,
		"unit_name": "",
		"data": {},
		"fallback_scene": scene
	}

	var instance: Node = scene.instantiate()
	var unit := instance as Unit
	if unit:
		if String(entry["scene_path"]).is_empty():
			entry["scene_path"] = unit.scene_file_path
		entry["unit_name"] = unit.unit_name
	instance.queue_free()
	return entry
