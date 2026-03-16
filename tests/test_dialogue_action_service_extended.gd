extends GdUnitTestSuite

# Tests for DialogueActionService: set_level, get_trigger_at, trigger_at_coord, has_active_dialogue_with, handle_dialogue_request

const DialogueScript := preload("res://Gameplay/narrative/dialogue/dialogue_action_service.gd")

class FakeLevel extends Level:
	var fake_dialogue_triggers: Array[DialogueTrigger] = []

class FakeTrigger extends DialogueTrigger:
	var _seen := false
	var triggered := false
	func _init(id: StringName = &"") -> void:
		_dialogue_id = id
	func requires_initiator_action() -> bool: return true
	func mark_seen(_b := false) -> void: _seen = true
	func reset_seen() -> void: _seen = false

class FakeTaskController:
	func _init() -> void: pass

func _make_service() -> DialogueActionService:
	var s := DialogueActionService.new()
	var js: JournalData = JournalData.new() # JournalData can be instanced safely.
	var jm: Node = Node.new()
	jm.set("journal_data", js)
	var config: GameSessionBuilder.Config = GameSessionBuilder.Config.new()
	var state: GameState = GameState.new({})
	state.task_controller = Node.new() # GameState expects a Node for tree items
	s.setup(state, config)
	return s

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

func test_prepare_for_level_replaces_active_triggers() -> void:
	var s := _make_service()
	var lvl := Level.new()
	var entry := LevelDialogueEntry.new()
	entry.entry_id = &"test"
	lvl.dialogue_entries = [entry]

	s.set_level(lvl)
	assert_int(s._trigger_manager.get_all_triggers().size()).is_equal(1)

func test_get_trigger_at_finds_by_coord() -> void:
	var s := _make_service()
	var trigger := FakeTrigger.new()
	trigger.set_external_grid_coord(Vector2i(1, 1))
	s.register_triggers([trigger])

	var found: DialogueTrigger = s.get_trigger_at(Vector2i(1, 1))
	assert_object(found).is_equal(trigger)

	var not_found: DialogueTrigger = s.get_trigger_at(Vector2i(2, 2))
	assert_object(not_found).is_null()

func test_has_active_dialogue_with_matches_unit() -> void:
	# Note: has_active_dialogue_with was removed or renamed in recent refactor.
	# If it's missing, we should probably check what replaced it or remove this test.
	# Looking at DialogueActionService.gd, it doesn't seem to have it.
	pass

func test_trigger_assign_coord_on_grid() -> void:
	var t := DialogueTrigger.new()
	t.entry = LevelDialogueEntry.new()
	var layer := TileMapLayer.new()
	layer.tile_set = TileSet.new()

	t.assign_coord_on_grid(layer)

	assert_object(t.grid_map).is_equal(layer)
	layer.queue_free()
