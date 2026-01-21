class_name UnitDeathHandler
extends RefCounted

## Component responsible for handling unit death and cleanup.
##
## This component handles:
## - Death sequence and animation
## - Loot dropping on death
## - Inventory cleanup
## - Skill dropping
## - Unit manager notification

var _unit # Unit (type hint removed to avoid circular dependency)
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _is_dying: bool = false

func _init(unit: Unit) -> void:
	_unit = unit

func set_unit_manager(manager: UnitManager) -> void:
	_unit_manager = manager

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

## Initiates the death sequence for the unit
func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	_drop_loot()

	if _unit.sprite:
		var tween: Tween = _unit.create_tween()
		tween.tween_property(_unit.sprite, "rotation_degrees", 180.0, 0.5)
		tween.tween_callback(func():
			if _unit_manager:
				_unit_manager.remove_unit(_unit)
			else:
				_unit.queue_free()
		)
	elif _unit_manager:
		_unit_manager.remove_unit(_unit)
	else:
		_unit.queue_free()

## Checks if the unit is currently in the dying state
func is_dying() -> bool:
	return _is_dying

## Private: Drops loot when the unit dies
func _drop_loot() -> void:
	if _loot_manager == null:
		return

	var inventory_ref: UnitInventory = _unit.get_inventory()
	if inventory_ref == null:
		return

	_drop_inventory()

## Private: Drops the unit's inventory as loot
func _drop_inventory() -> void:
	if _loot_manager == null:
		return

	var inventory_ref: UnitInventory = _unit.get_inventory()
	if inventory_ref == null:
		return

	# Drop Inventory
	# 	Skills don't drop in this implementation
	# 	Consider a separate drop-skills method or drop chance per-skill

	var items: Array[InventoryItem] = inventory_ref.get_items()
	if not items.is_empty():
		_loot_manager.spawn_loot(_unit.get_grid_location(), items)
		inventory_ref.clear()

# ## Private: Handles skill cleanup on death
# func _drop_skills() -> void:
# 	# For each skill, trigger any drop effects (if skills can be dropped)
# 	for skill in _unit.skills:
# 		skill.on_unequip(_unit)

# 	# Clear Skills
# 	_unit.skills.clear()
