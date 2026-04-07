class_name Unit
extends Target

signal aid_buffs_changed(total: int)
signal attribute_modifiers_changed()
signal components_ready

const FREE_ROAM_MOVEMENT_POINTS := 999999

const FACTION = GameConstants.Faction

@export var unit_name: String = ""
@export var faction: FACTION = FACTION.PLAYER
@export var action_range: int = 1 # Grid units (1 covers adjacent hexes)
@export var inventory_component_template: Resource = InventoryComponent.new()
@export var action_points_template: Resource = ActionPointsComponent.new()
@export var movement_range_cache_template: Resource = MovementRangeCache.new()
@export var threat_cache_template: Resource = ThreatCache.new()
@export var saved_items: Array[InventoryItem] = []
@export var neutral_can_be_persuaded: bool = true
@export var neutral_can_rally_allies: bool = false
@export var loyalty_type: GameConstants.Faction = GameConstants.Faction.NEUTRAL
@export var aid_buffs: PackedInt32Array = [0, 0, 0]
@export var max_willpower_value: int = 10

@export var is_dead: bool = false
@export var combat_priority_profile: CombatPriorityProfile

@export_group("Visuals")
@export var use_region: bool = true
@export var region_rect: Rect2 = Rect2(0, 0, 32, 32)
@export var master_texture: Texture2D
@export var spawn_index: int = -1


var skills: Array[Skill] = []
var _movement_cache: MovementRangeCache
var _threat_cache: ThreatCache
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _location_service: LocationService
var _combat_system: CombatSystem
var _animation_service: AnimationRequestService
var consumables_active: Dictionary

var _leader_faction: int = -1
var _setup_finalized: bool = false
var _attribute_cache: Dictionary = {}
var _attribute_cache_dirty: bool = true


# Behavior components
var combat: UnitCombatBehavior
var movement: UnitMovementBehavior
var interaction: TargetInteractionHandler
var death: UnitDeathHandler
var query: UnitQueryService
var loyalty: UnitLoyaltyComponent
var status: UnitStatusComponent

var inv: InventoryComponent
var res: ActionPointsComponent


func get_effective_faction() -> int:
	if faction == FACTION.NEUTRAL and is_instance_valid(loyalty):
		if loyalty.neutral_loyalty != FACTION.NEUTRAL:
			return loyalty.neutral_loyalty
	return faction


func _init() -> void:
	if action_points_template == null:
		action_points_template = ActionPointsComponent.new()
	res = action_points_template.duplicate(true)
	if res == null:
		res = ActionPointsComponent.new()


var max_willpower: int:
	get:
		return max_willpower_value

	set(value):
		max_willpower_value = value
		base_willpower = value


var movement_points: int:
	get:
		if movement:
			return movement.get_remaining_movement_points()
		return 0

	set(value):
		if res: res.set_movement_points(value)
		if _movement_cache:
			_movement_cache.invalidate()
		if _threat_cache:
			_threat_cache.invalidate()


func _ready() -> void:
	super ()
	base_willpower = max_willpower_value
	willpower = max_willpower_value
	if not willpower_changed.is_connected(_on_willpower_changed):
		willpower_changed.connect(_on_willpower_changed)
	if not attribute_modifiers_changed.is_connected(_sync_max_willpower):
		attribute_modifiers_changed.connect(_sync_max_willpower)

	refresh_is_opposed()

	if res:
		res.set_owner_unit(self )
		if not res.action_consumed.is_connected(consume_aid_buffs):
			res.action_consumed.connect(consume_aid_buffs)

	if not attribute_modifiers_changed.is_connected(_invalidate_attribute_cache):
		attribute_modifiers_changed.connect(_invalidate_attribute_cache)
	if not aid_buffs_changed.is_connected(_on_aid_buffs_changed_for_cache):
		aid_buffs_changed.connect(_on_aid_buffs_changed_for_cache)
	if EventBus and not EventBus.weather_changed.is_connected(_on_weather_changed_for_cache):
		EventBus.weather_changed.connect(_on_weather_changed_for_cache)
	if EventBus and not EventBus.locations_updated.is_connected(_invalidate_attribute_cache):
		EventBus.locations_updated.connect(_invalidate_attribute_cache)
	if EventBus and not attribute_modifiers_changed.is_connected(_on_attribute_modifiers_changed):
		attribute_modifiers_changed.connect(_on_attribute_modifiers_changed)

	UnitComponentFactory.create_components(self )
	z_index = GameConstants.ZIndex.UNIT
	_ensure_sprite_setup()
	update_visuals()

	skills = [] # of Skill
	consumables_active = {}

	if _animation_service and death:
		death.set_animation_service(_animation_service)

	if not saved_items.is_empty():
		if inv:
			inv.clear()
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

func _ensure_sprite_setup() -> void:
	if not is_instance_valid(sprite):
		sprite = get_node_or_null("Sprite2D")

	if not is_instance_valid(sprite):
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	if sprite is Sprite2D:
		if master_texture:
			sprite.texture = master_texture
		else:
			# Default based on faction
			var tex_path := "res://Resources/art/placeholder/32rogues/rogues.png"
			if faction == FACTION.ENEMY:
				tex_path = "res://Resources/art/placeholder/32rogues/monsters.png"

			var current_path: String = ""
			if sprite.texture:
				current_path = sprite.texture.resource_path

			if current_path == "" or current_path.find("sliced") != -1:
				GameLogger.debug(GameLogger.Category.MAP, "Unit %s (%s): Loading texture %s" % [unit_name, id, tex_path])
				sprite.texture = load(tex_path)

		sprite.region_enabled = use_region
		if "scale" in sprite:
			sprite.scale = Vector2(2, 2) # Reset scale if it was 2x for the sliced version
		sprite.centered = true

func update_visuals() -> void:
	if not is_instance_valid(sprite) or not sprite.region_enabled:
		GameLogger.debug(GameLogger.Category.MAP, "Unit %s (%s): Sprite invalid or region disabled" % [unit_name, id])
		return

	if region_rect != Rect2(0, 0, 32, 32):
		GameLogger.debug(GameLogger.Category.MAP, "Unit %s (%s): Using custom region_rect %s" % [unit_name, id, region_rect])
		sprite.region_rect = region_rect
		return

	# Fallback/Default logic with consistent "randomization" based on name/ID
	var seed_val = unit_name.hash() + id.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	var tex = sprite.texture
	var tex_size = tex.get_size() if tex else Vector2.ZERO
	var max_cols = int(tex_size.x / 32)
	var max_rows = int(tex_size.y / 32)

	if faction == FACTION.ENEMY:
		# Use Row 6 (y=160) from monsters.png.
		var row_idx = 5 # 0-indexed row 6
		if row_idx >= max_rows:
			GameLogger.error(GameLogger.Category.MAP, "Unit %s (%s): ROW 6 requested but texture %s only has %d rows" % [unit_name, id, tex.resource_path if tex else "NULL", max_rows])
			return

		var col_count = clampi(max_cols, 0, 5) # Expect up to 5 (a-e)
		var col_idx = rng.randi_range(0, col_count - 1)
		sprite.region_rect = Rect2(col_idx * 32, row_idx * 32, 32, 32)

	elif faction == FACTION.NEUTRAL:
		# Use Row 6 (y=160) and Row 7 (y=192) from rogues.png.
		# Check if rows exist
		if max_rows < 6:
			GameLogger.error(GameLogger.Category.MAP, "Unit %s (%s): Neutral rows 6/7 requested but texture %s only has %d rows" % [unit_name, id, tex.resource_path if tex else "NULL", max_rows])
			return

		var sprites_per_row = 6
		var total_available = sprites_per_row * min(2, max_rows - 5)
		if total_available <= 0:
			GameLogger.error(GameLogger.Category.MAP, "Unit %s (%s): No neutral sprites available in texture %s" % [unit_name, id, tex.resource_path if tex else "NULL"])
			return

		var sprite_idx: int = spawn_index if spawn_index >= 0 else rng.randi_range(0, total_available - 1)
		sprite_idx = sprite_idx % total_available # Wrap around if spawn_index is large

		# GDScript 2.0 integer division is fine, but being explicit to quell lints
		var row_offset: int = 5 + int(float(sprite_idx) / sprites_per_row)
		var col_offset: int = sprite_idx % sprites_per_row

		if col_offset >= max_cols:
			GameLogger.error(GameLogger.Category.MAP, "Unit %s (%s): Sprite column %d exceeds texture width %d" % [unit_name, id, col_offset, max_cols])
			sprite.region_rect = Rect2(0, row_offset * 32, 32, 32) # Fallback to col 0
		else:
			sprite.region_rect = Rect2(col_offset * 32, row_offset * 32, 32, 32)

		GameLogger.debug(GameLogger.Category.MAP, "Unit %s (%s): Assigned Neutral sprite index %d (Row %d, Col %d), rect %s" % [unit_name, id, sprite_idx, row_offset + 1, col_offset, sprite.region_rect])

	# Apply neutral tints
	if faction == FACTION.NEUTRAL:
		if loyalty_type == FACTION.STATIC:
			sprite.modulate = GameColors.YELLOW
		else:
			sprite.modulate = GameColors.WHITE
	else:
		sprite.modulate = GameColors.WHITE


func _sync_max_willpower() -> void:
	pass


func _on_willpower_changed(_target: Target) -> void:
	if willpower <= 0:
		_die()


func _on_attribute_modifiers_changed() -> void:
	if EventBus:
		EventBus.unit_attributes_changed.emit(self)


func _exit_tree() -> void:
	if inv:
		inv.cleanup()

	if _movement_cache:
		_movement_cache.cleanup()
	if _threat_cache:
		_threat_cache.cleanup()


func set_unit_manager(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager

	if interaction:
		interaction.set_unit_manager(unit_manager)

	if _movement_cache:
		_movement_cache.set_unit_manager(unit_manager)
	if _threat_cache:
		_threat_cache.set_unit_manager(unit_manager)

	if death:
		death.set_unit_manager(unit_manager)


var _attribute_modifiers: Dictionary = {} # source_id -> { "grit": 1, ... }
var ignore_weather: bool = false

func apply_attribute_modifier(source_id: String, modifiers: Dictionary) -> void:
	if source_id.is_empty(): return
	_attribute_modifiers[source_id] = modifiers.duplicate(true)
	attribute_modifiers_changed.emit()

func remove_attribute_modifier(source_id: String) -> void:
	if _attribute_modifiers.has(source_id):
		_attribute_modifiers.erase(source_id)
		attribute_modifiers_changed.emit()

func _invalidate_attribute_cache() -> void:
	_attribute_cache_dirty = true
	_attribute_cache.clear()

func _on_aid_buffs_changed_for_cache(_total: int) -> void:
	_invalidate_attribute_cache()

func _on_weather_changed_for_cache(_weather: Dictionary) -> void:
	_invalidate_attribute_cache()

func get_attribute_modifiers() -> Dictionary:
	return _attribute_modifiers

func get_base_attribute_from_target(idx: GameConstants.AttributeIndex) -> int:
	return super.get_attribute(idx)

func get_attribute(idx: GameConstants.AttributeIndex) -> int:
	if not _attribute_cache_dirty and _attribute_cache.has(int(idx)):
		return _attribute_cache[int(idx)]

	var base = get_base_attribute_from_target(idx)
	var bonus = query.get_attribute_bonus(idx) if query else 0
	var total = base + bonus

	_attribute_cache[int(idx)] = total
	# Once all 6 attributes are cached, we can technically clear the dirty flag
	# but simple per-index caching is safer for partial lookups.
	if _attribute_cache.size() >= 6:
		_attribute_cache_dirty = false

	if is_in_group("player"):
		GameLogger.debug(GameLogger.Category.COMBAT, "[UnitAttr] Unit: %s, Attr: %s, Base: %d, Bonus: %d, Total: %d (Cached)" % [
			unit_name if "unit_name" in self else "Unknown",
			GameConstants.get_attribute_name(idx),
			base,
			bonus,
			total
		])
	return total

## Convenience method for string-based attribute lookup
func get_attribute_by_name(attr_name: String) -> int:
	var idx = GameConstants.get_attribute_index(attr_name)
	return get_attribute(idx)


func get_attribute_by_index(idx: GameConstants.AttributeIndex) -> int:
	if idx < 0 or idx > 6:
		return 0
	return get_attribute(idx as GameConstants.AttributeIndex)


func get_unit_manager() -> UnitManager:
	return _unit_manager

func set_animation_service(service) -> void:
	_animation_service = service
	if death:
		death.set_animation_service(service)


func set_task_manager(manager: TaskManager) -> void:
	_task_manager = manager

	if interaction:
		interaction.set_task_manager(manager)


func get_task_manager() -> TaskManager:
	return _task_manager


func set_location_service(service: LocationService) -> void:
	_location_service = service

	if interaction:
		interaction.set_location_service(service)


func get_location_service() -> LocationService:
	return _location_service


func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

	if interaction:
		interaction.set_loot_manager(manager)

	if death:
		death.set_loot_manager(manager)


func get_loot_manager() -> LootManager:
	return _loot_manager


func set_combat_system(system: CombatSystem) -> void:
	_combat_system = system

	if combat:
		combat.set_combat_system(system)


func get_combat_system() -> CombatSystem:
	return _combat_system


func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]:
	return query.get_units_in_range_without_full_morale(units, detection_range) if query else []


func is_at_full_morale() -> bool:
	return is_at_full_willpower()


func adjust_remaining_movement(amount: int) -> void:
	if movement:
		movement.adjust_remaining_movement(amount)


func on_enter_terrain(terrain: Variant) -> void:
	if movement:
		movement.on_enter_terrain(terrain)


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
		if not _default_combat_profile:
			_default_combat_profile = CombatPriorityProfile.new()
		return _default_combat_profile
	return combat_priority_profile

static var _default_combat_profile: CombatPriorityProfile


func is_at_full_willpower() -> bool:
	if max_willpower <= 0:
		return true

	return willpower >= max_willpower


func refresh_for_new_round() -> void:
	if res:
		res.refresh_for_new_round()

	consume_aid_buffs()

	if _movement_cache:
		_movement_cache.invalidate()
	if _threat_cache:
		_threat_cache.invalidate()

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
	if _threat_cache:
		_threat_cache.invalidate()

func is_in_free_roam_mode() -> bool:
	return movement.is_free_roam_mode() if movement else false


func consume_action() -> void:
	if is_in_free_roam_mode():
		return
	if res:
		res.consume_action()


func block_movement_this_turn() -> void:
	if res:
		res.block_movement_this_turn()


func block_action_this_turn() -> void:
	if res:
		res.block_action_this_turn()


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
	return is_faction_leader(FACTION.PLAYER)


func set_player_leader(enabled: bool) -> void:
	set_faction_leader(FACTION.PLAYER, enabled)


func is_friendly(other: Unit) -> bool:
	if not is_instance_valid(other) or other == self:
		return false

	if other.faction == faction:
		return true

	if other.faction == FACTION.NEUTRAL:
		return other.loyalty and other.loyalty.neutral_loyalty == faction

	if faction == FACTION.NEUTRAL:
		return loyalty and loyalty.neutral_loyalty == other.faction

	return false


func is_hostile(other: Unit) -> bool:
	if not is_instance_valid(other) or other == self:
		return false

	if is_friendly(other):
		return false

	if faction == FACTION.NEUTRAL:
		if loyalty == null or loyalty.neutral_loyalty == FACTION.NEUTRAL:
			return other.faction != FACTION.NEUTRAL
		return other.faction != FACTION.NEUTRAL and other.faction != loyalty.neutral_loyalty

	if other.faction == FACTION.NEUTRAL:
		return other.loyalty == null or other.loyalty.neutral_loyalty != faction

	return true


func _die() -> void:
	if death:
		death.die()
	else:
		# Fallback if component missing
		is_dead = true
		queue_free()


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


func get_current_willpower() -> int:
	return willpower

func get_max_willpower() -> int:
	return max_willpower

func get_target_name() -> String:
	return unit_name if not unit_name.is_empty() else id

func get_target_id() -> String:
	return id

func get_subtype_prefix() -> String:
	return get_script().get_global_name().to_lower()


func get_interaction_type() -> String:
	if is_opposed:
		return GameConstants.Activity.FIGHT
	if faction == FACTION.NEUTRAL and TargetDiscoveryService.is_convincable(self ):
		return GameConstants.Activity.CONVINCE
	return GameConstants.Activity.FIGHT

func refresh_is_opposed() -> void:
	if faction == FACTION.ENEMY:
		is_opposed = true
	elif faction == FACTION.PLAYER:
		is_opposed = false
	elif faction == FACTION.NEUTRAL:
		if is_instance_valid(loyalty) and \
		   (loyalty.loyalty_type == FACTION.STATIC or \
		    loyalty.neutral_loyalty == FACTION.ENEMY):
			is_opposed = true
		else:
			is_opposed = false
	else:
		is_opposed = false


func get_aid_buff(pair_index: int) -> int:
	if pair_index >= 0 and pair_index < aid_buffs.size():
		return aid_buffs[pair_index]
	return 0


func add_aid_buff(p_value: int, pair_index: int = GameConstants.INVALID_INDEX) -> void:
	if pair_index == GameConstants.INVALID_INDEX:
		# Apply to all (legacy or special)
		for i in range(aid_buffs.size()):
			aid_buffs[i] += p_value
	elif pair_index >= 0 and pair_index < aid_buffs.size():
		aid_buffs[pair_index] += p_value

	var total: int = 0
	for b in aid_buffs: total += b
	aid_buffs_changed.emit(total)


func consume_aid_buffs() -> void:
	var total: int = 0
	for b in aid_buffs: total += b

	if total > 0:
		aid_buffs = PackedInt32Array([0, 0, 0])
		aid_buffs_changed.emit(0)
