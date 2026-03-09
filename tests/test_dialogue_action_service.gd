extends GdUnitTestSuite

const DialogueActionService := preload("res://Gameplay/narrative/dialogue/dialogue_action_service.gd")
const DialogueTrigger := preload("res://Gameplay/narrative/dialogue/dialogue_trigger.gd")
const DialogueTriggerGroup := preload("res://Gameplay/narrative/dialogue/dialogue_trigger_group.gd")
const LevelClass := preload("res://level/Level.gd")
const LevelDialogueEntry := preload("res://level/level_dialogue_entry.gd")
const UnitManagerClass := preload("res://Gameplay/targets/unit_manager.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")

func _create_trigger(coord: Vector2i, initiator: StringName, partner: StringName, group_id: StringName = StringName(""), allow_partner_initiation := false) -> DialogueTrigger:
	var entry := LevelDialogueEntry.new()
	entry.coord = coord
	entry.initiator_name = initiator
	entry.partner_name = partner
	entry.dialogue_resource_path = "res://Resources/level_data/dialogue_rows/example_dialogue.dialogue"
	entry.group_id = group_id
	entry.allow_partner_initiation = allow_partner_initiation
	var trigger := DialogueTrigger.new()
	trigger.configure_from_entry(entry)
	return trigger

func _prepare_service() -> DialogueActionService:
	var service := DialogueActionService.new()
	var unit_manager := UnitManagerClass.new()

	# Mock state for setup
	var mock_state = {
		"unit_manager": unit_manager,
		"hud": null,
		"hud_controller": null,
		"input_controller": null,
		"save_manager": null,
		"dialogue_action_service": service,
		"grid_visuals": null,
		"terrain_map": null,
		"binding_service": auto_free(InputBindingService.new()),
		"command_context": null,
		"command_router": null
	}

	var config = GameSessionBuilder.Config.new()
	config.grid = TileMapLayer.new()

	service.setup(mock_state as GameState, config)
	service.prepare_for_level(LevelClass.new())
	return service

func test_append_dialogue_actions_adds_talk_entry() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout: Stubs.FakeUnit = Stubs.FakeUnit.new()
	scout.unit_name = "Scout"
	scout.faction = UnitClass.Faction.PLAYER
	scout.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = Stubs.FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = UnitClass.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, "Scout", "Monk")
	service.register_triggers([trigger])
	var actions: Array[Dictionary] = []
	service.append_dialogue_actions(actions, scout, unit_manager)
	assert_that(actions.size()).is_equal(1)
	var action := actions[0]
	assert_that(action.get("type")).is_equal("talk")
	assert_that(action.get("target_index")).is_equal(unit_manager.get_unit_index(monk))
	assert_that(action.get("dialogue_id")).is_equal(trigger.get_dialogue_id())

func test_start_dialogue_consumes_action_and_sets_flag() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout: Stubs.FakeUnit = Stubs.FakeUnit.new()
	scout.unit_name = "Scout"
	scout.faction = UnitClass.Faction.PLAYER
	scout.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = Stubs.FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = UnitClass.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, "Scout", "Monk")
	service.register_triggers([trigger])
	var result := service.start_dialogue(trigger.get_dialogue_id(), 0, 1)
	assert_that(result.is_success()).is_true()
	assert_that(scout.res.has_action_available()).is_false()
	var actions: Array[Dictionary] = []
	service.append_dialogue_actions(actions, scout, unit_manager)
	assert_that(actions.size()).is_equal(0)

func test_trigger_group_marks_all_seen() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout: Stubs.FakeUnit = Stubs.FakeUnit.new()
	scout.unit_name = "Scout"
	scout.faction = UnitClass.Faction.PLAYER
	scout.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = Stubs.FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = UnitClass.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	var bard: Stubs.FakeUnit = Stubs.FakeUnit.new()
	bard.unit_name = "Bard"
	bard.faction = UnitClass.Faction.PLAYER
	bard.set_grid_location(Vector2i(-1, 0))
	unit_manager.add_unit(scout, scout.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	unit_manager.add_unit(bard, bard.get_grid_location(), true)
	var group := DialogueTriggerGroup.new(StringName("bridge"))
	var trigger_a := _create_trigger(Vector2i.ZERO, "Scout", "Monk", StringName("bridge"))
	var trigger_b := _create_trigger(Vector2i.ZERO, "Scout", "Bard", StringName("bridge"))
	trigger_a.set_group(group)
	trigger_b.set_group(group)
	service.register_triggers([trigger_a, trigger_b])
	var result := service.start_dialogue(trigger_a.get_dialogue_id(), 0, 1)
	assert_that(result.is_success()).is_true()
	assert_that(trigger_b.seen).is_true()
	var actions: Array[Dictionary] = []
	service.append_dialogue_actions(actions, scout, unit_manager)
	assert_that(actions.size()).is_equal(0)

func test_leader_placeholder_matches_active_leader() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var leader: Stubs.FakeUnit = Stubs.FakeUnit.new()
	leader.unit_name = "Assassin"
	leader.faction = UnitClass.Faction.PLAYER
	leader.set_player_leader(true)
	leader.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = Stubs.FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = UnitClass.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(leader, leader.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, StringName("Leader"), StringName("Monk"))
	service.register_triggers([trigger])
	var actions: Array[Dictionary] = []
	service.append_dialogue_actions(actions, leader, unit_manager)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].get("target_index")).is_equal(unit_manager.get_unit_index(monk))

func test_partner_initiation_allows_reverse_start() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var leader: Stubs.FakeUnit = Stubs.FakeUnit.new()
	leader.unit_name = "Assassin"
	leader.faction = UnitClass.Faction.PLAYER
	leader.set_player_leader(true)
	leader.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = Stubs.FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = UnitClass.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(leader, leader.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, StringName("Leader"), StringName("Monk"), StringName(""), true)
	service.register_triggers([trigger])
	var actions: Array[Dictionary] = []
	service.append_dialogue_actions(actions, monk, unit_manager)
	assert_that(actions.size()).is_equal(1)
	var action := actions[0]
	assert_that(action.get("initiator_index")).is_equal(unit_manager.get_unit_index(leader))
	assert_that(action.get("target_index")).is_equal(unit_manager.get_unit_index(monk))
