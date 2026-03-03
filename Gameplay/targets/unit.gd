class_name Unit
extends Target

signal willpower_changed(unit: Unit)
signal components_ready

const FREE_ROAM_MOVEMENT_POINTS := 999999


enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL
}


@export var unit_name: String = ""
@export var faction: Faction = Faction.PLAYER
@export var action_range: float = 1.5 # Changed to grid units (1.5 covers adjacent hexes)
@export var inventory_component_template: Resource = InventoryComponent.new()
@export var action_points_template: Resource = ActionPointsComponent.new()
@export var movement_range_cache_template: Resource = MovementRangeCache.new()
@export var saved_items: Array[InventoryItem] = []
@export var neutral_can_be_persuaded: bool = false
@export var neutral_can_rally_allies: bool = false
@export var stress: int = 0
@export var is_dead: bool = false
@export var combat_priority_profile: CombatPriorityProfile


var skills: Array[Skill] = []
var _movement_cache: MovementRangeCache
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _combat_system: CombatSystem
var _animation_service: AnimationRequestService
var consumables_active: Dictionary

var _leader_faction: int = -1
var _setup_finalized: bool = false


# Behavior components
var combat: UnitCombatBehavior
var movement: UnitMovementBehavior
var interaction: UnitInteractionHandler
var death: UnitDeathHandler
var query: UnitQueryService
var loyalty: UnitLoyaltyComponent
var status: UnitStatusComponent

var inv: InventoryComponent
var res: ActionPointsComponent


func _init() -> void:
	if action_points_template == null:
		action_points_template = ActionPointsComponent.new()
	res = action_points_template.duplicate(true)
	if res == null:
		res = ActionPointsComponent.new()


var willpower: int:
	get:
		return res.get_willpower()

	set(value):
		res.set_willpower(value)
		if res.get_willpower() <= 0:
			_die()


var max_willpower: int:
	get:
		return res.get_max_willpower()

	set(value):
		res.set_max_willpower(value)


var movement_points: int:
	get:
		return movement.get_remaining_movement_points()

	set(value):
		res.set_movement_points(value)
		if _movement_cache:
			_movement_cache.invalidate()


func _ready() -> void:
	UnitComponentFactory.create_components(self )

	skills = [] # of Skill
	consumables_active = {}

	if _animation_service and death:
		death.set_animation_service(_animation_service)

	if res:
		res.willpower_changed.connect(_on_action_points_willpower_changed)

	if not saved_items.is_empty():
		for item in saved_items:
			if item == null:
				continue
			var regenerate_uuid := not item.resource_path.is_empty()
			var item_instance := item.duplicate_instance(regenerate_uuid)
			if item_instance == null:
				continue
			if item_instance.equipped:
				inv.equip_item(item_instance)
			else:
				inv.add_item_to_inventory(item_instance)

		saved_items.clear()

	refresh_for_new_round()

	if not _setup_finalized:
		finalize_setup()

func _on_action_points_willpower_changed() -> void:
	willpower_changed.emit(self )


func _exit_tree() -> void:
	if inv:
		inv.cleanup()

	if _movement_cache:
		_movement_cache.cleanup()


func set_unit_manager(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager

	if _movement_cache:
		_movement_cache.set_unit_manager(unit_manager)

	if death:
		death.set_unit_manager(unit_manager)


func get_unit_manager() -> UnitManager:
	return _unit_manager

func set_animation_service(service) -> void:
	_animation_service = service
	if death:
		death.set_animation_service(service)


func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

	if interaction:
		interaction.set_loot_manager(manager)

	if death:
		death.set_loot_manager(manager)


func set_task_manager(manager: TaskManager) -> void:
	_task_manager = manager

	if interaction:
		interaction.set_task_manager(manager)


func get_task_manager() -> TaskManager:
	return _task_manager


func get_loot_manager() -> LootManager:
	return _loot_manager


func set_combat_system(system: CombatSystem) -> void:
	_combat_system = system

	if combat:
		combat.set_combat_system(system)


func get_combat_system() -> CombatSystem:
	return _combat_system


func get_attribute(attr_name: String) -> int:
	var attrs = inv.get_attributes() if inv else null
	if attrs:
		return attrs.get_attribute(attr_name)
	return super.get_attribute(attr_name)


func add_skill(skill: Skill) -> void:
	if skill == null:
		return

	if not skills.has(skill):
		skills.append(skill)


func remove_skill(skill: Skill) -> void:
	skills.erase(skill)

	skill.on_unequip(self )


func get_combat_profile() -> CombatPriorityProfile:
	if combat_priority_profile == null:
		if not Unit._default_combat_profile:
			Unit._default_combat_profile = CombatPriorityProfile.new()
		return Unit._default_combat_profile
	return combat_priority_profile

static var _default_combat_profile: CombatPriorityProfile


func is_at_full_willpower() -> bool:
	if max_willpower <= 0:
		return true

	return willpower >= max_willpower


func refresh_for_new_round() -> void:
	if res:
		res.refresh_for_new_round()

	if _movement_cache:
		_movement_cache.invalidate()

	if movement:
		movement.refresh_for_new_round()

	if query:
		query.invalidate_cache()


func set_free_roam_mode(enabled: bool) -> void:
	if is_in_free_roam_mode() == enabled:
		return
	if movement:
		movement.set_free_roam_mode(enabled)
	if res:
		res.refresh_for_new_round()
	if _movement_cache:
		_movement_cache.invalidate()

func is_in_free_roam_mode() -> bool:
	return movement.is_free_roam_mode() if movement else false


func is_faction_leader(p_faction: int) -> bool:
	return _leader_faction == p_faction and p_faction >= 0


func set_faction_leader(p_faction: int, enabled: bool) -> void:
	if p_faction < 0:
		return
	if enabled:
		_leader_faction = p_faction
	else:
		if _leader_faction == p_faction:
			_leader_faction = -1


func is_player_leader() -> bool:
	return is_faction_leader(Unit.Faction.PLAYER)


func set_player_leader(enabled: bool) -> void:
	set_faction_leader(Unit.Faction.PLAYER, enabled)


func _die() -> void:
	death.die()


func apply_consumable(pair_index: int, bonus: int) -> void:
	consumables_active[pair_index] = bonus


func prepare_for_save() -> void:
	if res:
		action_points_template = res.duplicate(true)


	var current_inv := inv.get_inventory() if inv else null

	if current_inv:
		saved_items = current_inv.get_items()


func get_hover_info() -> String:
	return UnitPresenter.get_hover_info(self )


func finalize_setup() -> void:
	if _setup_finalized:
		return
	_setup_finalized = true
	components_ready.emit()
