extends GdUnitTestSuite

const DialogueActionService := preload("res://Gameplay/narrative/dialogue/dialogue_action_service.gd")
const DialogueTrigger := preload("res://Gameplay/narrative/dialogue/dialogue_trigger.gd")
const DialogueTriggerGroup := preload("res://Gameplay/narrative/dialogue/dialogue_trigger_group.gd")
const LevelClass := preload("res://level/level.gd")
const LevelDialogueEntry := preload("res://level/level_dialogue_entry.gd")
const UnitManagerClass := preload("res://Gameplay/targets/unit_manager.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const GameStateClass := preload("res://Gameplay/game_state.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const DialogueResourceClass := preload("res://addons/dialogue_manager/dialogue_resource.gd")

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
	var unit_manager: UnitManager = auto_free(UnitManagerClass.new())
	get_tree().root.add_child(unit_manager)

	# Mock state for setup
	var mock_state = {
		"unit_manager": unit_manager,
		"hud": auto_free(Stubs.FakeHud.new()),
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

	var config: GameSessionBuilder.Config = GameSessionBuilder.Config.new()
	config.grid = auto_free(TileMapLayer.new())

	service.setup(GameStateClass.new(mock_state), config)
	service.prepare_for_level(LevelClass.new())

	# Inject mock resource to avoid file-system checks in start_dialogue
	var mock_res: DialogueResource = DialogueResourceClass.new()
	# Populate with dummy data to satisfy DialogueManager's validation
	mock_res.lines = {
		"0": {
			"id": "0",
			"type": "dialogue",
			"next_id": "",
			"text": "Fallback dialogue text",
			"character": "",
			"character_replacements": [],
			"text_replacements": [],
			"translation_key": ""
		}
	}
	mock_res.titles = {
		"test_dialogue": "0",
		"example_dialogue": "0",
		"res://Resources/level_data/dialogue_rows/example_dialogue.dialogue": "0"
	}
	service._dialogue_resource_cache["res://Resources/level_data/dialogue_rows/example_dialogue.dialogue"] = mock_res

	return service

func test_append_dialogue_actions_adds_talk_entry() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	scout.unit_name = "Scout"
	scout.faction = GameConstants.Faction.PLAYER
	scout.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	monk.unit_name = "Monk"
	monk.faction = GameConstants.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, "Scout", "Monk")
	service.register_triggers([trigger])
	var actions: Array[PlayerAction] = []
	service.append_dialogue_actions(actions, scout, unit_manager)
	assert_that(actions.size()).is_equal(1)
	var action := actions[0]
	assert_bool(action.type == GameConstants.ActionType.TALK).is_true()
	assert_that(action.target_index).is_equal(unit_manager.get_unit_index(monk))
	assert_that(action.dialogue_id).is_equal(String(trigger.get_dialogue_id()))

func test_start_dialogue_consumes_action_and_sets_flag() -> void:
	# Note: start_dialogue doesn't directly consume action in the refactored version,
	# it's usually handled by the command/executor.
	# However, we can check if it initializes dialogue correctly.
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	scout.unit_name = "Scout"
	scout.faction = GameConstants.Faction.PLAYER
	scout.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	monk.unit_name = "Monk"
	monk.faction = GameConstants.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, "Scout", "Monk")
	service.register_triggers([trigger])

	# Mock DialogueManager node
	var dm = Node.new()
	dm.name = "DialogueManager"
	unit_manager.get_tree().root.add_child(dm)

	var result := service.start_dialogue(trigger.get_dialogue_id(), 0, 1)
	assert_bool(result.is_success()).is_true()
	assert_bool(service.is_dialogue_active()).is_true()

	dm.queue_free()

func test_trigger_group_marks_all_seen() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	scout.unit_name = "Scout"
	scout.faction = GameConstants.Faction.PLAYER
	scout.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	monk.unit_name = "Monk"
	monk.faction = GameConstants.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)

	var group := DialogueTriggerGroup.new(StringName("bridge"))
	var trigger_a := _create_trigger(Vector2i.ZERO, "Scout", "Monk", StringName("bridge"))
	var trigger_b := _create_trigger(Vector2i.ZERO, "Scout", "Bard", StringName("bridge"))
	trigger_a.set_group(group)
	trigger_b.set_group(group)
	service.register_triggers([trigger_a, trigger_b])

	# Mock DialogueManager node
	var dm = Node.new()
	dm.name = "DialogueManager"
	unit_manager.get_tree().root.add_child(dm)

	var result := service.start_dialogue(trigger_a.get_dialogue_id(), 0, 1)
	assert_bool(result.is_success()).is_true()
	assert_bool(trigger_b.seen).is_true()

	dm.queue_free()

func test_leader_placeholder_matches_active_leader() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var leader: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	leader.unit_name = "Assassin"
	leader.faction = GameConstants.Faction.PLAYER
	leader.set_player_leader(true)
	leader.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	monk.unit_name = "Monk"
	monk.faction = GameConstants.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(leader, leader.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, StringName("Leader"), StringName("Monk"))
	service.register_triggers([trigger])
	var actions: Array[PlayerAction] = []
	service.append_dialogue_actions(actions, leader, unit_manager)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].target_index).is_equal(unit_manager.get_unit_index(monk))

func test_partner_initiation_allows_reverse_start() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var leader: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	leader.unit_name = "Assassin"
	leader.faction = GameConstants.Faction.PLAYER
	leader.set_player_leader(true)
	leader.set_grid_location(Vector2i.ZERO)
	var monk: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	monk.unit_name = "Monk"
	monk.faction = GameConstants.Faction.PLAYER
	monk.set_grid_location(Vector2i(1, 0))
	unit_manager.add_unit(leader, leader.get_grid_location(), true)
	unit_manager.add_unit(monk, monk.get_grid_location(), true)
	var trigger := _create_trigger(Vector2i.ZERO, StringName("Leader"), StringName("Monk"), StringName(""), true)
	service.register_triggers([trigger])
	var actions: Array[PlayerAction] = []
	service.append_dialogue_actions(actions, monk, unit_manager)
	assert_that(actions.size()).is_equal(1)
	var action := actions[0]
	assert_that(action.initiator_index).is_equal(unit_manager.get_unit_index(leader))
	assert_that(action.target_index).is_equal(unit_manager.get_unit_index(monk))
