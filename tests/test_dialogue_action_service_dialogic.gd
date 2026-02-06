extends GdUnitTestSuite

const DialogueActionService := preload("res://Gameplay/dialogue_action_service.gd")
const DialogueTrigger := preload("res://Gameplay/dialogue_trigger.gd")
const LevelDialogueEntry := preload("res://Resources/level_data/level_dialogue_entry.gd")
const Level := preload("res://Resources/Level.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd")
const Hud := preload("res://GUI/hud.gd")
const HUDController := preload("res://Gameplay/hud_controller.gd")
const Unit := preload("res://Gameplay/unit.gd")

class FakeUnit extends Unit:
	var fake_coord := Vector2i.ZERO
	var actions := 1

	func has_action_available() -> bool:
		return actions > 0

	func consume_action() -> void:
		if actions > 0:
			actions -= 1

	func get_grid_location() -> Vector2i:
		return fake_coord

	func set_fake_coord(coord: Vector2i) -> void:
		fake_coord = coord

class FakeDialogic extends Node:
	signal timeline_ended
	var start_called := false
	var start_timeline_called := false

	func start(_timeline, _label_or_idx := "") -> void:
		start_called = true

	func start_timeline(_timeline, _label_or_idx := "") -> void:
		start_timeline_called = true

func _create_trigger(coord: Vector2i, initiator: StringName, partner: StringName) -> DialogueTrigger:
	var entry := LevelDialogueEntry.new()
	entry.coord = coord
	entry.initiator_name = initiator
	entry.partner_name = partner
	entry.timeline_path = "res://Resources/dialogue/hometown_intro.dtl"
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

func test_start_dialogue_uses_dialogic_start() -> void:
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

	var tree := Engine.get_main_loop()
	assert_bool(tree is SceneTree).is_true()
	var root := (tree as SceneTree).root
	var dialogic := FakeDialogic.new()
	dialogic.name = "Dialogic"
	root.add_child(dialogic)

	var result := service.start_dialogue(trigger.get_dialogue_id(), 0, 1)
	assert_that(result.is_success()).is_true()
	assert_bool(dialogic.start_called).is_true()
	assert_bool(dialogic.start_timeline_called).is_false()

	root.remove_child(dialogic)
	dialogic.queue_free()
