extends GdUnitTestSuite

const DialogueActionService := preload("res://Gameplay/dialogue_action_service.gd")
const DialogueTrigger := preload("res://Gameplay/dialogue_trigger.gd")
const DialogueTriggerGroup := preload("res://Gameplay/dialogue_trigger_group.gd")
const Level := preload("res://Resources/Level.gd")
const LevelDialogueEntry := preload("res://Resources/level_data/level_dialogue_entry.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd")
const Hud := preload("res://GUI/hud.gd")
const HUDController := preload("res://Gameplay/hud_controller.gd")

class FakeUnit extends Unit:
	var fake_coord := Vector2i.ZERO
	var actions := 1

	func _ready() -> void:
		pass

	func has_action_available() -> bool:
		return actions > 0

	func consume_action() -> void:
		if actions > 0:
			actions -= 1

	func get_grid_location() -> Vector2i:
		return fake_coord

	func set_fake_coord(coord: Vector2i) -> void:
		fake_coord = coord

func _create_trigger(coord: Vector2i, initiator: StringName, partner: StringName, group_id: StringName = StringName("")) -> DialogueTrigger:
	var entry := LevelDialogueEntry.new()
	entry.coord = coord
	entry.initiator_name = initiator
	entry.partner_name = partner
	entry.timeline_path = "res://Resources/dialogue/hometown_intro.dtl"
	entry.group_id = group_id
	var trigger := DialogueTrigger.new()
	trigger.configure_from_entry(entry)
	return trigger

func _prepare_service() -> DialogueActionService:
	var service := DialogueActionService.new()
	var unit_manager := UnitManager.new()
	var hud := Hud.new()
	var hud_controller := HUDController.new()
	var grid := TileMapLayer.new()
	service.setup(unit_manager, hud, hud_controller, grid)
	service.prepare_for_level(Level.new())
	return service

func test_append_dialogue_actions_adds_talk_entry() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout := FakeUnit.new()
	scout.unit_name = "Scout"
	scout.faction = Unit.Faction.PLAYER
	scout.set_fake_coord(Vector2i.ZERO)
	var monk := FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = Unit.Faction.PLAYER
	monk.set_fake_coord(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.fake_coord, true)
	unit_manager.add_unit(monk, monk.fake_coord, true)
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
	var scout := FakeUnit.new()
	scout.unit_name = "Scout"
	scout.faction = Unit.Faction.PLAYER
	scout.set_fake_coord(Vector2i.ZERO)
	var monk := FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = Unit.Faction.PLAYER
	monk.set_fake_coord(Vector2i(1, 0))
	unit_manager.add_unit(scout, scout.fake_coord, true)
	unit_manager.add_unit(monk, monk.fake_coord, true)
	var trigger := _create_trigger(Vector2i.ZERO, "Scout", "Monk")
	service.register_triggers([trigger])
	var result := service.start_dialogue(trigger.get_dialogue_id(), 0, 1)
	assert_that(result.is_success()).is_true()
	assert_that(scout.has_action_available()).is_false()
	var actions: Array[Dictionary] = []
	service.append_dialogue_actions(actions, scout, unit_manager)
	assert_that(actions.size()).is_equal(0)

func test_trigger_group_marks_all_seen() -> void:
	var service := _prepare_service()
	var unit_manager := service._unit_manager
	var scout := FakeUnit.new()
	scout.unit_name = "Scout"
	scout.faction = Unit.Faction.PLAYER
	scout.set_fake_coord(Vector2i.ZERO)
	var monk := FakeUnit.new()
	monk.unit_name = "Monk"
	monk.faction = Unit.Faction.PLAYER
	monk.set_fake_coord(Vector2i(1, 0))
	var bard := FakeUnit.new()
	bard.unit_name = "Bard"
	bard.faction = Unit.Faction.PLAYER
	bard.set_fake_coord(Vector2i(-1, 0))
	unit_manager.add_unit(scout, scout.fake_coord, true)
	unit_manager.add_unit(monk, monk.fake_coord, true)
	unit_manager.add_unit(bard, bard.fake_coord, true)
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
