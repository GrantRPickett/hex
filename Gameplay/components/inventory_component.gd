class_name InventoryComponent
extends Resource

const UnitAttributes := preload("res://Gameplay/unit_attributes.gd")
const UnitInventory := preload("res://Gameplay/unit_inventory.gd")
const InventoryItem := preload("res://Resources/inventory_item.gd")

@export var attributes_path: NodePath
@export var inventory_path: NodePath

var _owner: Node
var _attributes: UnitAttributes
var _inventory: UnitInventory
var _item_modifier_ids: Dictionary = {}
var _equipped_callable: Callable
var _unequipped_callable: Callable

func setup(owner: Node, attributes: UnitAttributes = null, inventory: UnitInventory = null) -> void:
	cleanup()
	_owner = owner
	_attributes = attributes
	if _attributes == null and owner != null:
		if not attributes_path.is_empty() and owner.has_node(attributes_path):
			_attributes = owner.get_node(attributes_path)
		else:
			_attributes = UnitAttributes.new()
			owner.add_child(_attributes)
	_inventory = inventory
	if _inventory == null and owner != null:
		if not inventory_path.is_empty() and owner.has_node(inventory_path):
			_inventory = owner.get_node(inventory_path)
		else:
			_inventory = UnitInventory.new()
			owner.add_child(_inventory)
	if _inventory:
		_equipped_callable = func(item: InventoryItem) -> void:
			if _attributes == null or item == null:
				return
			var id := str(item.get_instance_id())
			_item_modifier_ids[item] = id
			_attributes.apply_modifier(id, item.attribute_modifiers)
		_inventory.item_equipped.connect(_equipped_callable)
		_unequipped_callable = func(item: InventoryItem) -> void:
			if _attributes == null or item == null:
				return
			if not _item_modifier_ids.has(item):
				return
			var id: String = _item_modifier_ids[item]
			_attributes.remove_modifier(id)
			_item_modifier_ids.erase(item)
		_inventory.item_unequipped.connect(_unequipped_callable)

func cleanup() -> void:
	if _inventory:
		if _equipped_callable and _inventory.item_equipped.is_connected(_equipped_callable):
			_inventory.item_equipped.disconnect(_equipped_callable)
		if _unequipped_callable and _inventory.item_unequipped.is_connected(_unequipped_callable):
			_inventory.item_unequipped.disconnect(_unequipped_callable)
	_equipped_callable = Callable()
	_unequipped_callable = Callable()
	_item_modifier_ids.clear()
	_owner = null
	_attributes = null
	_inventory = null

func get_attributes() -> UnitAttributes:
	return _attributes

func get_inventory() -> UnitInventory:
	return _inventory

func equip_item(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.equip_item(item)

func unequip_item(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.unequip_item(item)
