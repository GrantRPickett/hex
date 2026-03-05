class_name LootManager
extends Node

signal loot_added(loot: Loot, coord: Vector2i)
signal loot_removed(loot: Loot)

var _loot_items: Array[Loot] = []
var _coords: Array[Vector2i] = []
var _routing_pool: Array[InventoryItem] = []

func reset() -> void:
	for loot in _loot_items:
		if is_instance_valid(loot):
			loot.queue_free()
	_loot_items.clear()
	_coords.clear()
	_routing_pool.clear()

func add_to_routing_pool(items: Array[InventoryItem]) -> void:
	_routing_pool.append_array(items)

func collect_routing_pool() -> Array[InventoryItem]:
	var result = _routing_pool.duplicate()
	_routing_pool.clear()
	return result

func add_loot(loot: Loot, coord: Vector2i) -> void:
	if loot == null:
		return
	loot.set_external_grid_coord(coord)
	_loot_items.append(loot)
	_coords.append(coord)
	loot_added.emit(loot, coord)

func remove_loot(loot: Loot) -> void:
	var index = _loot_items.find(loot)
	if index == -1:
		return

	_loot_items.remove_at(index)
	_coords.remove_at(index)
	loot_removed.emit(loot)
	loot.queue_free()

func get_loot_at(coord: Vector2i) -> Loot:
	var index = _coords.find(coord)
	if index != -1:
		return _loot_items[index]
	return null

func has_loot_at(coord: Vector2i) -> bool:
	return _coords.has(coord)

func get_loot_count() -> int:
	return _loot_items.size()

func get_loot(index: int) -> Loot:
	if index >= 0 and index < _loot_items.size():
		return _loot_items[index]
	return null

func get_coord(index: int) -> Vector2i:
	if index >= 0 and index < _coords.size():
		return _coords[index]
	return Vector2i(-999, -999)

func get_all_loot() -> Array[Loot]:
	return _loot_items.duplicate()

func spawn_loot(coord: Vector2i, items: Array) -> void:
	if items.is_empty():
		return

	var existing_loot := get_loot_at(coord)
	if existing_loot:
		existing_loot.add_items(items)
		return

	_spawn_new_loot(coord, items)

func _spawn_new_loot(coord: Vector2i, items: Array) -> void:
	var entry := LevelLootEntry.new()
	entry.coord = coord
	entry.items.assign(items)
	TargetSpawner.spawn_loot(entry, self )

func create_memento() -> Dictionary:
	var loot_data: Array[Dictionary] = []
	for i in range(_loot_items.size()):
		var loot = _loot_items[i]
		if is_instance_valid(loot):
			loot_data.append({
				"coord": _coords[i],
				"items": loot.inventory.duplicate()
			})
	return {"loot": loot_data}

func restore_from_memento(memento: Dictionary) -> void:
	reset()
	var loot_data = memento.get("loot", [])
	for entry in loot_data:
		spawn_loot(entry.get("coord", Vector2i.ZERO), entry.get("items", []))

func collect_all_loot_items() -> Array[InventoryItem]:
	var collected: Array[InventoryItem] = []
	var loot_copy := _loot_items.duplicate()
	for loot in loot_copy:
		if not is_instance_valid(loot):
			continue
		var taken: Array[InventoryItem] = loot.take_all_items()
		for item in taken:
			if item:
				collected.append(item)
		remove_loot(loot)
	return collected
