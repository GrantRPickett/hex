extends GdUnitTestSuite

class StubLevelManager extends Node:
	var levels: Array = []

	func get_available_levels() -> Array:
		return levels.duplicate(true)

	func start_level_by_id(_id: String) -> void:
		pass

class StubSaveManager extends Node:
	var data := {}

	func get_value(key: String, default := null):
		return data.get(key, default)

func _add_autoload_stub(node: Node) -> void:
	get_tree().root.add_child(node)

func _remove_autoload_stub(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()

func test_hometown_listed_first_and_repeatable() -> void:
	var level_manager := StubLevelManager.new()
	level_manager.name = "LevelManager"
	level_manager.levels = [
		{"id": "hometown", "display_name": "Hometown", "is_hometown": true, "repeatable": true},
		{"id": "level_1", "display_name": "A Mission"}
	]
	var save_manager := StubSaveManager.new()
	save_manager.name = "SaveManager"
	save_manager.data = {"completed_levels": {"hometown": true}}
	_add_autoload_stub(level_manager)
	_add_autoload_stub(save_manager)

	var scene := load("res://Menus/level_select.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	var list := scene.get_node("Panel/VBox/ScrollContainer/LevelList") as VBoxContainer
	var first_button := list.get_child(0) as Button
	assert_str(first_button.text).is_equal("Hometown")
	assert_bool(first_button.disabled).is_false()

	_remove_autoload_stub(level_manager)
	_remove_autoload_stub(save_manager)
	scene.queue_free()
