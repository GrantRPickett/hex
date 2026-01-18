class_name LootManager
extends Node

signal loot_added(loot: Loot, coord: Vector2i)
signal loot_removed(loot: Loot)

var _loot_items: Array[Loot] = []
var _coords: Array[Vector2i] = []

func reset() -> void:
	_loot_items.clear()
	_coords.clear()

func add_loot(loot: Loot, coord: Vector2i) -> void:
	if loot == null:
		return
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
	return Vector2i.ZERO

func get_all_loot() -> Array[Loot]:
	return _loot_items.duplicate()

func spawn_loot(coord: Vector2i, items: Array) -> void:
	if items.is_empty():
		return

	var existing_loot := get_loot_at(coord)
	if existing_loot:
		for item in items:
			if item is InventoryItem:
				existing_loot.inventory.append(item)
		return

	var loot: Loot = Loot.new()
	for item in items:
		if item is InventoryItem:
			loot.inventory.append(item)

	if loot.inventory.is_empty():
		loot.queue_free()
		return

	add_loot(loot, coord)