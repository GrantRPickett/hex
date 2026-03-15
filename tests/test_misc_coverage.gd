extends GdUnitTestSuite

# For coverage of remaining untested functions
const DialogueState = preload("res://Gameplay/narrative/dialogue/dialogue_state.gd")
const TaskStageSpawner = preload("res://Gameplay/narrative/task/task_stage_spawner.gd")

func test_dialogue_state_methods() -> void:
	var state: DialogueState = DialogueState.new()
	var stat = state.get_character_stat("Hero", "HP", 10)
	assert_that(stat).is_equal(10)
	state.free()

func test_task_stage_spawner_methods() -> void:
	# TaskStageSpawner requires GameState. We can pass a mock or null if it just fails gracefully.
	var spawner: TaskStageSpawner = TaskStageSpawner.new(null)
	var result = spawner.handle_stage_spawns(Resource.new())
	assert_that(result).is_false() # Should fail because state/unit_manager is null
	# RefCounted, no need to free.

func test_inventory_ui_methods() -> void:
	var char_panel_scene: Resource = load("res://GUI/inventory/inventory_character_panel.tscn")
	if char_panel_scene:
		var panel: Node = auto_free(char_panel_scene.instantiate())
		if panel.has_method("set_highlight"):
			panel.set_highlight(true)
		if panel.has_method("refresh"):
			panel.refresh()

	var item_slot_scene: Resource = load("res://GUI/inventory/inventory_item_slot.tscn")
	if item_slot_scene:
		var slot: Node = auto_free(item_slot_scene.instantiate())
		if slot.has_method("set_highlight"):
			slot.set_highlight(true)
