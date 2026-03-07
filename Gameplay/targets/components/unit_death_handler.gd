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
var _animation_service
const DEATH_ANIMATION_STYLE := StringName("unit_death_rotate")
var _is_dying: bool = false

func _init(unit: Unit) -> void:
	_unit = unit

func set_unit_manager(manager: UnitManager) -> void:
	_unit_manager = manager

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

func set_animation_service(service) -> void:
	_animation_service = service

## Initiates the death sequence for the unit
func die() -> void:
	if _is_dying:
		return

	# Check difficulty on the save file (easy/explorer, medium/adventurer, hard/survivor)
	# Default to "normal" (medium/adventurer) if not set.
	var difficulty = "normal"
	if SaveManager:
		difficulty = SaveManager.get_value("difficulty", "normal")

	if _unit.faction == Unit.Faction.PLAYER:
		match difficulty:
			"easy", "explorer":
				pass # Units retreat
			"hard", "survivor":
				_unit.stress += 6
				_unit.is_dead = true
			_: # "medium", "adventurer", "normal"
				_unit.stress += 1
				# TODO: Check if medium can toggle permadeath at 6 stress.

	_is_dying = true
	_drop_loot()

	if _unit.sprite:
		if _animation_service:
			_animation_service.request_property_animation(_unit.sprite, "rotation_degrees", 180.0, DEATH_ANIMATION_STYLE, Callable(self , "_finalize_death"))
		else:
			_finalize_death()
	else:
		_finalize_death()

## Checks if the unit is currently in the dying state
func is_dying() -> bool:
	return _is_dying

## Private: Drops loot when the unit dies
func _drop_loot() -> void:
	if _loot_manager == null:
		return

	# Check difficulty
	var difficulty = "normal"
	if SaveManager:
		difficulty = SaveManager.get_value("difficulty", "normal")

	var should_drop = true

	# Spec: Difficulty-scaled Loot Rules
	# Easy: All loot dropped.
	# Mid: Neutral loot dropped, enemy loot requires routing.
	# Hard: No enemy or neutral loot without routing.
	if _unit.faction == Unit.Faction.ENEMY:
		if difficulty == "easy" or difficulty == "explorer":
			should_drop = true
		else: # Mid and Hard both require routing for enemy loot
			should_drop = false
	elif _unit.faction == Unit.Faction.NEUTRAL:
		if difficulty == "hard" or difficulty == "survivor":
			should_drop = false
		else:
			should_drop = true

	# Always drop quest items, regardless of difficulty or faction
	var inventory_ref: UnitInventory = _unit.inv.get_inventory()
	if inventory_ref:
		var all_items = inventory_ref.get_items()
		var quest_items = all_items.filter(func(i): return i.quest)
		if not quest_items.is_empty():
			_loot_manager.spawn_loot(_unit.get_grid_location(), quest_items)
			for qi in quest_items:
				_unit.inv.remove_item(qi)
			# Refresh the list for the following difficulty logic
			all_items = inventory_ref.get_items()

	if not should_drop:
		if inventory_ref:
			if _loot_manager.has_method("add_to_routing_pool"):
				_loot_manager.add_to_routing_pool(inventory_ref.get_items())
			inventory_ref.clear()
		return

	_drop_inventory()

## Private: Drops the unit's inventory as loot
func _drop_inventory() -> void:
	if _loot_manager == null:
		return

	var inventory_ref: UnitInventory = _unit.inv.get_inventory()
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

func _finalize_death() -> void:
	if _unit_manager:
		_unit_manager.remove_unit(_unit)
	else:
		_unit.queue_free()
