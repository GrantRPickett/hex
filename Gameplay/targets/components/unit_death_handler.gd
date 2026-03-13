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

var _unit: Unit
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

	# Check difficulty on the save file
	var difficulty = GameConstants.Settings.DIFFICULTY_NORMAL
	if SaveManager:
		difficulty = SaveManager.get_value("difficulty", GameConstants.Settings.DIFFICULTY_NORMAL)

	var should_retreat := false
	if _unit.faction == Unit.Faction.PLAYER:
		match difficulty:
			GameConstants.Settings.DIFFICULTY_EASY:
				should_retreat = true
			GameConstants.Settings.DIFFICULTY_NORMAL:
				_unit.stress += 1
				should_retreat = true
			GameConstants.Settings.DIFFICULTY_HARD:
				_unit.stress += 6
				_unit.is_dead = true
				should_retreat = false

	if should_retreat:
		_is_dying = true
		if RosterManager:
			RosterManager.sync_unit(_unit)
		if _unit_manager and _unit_manager.has_method("mark_retreat"):
			_unit_manager.mark_retreat(_unit)
		return

	# If not retreating, it's a permanent death (Player on Hard, Enemy, or Neutral)
	_is_dying = true

	# For dead player units (Hard), sync to roster so they are removed/erased
	if _unit.faction == Unit.Faction.PLAYER and RosterManager:
		RosterManager.sync_unit(_unit)

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

	var inventory = _unit.inv.get_inventory()
	if inventory == null:
		return

	_drop_quest_items(inventory)
	
	if _should_drop_standard_loot():
		_drop_inventory()
	else:
		_route_remaining_items(inventory)

func _should_drop_standard_loot() -> bool:
	var difficulty = _get_current_difficulty()
	
	if _unit.faction == Unit.Faction.ENEMY:
		return difficulty == GameConstants.Settings.DIFFICULTY_EASY
		
	if _unit.faction == Unit.Faction.NEUTRAL:
		return difficulty != GameConstants.Settings.DIFFICULTY_HARD
		
	return true

func _get_current_difficulty() -> String:
	if SaveManager:
		return String(SaveManager.get_value("difficulty", GameConstants.Settings.DIFFICULTY_NORMAL))
	return GameConstants.Settings.DIFFICULTY_NORMAL

func _drop_quest_items(inventory: UnitInventory) -> void:
	var quest_items = inventory.get_items().filter(func(i): return i.is_quest_item())
	if quest_items.is_empty():
		return
		
	_loot_manager.spawn_loot(_unit.get_grid_location(), quest_items)
	for item in quest_items:
		_unit.inv.remove_item_from_inventory(item)

func _route_remaining_items(inventory: UnitInventory) -> void:
	var remaining = inventory.get_items()
	if remaining.is_empty():
		return
		
	if _loot_manager.has_method("add_to_routing_pool"):
		_loot_manager.add_to_routing_pool(remaining)
	inventory.clear()


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

