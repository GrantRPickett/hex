extends GdUnitTestSuite

const AIController := preload("res://Gameplay/ai_controller.gd")
const TurnSystem := preload("res://Gameplay/turn_system.gd")
const GameCommandContext := preload("res://Gameplay/input_commands/game_command_context.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")
const UnitActionManager := preload("res://Gameplay/unit_action_manager.gd")
const DialogueActionService := preload("res://Gameplay/dialogue_action_service.gd")

class FakelocationManager extends RefCounted:
	var coords: Array
	func _init(location_coords: Array = []):
		coords = location_coords
	func get_location_count() -> int:
		return coords.size()
	func get_target(index: int) -> Vector2i:
		return coords[index]

class FakeUnitManager extends RefCounted:
	func is_occupied(_coord: Vector2i) -> bool:
		return false

class FakeIndexedUnitManager extends UnitManager:
	var _indices: Dictionary = {}
	func register_unit(unit, index: int) -> void:
		_indices[unit] = index
	func get_unit_index(unit) -> int:
		if _indices.has(unit):
			return _indices[unit]
		return super.get_unit_index(unit)

class FakeDialogueActionService extends DialogueActionService:
	var actions_to_append: Array[Dictionary] = []
	var last_start_payload: Dictionary = {}
	func append_dialogue_actions(actions: Array, _unit, _unit_manager) -> void:
		for entry in actions_to_append:
			actions.append(entry.duplicate(true))
	func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
		last_start_payload = {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index
		}
		return CommandResult.success()

class FakeTalkUnit extends RefCounted:
	var unit_name := "Speaker"
	var willpower := 5
	func has_action_available() -> bool:
		return true

class FakeTerrainMap extends RefCounted:
	var neighbor_map: Dictionary = {}
	var grid_width: int = 4
	var grid_height: int = 4
	var offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
	func _init(neighbors: Dictionary = {}, width: int = 4, height: int = 4):
		neighbor_map = neighbors.duplicate(true)
		grid_width = width
		grid_height = height
	func get_neighbors(coord: Vector2i) -> Array:
		return neighbor_map.get(coord, [])
	func get_offset_axis() -> int:
		return offset_axis

class FakeHostile extends RefCounted:
	var coord: Vector2i
	var unit_name := "Target"
	func _init(p_coord: Vector2i):
		coord = p_coord
	func get_grid_location() -> Vector2i:
		return coord

class FakeUnit extends RefCounted:
	var paths: Dictionary
	var hostiles: Array
	var faction := TurnSystem.Side.PLAYER
	var unit_name := "Unit"
	var willpower := 2
	func _init(p_paths: Dictionary = {}, p_hostiles: Array = []):
		paths = p_paths.duplicate(true)
		hostiles = p_hostiles.duplicate(true)
	func get_path_to_coord(coord: Vector2i, _terrain_map) -> Array:
		return paths.get(coord, [])
	func get_hostile_units() -> Array:
		return hostiles.duplicate(true)
	func get_grid_location() -> Vector2i:
		return Vector2i.ZERO
	@warning_ignore("native_method_override")
	func has_method(name: StringName) -> bool:
		return String(name) == "faction"

func test_fallback_location_action_returns_best_path() -> void:
	var controller: Variant = auto_free(AIController.new())
	controller._location_manager = FakelocationManager.new([
		Vector2i(4, 4)
	])
	var unit := FakeUnit.new({Vector2i(4, 4): [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]})
	var action: Variant = controller._fallback_location_action(unit, FakeTerrainMap.new())
	assert_object(action).is_not_null()
	assert_str(action.type).is_equal("move_to_location")
	assert_array(action.path).has_size(4)

func test_fallback_enemy_action_moves_toward_hostile() -> void:
	var controller: Variant = auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var hostile := FakeHostile.new(Vector2i(2, 0))
	var terrain: FakeTerrainMap = FakeTerrainMap.new({Vector2i(2, 0): [Vector2i(1, 0)]})
	var unit := FakeUnit.new({Vector2i(1, 0): [Vector2i(1, 0)]}, [hostile])
	var action: Variant = controller._fallback_enemy_action(unit, terrain)
	assert_object(action).is_not_null()
	assert_str(action.type).is_equal("move_to_enemy")
	assert_array(action.path).has_size(1)

func test_fallback_enemy_action_skips_neutral_units() -> void:
	var controller: Variant = auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var hostile := FakeHostile.new(Vector2i(2, 0))
	var terrain: FakeTerrainMap = FakeTerrainMap.new({Vector2i(2, 0): [Vector2i(1, 0)]})
	var unit := FakeUnit.new({Vector2i(1, 0): [Vector2i(1, 0)]}, [hostile])
	unit.faction = TurnSystem.Side.NEUTRAL
	var action: Variant = controller._fallback_enemy_action(unit, terrain, {}, true)
	assert_object(action).is_null()

func test_fallback_center_action_moves_toward_middle() -> void:
	var controller: Variant = auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var terrain: FakeTerrainMap = FakeTerrainMap.new({}, 4, 4)
	var center_coord := Vector2i(2, 2)
	var unit := FakeUnit.new({center_coord: [Vector2i(1, 0), center_coord]}, [])
	var action: Variant = controller._fallback_center_action(unit, terrain)
	assert_object(action).is_not_null()
	assert_str(action.type).is_equal(AIController.ACTION_MOVE_TO_CENTER)
	assert_array(action.path).is_not_empty()

class FakelocationLookupManager extends RefCounted:
	var _location
	func _init(location_instance):
		_location = location_instance
	func get_location_at_cell(cell: Vector2i):
		if _location and _location.coord == cell:
			return _location
		return null

class Fakelocation extends RefCounted:
	var coord: Vector2i
	func _init(p_coord: Vector2i):
		coord = p_coord
	func can_be_worked_on_by(_unit: Unit) -> bool:
		return true

class FakeLootPresence extends RefCounted:
	var loot_coord: Vector2i
	func _init(coord: Vector2i):
		loot_coord = coord
	func has_loot_at(coord: Vector2i) -> bool:
		return coord == loot_coord

class FakeSimpleUnit extends RefCounted:
	var coord: Vector2i
	func _init(p_coord: Vector2i = Vector2i.ZERO):
		coord = p_coord
	func get_grid_location() -> Vector2i:
		return coord

class FakeCombatUnit extends Unit:
	var _hostiles: Array
	var _adjacent: Array
	func _init(hostiles: Array = [], adjacent: Array = []):
		_hostiles = hostiles.duplicate(true)
		_adjacent = adjacent.duplicate(true)
	func get_hostile_units() -> Array[Unit]:
		return _hostiles.duplicate(true)
	func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
		var result: Array = []
		for unit in units:
			if _adjacent.has(unit):
				result.append(unit)
		return result
	func get_units_in_range(units: Array, detection_range: float) -> Array:
		return units.duplicate(true)
func test_promote_move_to_loot_sets_loot_action() -> void:
	var controller: Variant = auto_free(AIController.new())
	controller._loot_manager = FakeLootPresence.new(Vector2i(2, 1))
	var unit := FakeSimpleUnit.new(Vector2i(2, 1))
	var action: AIController.AIAction = AIController.AIAction.new(AIController.ACTION_MOVE_TO_LOOT, null, [], 0.0)
	controller._promote_move_action_followup(unit, action)
	assert_str(action.type).is_equal(AIController.ACTION_LOOT)
	assert_vector(action.target).is_equal(Vector2i(2, 1))

func test_promote_move_to_location_sets_location_target() -> void:
	var controller: Variant = auto_free(AIController.new())
	var location := Fakelocation.new(Vector2i(3, 0))
	controller._location_manager = FakelocationLookupManager.new(location)
	var unit := FakeSimpleUnit.new(Vector2i(3, 0))
	var action: AIController.AIAction = AIController.AIAction.new(AIController.ACTION_MOVE_TO_location, Vector2i(3, 0), [], 0.0)
	controller._promote_move_action_followup(unit, action)
	assert_str(action.type).is_equal(AIController.ACTION_WORK_ON_location)
	assert_object(action.target).is_equal(location)

func test_promote_move_to_enemy_sets_attack_action() -> void:
	var controller: Variant = auto_free(AIController.new())
	var enemy := FakeHostile.new(Vector2i(1, 0))
	var unit := FakeSimpleUnit.new(Vector2i.ZERO)
	var action: AIController.AIAction = AIController.AIAction.new(AIController.ACTION_MOVE_TO_ENEMY, enemy, [], 0.0)
	controller._promote_move_action_followup(unit, action)
	assert_str(action.type).is_equal(AIController.ACTION_ATTACK)
	assert_object(action.target).is_equal(enemy)

func test_find_enemy_actions_only_attacks_adjacent_targets() -> void:
	var controller: Variant = auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var adjacent: Unit = auto_free(Unit.new())
	adjacent.unit_name = "Adjacent"
	var distant: Unit = auto_free(Unit.new())
	distant.unit_name = "Distant"
	var unit: FakeCombatUnit = auto_free(FakeCombatUnit.new([adjacent, distant], [adjacent]))
	var actions: Array[AIController.AIAction] = []
	controller._find_enemy_actions(unit, Vector2i.ZERO, FakeTerrainMap.new(), actions)
	var attack_targets: Array = []
	for action in actions:
		if action.type == AIController.ACTION_ATTACK:
			attack_targets.append(action.target)
	assert_array(attack_targets).has_size(1)
	assert_object(attack_targets[0]).is_equal(adjacent)

func test_find_talk_actions_appends_ai_action() -> void:
	var controller: Variant = auto_free(AIController.new())
	var unit_manager := FakeIndexedUnitManager.new()
	var talk_unit := FakeTalkUnit.new()
	unit_manager.register_unit(talk_unit, 2)
	controller._unit_manager = unit_manager
	var dialogue_service := FakeDialogueActionService.new()
	dialogue_service.actions_to_append = [{
		"type": "talk",
		"initiator_index": 2,
		"target_index": 7,
		"dialogue_id": StringName("story_flag"),
		"available": true
	}]
	var context := GameCommandContext.new(unit_manager, null, null, null, null, null, null)
	context.dialogue_action_service = dialogue_service
	controller.set_command_context(context)
	var actions: Array[AIController.AIAction] = []
	controller._find_talk_actions(talk_unit, actions)
	assert_array(actions).has_size(1)
	var action: AIController.AIAction = actions[0]
	assert_str(action.type).is_equal(AIController.ACTION_TALK)
	var payload: Dictionary = action.target
	assert_int(payload.get("target_index", -1)).is_equal(7)
	assert_str(String(payload.get("dialogue_id"))).is_equal("story_flag")

func test_execute_unit_interaction_runs_talk_command() -> void:
	var controller: Variant = auto_free(AIController.new())
	var unit_manager := FakeIndexedUnitManager.new()
	var talk_unit := FakeTalkUnit.new()
	unit_manager.register_unit(talk_unit, 4)
	controller._unit_manager = unit_manager
	var dialogue_service := FakeDialogueActionService.new()
	var context := GameCommandContext.new(unit_manager, null, null, null, null, null, null)
	context.dialogue_action_service = dialogue_service
	controller.set_command_context(context)
	var talk_payload := {
		"dialogue_id": StringName("story_flag"),
		"initiator_index": 4,
		"target_index": 9
	}
	var action: AIController.AIAction = AIController.AIAction.new(AIController.ACTION_TALK, talk_payload, [], 0.0)
	var result: bool = controller._execute_unit_interaction(talk_unit, action)
	assert_bool(result).is_true()
	assert_int(dialogue_service.last_start_payload.get("target_index", -1)).is_equal(9)

func test_find_talk_actions_uses_global_service_when_context_missing() -> void:
	var controller: Variant = auto_free(AIController.new())
	var unit_manager := FakeIndexedUnitManager.new()
	var talk_unit := FakeTalkUnit.new()
	unit_manager.register_unit(talk_unit, 3)
	controller._unit_manager = unit_manager
	controller.set_command_context(null)
	var dialogue_service := FakeDialogueActionService.new()
	dialogue_service.actions_to_append = [{
		"type": "talk",
		"initiator_index": 3,
		"target_index": 1,
		"dialogue_id": StringName("story_flag"),
		"available": true
	}]
	UnitActionManager.set_dialogue_service(dialogue_service)
	var actions: Array[AIController.AIAction] = []
	controller._find_talk_actions(talk_unit, actions)
	assert_array(actions).has_size(1)
	assert_object(UnitActionManager.get_dialogue_service()).is_equal(dialogue_service)
	UnitActionManager.set_dialogue_service(null)
	assert_object(UnitActionManager.get_dialogue_service()).is_null()

