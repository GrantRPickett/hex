class_name UnitInventory
extends Node

const DEFAULT_CAPACITY := 6

signal item_equipped(item)
signal item_unequipped(item)

var slot_capacity: int = DEFAULT_CAPACITY
var _items: Array = []

func equip_item(item) -> bool:
    if item == null:
        return false
    if _items.size() >= slot_capacity:
        return false
    if _items.has(item):
        return false
    _items.append(item)
    item_equipped.emit(item)
    return true

func unequip_item(item) -> bool:
    var idx := _items.find(item)
    if idx == -1:
        return false
    _items.remove_at(idx)
    item_unequipped.emit(item)
    return true

func clear() -> void:
    for item in _items.duplicate():
        unequip_item(item)

func get_items() -> Array:
    return _items.duplicate()
