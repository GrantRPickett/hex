class_name Unit
extends Node2D

enum Faction {
    PLAYER,
    ENEMY,
    NEUTRAL
}

@export var unit_name: String = ""
@export var faction: Faction = Faction.PLAYER
@export var willpower: int = 10
@export var movement_points: int = 6
@export var action_range: float = 10.0
@export var attributes_path: NodePath
@export var inventory_path: NodePath

var skills: Array[StringName] = []
var _attributes: UnitAttributes
var _inventory: UnitInventory
var _item_modifier_ids: Dictionary = {}

func _ready() -> void:
    _attributes = _resolve_child(attributes_path, UnitAttributes)
    _inventory = _resolve_child(inventory_path, UnitInventory)
    if _inventory:
        _inventory.item_equipped.connect(_on_item_equipped)
        _inventory.item_unequipped.connect(_on_item_unequipped)

func get_attributes() -> UnitAttributes:
    return _attributes

func get_inventory() -> UnitInventory:
    return _inventory

func add_skill(skill: StringName) -> void:
    if not skills.has(skill):
        skills.append(skill)

func equip_item(item: InventoryItem) -> bool:
    if _inventory == null:
        return false
    return _inventory.equip_item(item)

func unequip_item(item: InventoryItem) -> bool:
    if _inventory == null:
        return false
    return _inventory.unequip_item(item)

func has_nearby_units(units: Array, detection_range: float) -> bool:
    return not get_units_in_range(units, detection_range).is_empty()

func get_units_in_range(units: Array, detection_range: float) -> Array:
    var result: Array = []
    for other in units:
        if other == null or other == self:
            continue
        if not (other is Unit):
            continue
        if global_position.distance_to(other.global_position) <= detection_range:
            result.append(other)
    return result

func list_goals_in_range(goals: Array, detection_range: float) -> Array:
    var result: Array = []
    for goal in goals:
        if goal == null:
            continue
        if not goal is Node2D:
            continue
        if global_position.distance_to(goal.global_position) <= detection_range:
            result.append(goal)
    return result

func act(target: Node2D) -> bool:
    if target == null:
        return false
    if not (target is Node2D):
        return false
    return global_position.distance_to(target.global_position) <= action_range

func _resolve_child(path: NodePath, type_class) -> Node:
    var node: Node = null
    if not path.is_empty() and has_node(path):
        node = get_node(path)
    if node == null:
        node = type_class.new()
        add_child(node)
    return node

func _on_item_equipped(item: InventoryItem) -> void:
    if _attributes == null or item == null:
        return
    var id := str(item.get_instance_id())
    _item_modifier_ids[item] = id
    _attributes.apply_modifier(id, item.attribute_modifiers)

func _on_item_unequipped(item: InventoryItem) -> void:
    if _attributes == null or item == null:
        return
    if not _item_modifier_ids.has(item):
        return
    var id = _item_modifier_ids[item]
    _attributes.remove_modifier(id)
    _item_modifier_ids.erase(item)
